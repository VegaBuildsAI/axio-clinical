# Integración — Cómo encaja AXIO Clinical en el stack AXIO

AXIO Clinical es el **Clinical Engine** del stack AXIO: producto local-first renombrado, con el
agente **AXIO Clinical Agent**. Todo corre local/on-prem por clínica.

## Componentes y puertos

| Servicio | Carpeta/Repo | Stack | Puerto |
|---|---|---|---|
| Backend paciente (Vega) | `axio-clinical-platform-vega/backend` | NestJS | `:4000` (proxy `/api/axio-clinical-agent/infer`) |
| APK paciente | `axio-clinical-platform-vega/mobile` | Expo/React Native web | `:8081` |
| Admin operación | `axio-clinical-platform-vega/admin` | Next.js | (según config) |
| Motor clínico | `axio-clinical-motor-clinico` | Python FastAPI | `:8000` |
| Consola (obs/HITL/gates) | `axio-clinical-console` | Python `axio_clinical_console` + Vite/React | api `:8001`, web `:5173` |
| Orquestación | `orchestration/` (ex `axio-clinical-local`) | Docker Compose | postgres `:5433`, oncall-sim |

## Convenciones de naming

- **Marca**: AXIO Clinical. **Agente**: AXIO Clinical Agent.
- **Env keys**: prefijo `AXIO_CLINICAL_*`.
- **DB**: `axio_clinical_motor` (motor), `axio_clinical_console` (consola); user postgres `axio_clinical`.
  Los nombres de DB deben quedar **en minúsculas**.
- **Paquete Python de consola**: `axio_clinical_console`.
- **Prefijo de seudónimo de sujeto**: `ax_`.
- **Endpoint del agente**: `/axio-clinical-agent/infer` (cliente y servidor deben coincidir).
- **Codenames internos** conservados (no son marca): `vega`, `siku`, `consola`, `motor`.

## Auth / identidad

- Paciente → Vega: **JWT del paciente** (`JwtAuthGuard`).
- Vega → Motor: `x-service-token` con identidad `vega` (en `AXIO_CLINICAL_SERVICE_TOKENS`).
- Consola → Motor: identidad `consola` + `MOTOR_INGEST_TOKEN`; lectura del SoR con rol `console_ro`
  (**solo SELECT**).
- Sujeto seudónimo `ax_<id>`; la identidad directa vive **cifrada y separada** (llave
  `AXIO_CLINICAL_IDENTITY_KEY`).

## Config centralizada

- Un `.env` por instancia en `orchestration/.env` (ver [`deployment.md`](deployment.md)).
- Integraciones cloud (Cloudflare/Cloudinary/WhatsApp/ContactShip/Siku) quedan **apagadas** →
  el motor **degrada a stubs seguros**. No hay dependencia obligatoria de la nube.

## Verificación (E2E, con Docker + Ollama arriba)

1. `docker compose up -d --build` en `orchestration/` → `docker compose ps` (4 healthy).
2. `./scripts/smoke.sh` verde (turno normal + crisis N3 contra Ollama real).
3. Consola `:5173`: login, ver observación del turno, registrar outcome, gates fail-closed.
4. El agente responde como **AXIO Clinical Agent**; **N3 corta antes del LLM**.
5. Tests: `./scripts/test-motor.sh`, `docker compose exec consola-api python -m pytest -q`.

## Supuestos / preguntas abiertas

- Modelo de despliegue: **single-tenant replicable** (confirmado). Multi-tenant **no** implementado.
- Publicación de los repos de componentes bajo `VegaBuildsAI` (ver [`../components.md`](../components.md)).
