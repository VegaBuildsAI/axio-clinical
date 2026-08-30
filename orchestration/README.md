# axio-clinical-local

AXIO Clinical Agent completa en la Dell — motor clínico + consola + Postgres en **un** proyecto
Docker, contra el **Ollama del host** (Intel Arc 140V vía Vulkan). Sin nube.

## Levantar todo (3 comandos)

```bash
cd axio-clinical-local          # (si es la primera vez: cp .env.example .env y completar)
docker compose up -d --build
./scripts/smoke.sh           # turno normal + crisis N3 contra el modelo real
```

| Servicio | URL | Qué es |
|---|---|---|
| motor | http://localhost:8000 | `POST /infer` · `POST /classify` · `/health` |
| consola-api | http://localhost:8001 | backend de la consola (HITL/observabilidad) |
| consola-web | http://localhost:5173 | frontend de la consola |
| postgres | localhost:5433 | BD `axio_clinical_motor` + `axio_clinical_console` |
| oncall-sim | (interno) | receptor simulado del webhook de crisis N3 |
| Ollama | localhost:11434 | **en el host**, no en Docker |

## Requisitos del host

- Docker Desktop.
- Ollama ≥ 0.32 corriendo en Windows con la Arc habilitada:
  `OLLAMA_IGPU_ENABLE=1` (variable de usuario; sin ella Ollama descarta la iGPU
  y corre 100% CPU). Contexto recomendado: 8192 (config de la app de Ollama).
- Modelos: `qwen3:8b`, `qwen3:14b`, `nomic-embed-text`.

## Verificación

```bash
docker compose ps                              # 5 servicios, 4 healthy
./scripts/bench-ollama.sh                      # tok/s (Fase 0: 8b≈17, 14b≈9.7 en la Arc)
./scripts/test-motor.sh                        # 188 esperados (limpia el env; BD de test aparte)
docker compose exec consola-api python -m pytest -q   # suite de la consola
docker compose logs oncall-sim                 # notificaciones N3 recibidas
```

## Plataforma vega + APK (encima de este stack)

La app del paciente (APK Expo de `axio-clinical-platform-vega/mobile`) habla con el
backend NestJS de vega, y éste con el motor vía `POST /axio-clinical-agent/infer`
(identidad `vega:` en `AXIO_CLINICAL_SERVICE_TOKENS`):

```
APK (Expo) ──► vega backend :4000 (/api/axio-clinical-agent/infer, JWT del paciente)
                   └──► motor :8000 (/infer, x-service-token)
                           ├──► Ollama del host (qwen3:8b, Arc 140V)
                           ├──► oncall-sim (webhook N3)
                           └──► Postgres 5433 (SoR cifrado) ◄── consola HITL :5173
```

- Backend vega: `axio-clinical-platform-vega/backend/.env` (BD propia en el
  postgis `axio-clinical-db` :5432, `MOTOR_SERVICE_TOKEN`, `MOTOR_TIMEOUT_MS`).
  Arranque: `npm --prefix axio-clinical-platform-vega/backend run start:dev`.
- Móvil: `mobile/app.json → extra.apiUrl = http://<IP-LAN-de-la-Dell>:4000`.
  El teléfono debe estar en la misma Wi-Fi; si no conecta, permití node.exe
  entrante (red privada) en el firewall de Windows. Un APK ya instalado trae
  la URL vieja horneada: rebuild (`eas build -p android --profile preview`) o
  probar con Expo Go. Para APK standalone con http:// hace falta
  `expo-build-properties` → `usesCleartextTraffic` (o un túnel https).

## Exportar al server GPU (2× RTX 4080)

El motor corre **EN** la caja (D6, regla S3: PHI no sale). Único cambio:
en `.env`, `AXIO_CLINICAL_MODEL_REASONING=qwen3:14b`. Cero diff de código.

## Diseño

- **No se copia código**: `build.context` apunta a `../axio-clinical-motor-clinico` y
  `../axio-clinical-console` (evita la divergencia platform↔vega).
- Todo lo cloud (Cloudflare, Cloudinary, ContactShip, Siku, WhatsApp) queda
  **apagado** con config vacía — el motor degrada a stubs seguros.
- El puerto 5432 del host es del postgis de vega: este stack usa **5433**.
