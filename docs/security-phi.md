# Seguridad y PHI — AXIO Clinical

AXIO Clinical maneja información clínica sensible (PHI). El diseño es **local-first / on-premise**
para que los datos de pacientes **no salgan de la infraestructura de la clínica**, con controles
determinIstas de crisis y trazabilidad completa.

## 1. De-identificación (Safe-Harbor)

- Los **identificadores directos** (Safe-Harbor) no viajan ni se registran en claro entre servicios.
- El sujeto se referencia por **seudónimo** `ax_<id>`.
- La **identidad directa** vive **cifrada y separada** del hilo clínico, con:
  - `AXIO_CLINICAL_IDENTITY_KEY` — llave AES (base64 de 32 bytes).
  - `AXIO_CLINICAL_IDENTITY_PEPPER` — pepper (base64 de 32 bytes).
- Estos dos son **obligatorios** si hay DSN del SoR: **el motor falla el arranque a propósito** si
  faltan (fail-closed) — nunca opera sin cifrado.

## 2. Manejo determinista de crisis (N3)

- La escala de riesgo canónica es **N0–N3** (ver [`api-infer.md`](api-infer.md)).
- Ante **N3** (bandera roja / crisis), la escalación es **determinista y ocurre ANTES de invocar el
  LLM**: no depende del modelo, no puede ser "hablada" por el paciente ni alucinada por el agente.
- Se notifica al flujo humano (webhook on-call) con **meta < 2 minutos**.
- En local, el destino es `oncall-sim` (`AXIO_CLINICAL_CRISIS_WEBHOOK_URL/_TOKEN`).

## 3. Audit log append-only + gates fail-closed

- Las observaciones de cada turno se **ingestan a la consola** y se registran de forma
  **append-only** (auditables, no reescribibles).
- La consola opera **gates fail-closed**: ante duda o fallo, se cierra (no se abre) el paso.

## 4. Modelo de acceso a datos

- La **consola** lee el SoR con el rol de Postgres **`console_ro` (solo `SELECT`)**: aunque un bug
  intentara escribir el hilo del motor desde la consola, Postgres lo rechaza a nivel de motor de BD.
- La contraseña de `console_ro` vive en `.env` (`MOTOR_DATABASE_URL`) y debe coincidir con la del
  script de init (`orchestration/scripts/initdb/02-console-ro.sql`).

## 5. Autenticación

| Enlace | Mecanismo |
|---|---|
| Paciente → Vega | JWT del paciente (`JwtAuthGuard`) |
| Vega → Motor | `x-service-token` identidad `vega` (en `AXIO_CLINICAL_SERVICE_TOKENS`) |
| Consola → Motor | identidad `consola` + `MOTOR_INGEST_TOKEN` |
| Consola → SoR | rol `console_ro` (solo SELECT) |

## 6. Gestión de secretos

- **Ningún secreto se versiona** en este repo. Todos viven en `.env` por instancia.
- El repo solo incluye `.env.example` con **claves vacías** y placeholders.
- Generar secretos por clínica (no reutilizar entre clínicas):
  ```bash
  python -c "import secrets; print(secrets.token_urlsafe(32))"                    # tokens
  python -c "import os,base64; print(base64.b64encode(os.urandom(32)).decode())"  # pepper/key
  ```

## 7. Superficie cloud apagada por defecto

Cloudflare / Cloudinary / WhatsApp / ContactShip / Siku quedan **apagadas** por defecto; el motor
degrada a **stubs seguros**. No hay dependencia obligatoria de servicios externos para operar el
flujo clínico.

## 8. Divulgación responsable

Este es un repositorio **privado**. Reportá cualquier hallazgo de seguridad de forma privada al
equipo AXIO (no abras issues públicos ni divulgues detalles fuera del canal interno). Ver
[`../SECURITY.md`](../SECURITY.md).
