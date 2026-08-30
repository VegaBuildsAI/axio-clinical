#!/usr/bin/env bash
# Benchmark repetible de Ollama (método de la Fase 0 / §8 del plan).
# Uso: ./scripts/bench-ollama.sh [modelo...]   (default: qwen3:8b qwen3:14b)
set -euo pipefail

HOST=${OLLAMA_URL:-http://localhost:11434}
MODELOS=("${@:-qwen3:8b}")
[ $# -eq 0 ] && MODELOS=(qwen3:8b qwen3:14b)

echo "Ollama en $HOST"
for m in "${MODELOS[@]}"; do
  echo "--- $m ---"
  curl -s "$HOST/api/generate" -d "{
    \"model\": \"$m\",
    \"prompt\": \"Explica en un parrafo que es la hipertension arterial y por que importa controlarla.\",
    \"stream\": false, \"think\": false,
    \"options\": {\"num_predict\": 60}
  }" | python -c "
import json, sys
d = json.load(sys.stdin)
if 'eval_count' not in d:
    print('ERROR:', d.get('error', d)); raise SystemExit(1)
print(f\"  tok/s:   {d['eval_count'] / (d['eval_duration'] / 1e9):.2f}\")
print(f\"  load_s:  {d.get('load_duration', 0) / 1e9:.1f}\")
print(f\"  total_s: {d['total_duration'] / 1e9:.1f}\")
"
done
echo "--- procesador (debe decir GPU, no 100% CPU) ---"
curl -s "$HOST/api/ps" | python -c "
import json, sys
for m in json.load(sys.stdin).get('models', []):
    total, vram = m.get('size', 0), m.get('size_vram', 0)
    pct = round(100 * vram / total) if total else 0
    print(f\"  {m['name']}: {pct}% GPU · ctx {m.get('context_length','?')}\")
"
