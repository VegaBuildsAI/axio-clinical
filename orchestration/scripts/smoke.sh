#!/usr/bin/env bash
# Smoke test del stack local: turno normal + crisis N3 contra el Ollama real.
# Uso: ./scripts/smoke.sh   (desde axio-clinical-local/, con el compose arriba)
set -euo pipefail
cd "$(dirname "$0")/.."

MOTOR=${MOTOR_URL:-http://localhost:8000}

# Token de la identidad "smoke" en AXIO_CLINICAL_SERVICE_TOKENS del .env
TOKEN=$(grep '^AXIO_CLINICAL_SERVICE_TOKENS=' .env | sed 's/.*smoke:\([^,]*\).*/\1/')
if [ -z "$TOKEN" ]; then
  echo "FAIL: no encontré la identidad 'smoke' en AXIO_CLINICAL_SERVICE_TOKENS (.env)"; exit 1
fi

fallo=0
check() { # check <descripcion> <ok:0|1>
  if [ "$2" -eq 0 ]; then echo "  OK   $1"; else echo "  FAIL $1"; fallo=1; fi
}

echo "== 1. Motor vivo y con Ollama configurado =="
curl -fsS "$MOTOR/health" >/dev/null
check "/health responde" $?
READY=$(curl -fsS -H "x-service-token: $TOKEN" "$MOTOR/ready?probe=true")
echo "$READY" | python -c "
import json,sys
d = json.load(sys.stdin)
assert d['local_llm']['endpoint'] == 'configured', d['local_llm']
assert d['sor'] == 'postgres', d['sor']
" && check "/ready: local_llm configurado + SoR postgres" 0 || check "/ready: local_llm configurado + SoR postgres" 1

echo "== 2. Turno normal (debe razonarlo qwen3 real, no el DEMO) =="
# Los payloads van por stdin (heredoc): pasarlos como argumento de curl rompe
# el UTF-8 en Git Bash / Windows (400 "error parsing the body").
RESP=$(curl -fsS -X POST "$MOTOR/axio-clinical-agent/infer" \
  -H "content-type: application/json" -H "x-service-token: $TOKEN" \
  --data-binary @- <<'EOF'
{"member_token":"smoke-demo-1","text":"¿Cada cuánto conviene medirse la presión arterial en la casa y a qué hora del día?","channel":"web"}
EOF
)
echo "$RESP" | python -c "
import json,sys
d = json.load(sys.stdin)
assert d['route'] == 'local', f\"route={d['route']}\"
assert 'TODO_CONFIRMAR' not in d['reply'], 'la respuesta es el scaffold DEMO, no el modelo'
assert '<think>' not in d['reply'], 'se filtró el monólogo interno de qwen3'
assert len(d['reply']) > 40, 'respuesta sospechosamente corta'
print('  reply (primeros 120):', d['reply'][:120].replace(chr(10),' '))
print('  risk:', d['risk_level'], '| tools:', d['tools_used'])
" && check "turno normal razonado por el modelo local" 0 || check "turno normal razonado por el modelo local" 1
CONV_ID=$(echo "$RESP" | python -c "import json,sys; print(json.load(sys.stdin).get('conversation_id') or '')")

echo "== 3. Crisis N3 (determinística, antes del LLM — S9) =="
RESP=$(curl -fsS -X POST "$MOTOR/axio-clinical-agent/infer" \
  -H "content-type: application/json" -H "x-service-token: $TOKEN" \
  --data-binary @- <<'EOF'
{"member_token":"smoke-demo-1","text":"me duele el pecho y me falta el aire","channel":"web"}
EOF
)
echo "$RESP" | python -c "
import json,sys
d = json.load(sys.stdin)
assert d['risk_level'] == 'N3', f\"risk={d['risk_level']}\"
assert d['escalated'] is True, 'N3 sin escalar'
assert d['route'] == 'crisis', f\"route={d['route']}\"
print('  risk:', d['risk_level'], '| escalated:', d['escalated'])
" && check "N3 clasificado y escalado" 0 || check "N3 clasificado y escalado" 1

sleep 2
if docker compose logs oncall-sim 2>/dev/null | grep -q "\[oncall-sim\].*POST"; then
  check "webhook de crisis recibido por el on-call simulado" 0
else
  check "webhook de crisis recibido por el on-call simulado" 1
fi

echo "== 4. Persistencia del hilo (misma conversación al continuar) =="
if [ -n "$CONV_ID" ]; then
  RESP=$(curl -fsS -X POST "$MOTOR/axio-clinical-agent/infer" \
    -H "content-type: application/json" -H "x-service-token: $TOKEN" \
    --data-binary @- <<EOF
{"member_token":"smoke-demo-1","text":"gracias, ¿y con qué aparato me la mido?","channel":"web","conversation_id":"$CONV_ID"}
EOF
)
  echo "$RESP" | python -c "
import json,sys
d = json.load(sys.stdin)
assert d.get('conversation_id') == '$CONV_ID', f\"cambió el hilo: {d.get('conversation_id')}\"
print('  conversation_id:', d['conversation_id'])
" && check "hilo persistido (mismo conversation_id)" 0 || check "hilo persistido" 1
else
  check "hilo persistido (sin conversation_id del paso 2)" 1
fi

echo "== 5. Hilo multicanal (D4: cruzar de canal requiere link de enrollment) =="
# Simula el enrollment: asocia la identidad whatsapp al subject de web.
docker compose exec -T motor python - <<'EOF'
from app.main_deps import get_deps
deps = get_deps()
sid = deps.sor.resolve_subject("web", "smoke-demo-1")
deps.sor.identity.link(sid, "whatsapp", "+50688880000")
print(f"  link whatsapp:+50688880000 -> subject {sid[:8]}…")
EOF
RESP=$(curl -fsS -X POST "$MOTOR/axio-clinical-agent/infer" \
  -H "content-type: application/json" -H "x-service-token: $TOKEN" \
  --data-binary @- <<EOF
{"member_token":"+50688880000","text":"soy yo desde whatsapp, ¿me repetís la recomendación?","channel":"whatsapp","conversation_id":"$CONV_ID"}
EOF
)
echo "$RESP" | python -c "
import json,sys
d = json.load(sys.stdin)
assert d.get('conversation_id') == '$CONV_ID', f\"otro hilo: {d.get('conversation_id')}\"
print('  mismo hilo desde whatsapp:', d['conversation_id'])
" && check "un subject, una conversación, dos canales" 0 || check "un subject, una conversación, dos canales" 1

echo "== 6. N3 visible en HITL (Fase 3: la consola lee la BD del motor) =="
CONSOLA=${CONSOLA_URL:-http://localhost:8001}
JWT=$(curl -fsS -X POST "$CONSOLA/auth/login" -H "content-type: application/json" \
  -d '{"correo":"revisora@axio_clinical.cr","password":"axio-clinical-agent-demo-2026"}' \
  | python -c "import json,sys; print(json.load(sys.stdin)['access_token'])" 2>/dev/null || true)
if [ -z "$JWT" ]; then
  check "login consola (¿corriste el seed? docker compose exec consola-api python -m axio_clinical_console.cli seed)" 1
else
  curl -fsS -H "Authorization: Bearer $JWT" "$CONSOLA/hitl/cola?estado=pendiente" | python -c "
import json,sys
cola = json.load(sys.stdin)
n3 = [c for c in cola if c['nivel_riesgo'] == 'N3']
assert n3, 'la cola HITL no muestra el N3 del motor'
caso = n3[0]
assert caso['subject_id'], 'caso sin subject_id'
print('  caso:', caso['member_nombre'], '|', caso['motivo_bandera_roja'][:50])
" && check "N3 del motor visible en la cola HITL" 0 || check "N3 del motor visible en la cola HITL" 1
fi

echo
if [ "$fallo" -eq 0 ]; then echo "SMOKE OK"; else echo "SMOKE CON FALLOS"; exit 1; fi
