# Arquitectura — AXIO Clinical

AXIO Clinical es un stack **local-first, on-premise, single-tenant** para soporte a la decisión
clínica, triaje y análisis de síntomas. Cada clínica corre su propia instancia completa (su BD, sus
secretos, sus modelos, su branding). No hay multi-tenant.

## 1. Componentes y responsabilidades

| Servicio | Stack | Puerto | Responsabilidad |
|---|---|---|---|
| **Vega** (backend paciente) | NestJS | `:4000` | API del paciente, auth JWT, proxy `/api/axio-clinical-agent/infer` → Motor. |
| **APK paciente** | Expo / React Native (web) | `:8081` | Interfaz del paciente; conversa con el agente. |
| **Admin** | Next.js | (config) | Operación / back-office de la clínica. |
| **Motor Clínico** | Python / FastAPI | `:8000` | Razonamiento, triaje N0–N3, crisis determinista, escritura del SoR. |
| **Consola** | Python (`axio_clinical_console`) + Vite/React | api `:8001`, web `:5173` | Observabilidad, HITL, gates fail-closed, lectura del SoR. |
| **Postgres** | Postgres (compose) | `:5433` | SoR cifrado (`axio_clinical_motor`) + estado de consola (`axio_clinical_console`). |
| **oncall-sim** | Python | interno | Simulador local del webhook de crisis N3. |
| **Ollama** | Ollama (host) | `:11434` | LLM local (qwen3 razonamiento/triaje, nomic-embed-text). |
| **Web (demo)** | Vite/React | — | Demo web del agente. |
| **Siku** | Python | — | Conector IoLab/Siku. |
| **ContactShip** | Python | — | Puente voz/omnicanal. |

Codenames internos (no marca): `vega`, `motor`, `consola`, `siku`.

## 2. Flujo end-to-end

```
APK :8081
  └─ JWT paciente ─▶ Vega :4000  (/api/axio-clinical-agent/infer)
                       └─ x-service-token "vega" ─▶ Motor :8000  (/axio-clinical-agent/infer)
                            ├─ Ollama host :11434            (qwen3 — razonamiento/triaje)
                            ├─ Postgres :5433                (SoR cifrado, DB axio_clinical_motor, sujeto ax_*)
                            ├─ oncall-sim                    (webhook crisis N3, determinista, pre-LLM)
                            └─ ingesta ─▶ Consola :8001/5173 (HITL/observabilidad)
                                            └─ rol console_ro (solo SELECT) ─▶ Postgres :5433
```

1. El paciente escribe un turno en la APK; Vega valida el **JWT del paciente**.
2. Vega actúa como proxy y llama al Motor con **`x-service-token`** de identidad `vega`.
3. El Motor clasifica el riesgo (**N0–N3**):
   - Si detecta **crisis N3**, escala de forma **determinista** al `oncall-sim` **antes** de invocar el LLM.
   - Si no, razona con **Ollama** (qwen3) y arma la respuesta (`reply`, `actions`, `disclaimers`…).
4. El Motor persiste el turno en el **SoR** (seudonimizado, cifrado) e **ingesta** la observación a la Consola.
5. La **Consola** permite al equipo clínico observar el turno, registrar outcomes y operar gates
   fail-closed, leyendo el SoR con rol `console_ro` (**solo SELECT**).

## 3. System of Record (SoR)

- BD `axio_clinical_motor` en el Postgres del compose (`:5433`).
- El sujeto se identifica por **seudónimo** `ax_<id>`. La **identidad directa** (PHI) vive **cifrada
  y separada**, con llave `AXIO_CLINICAL_IDENTITY_KEY` (AES) y `AXIO_CLINICAL_IDENTITY_PEPPER`.
- Pepper y key son **obligatorios** si hay DSN: el motor **falla el arranque a propósito** sin ellos
  (fail-closed), para no operar sin cifrado.
- La consola **nunca** escribe el hilo del motor: usa el rol `console_ro` (solo `SELECT`), reforzado
  a nivel de Postgres.

## 4. El agente (AXIO Clinical Agent)

- Endpoint canónico: **`POST /axio-clinical-agent/infer`** (cliente y servidor deben coincidir).
- Entrada/salida planas (`InferRequest` / `InferResponse`) — ver [`api-infer.md`](api-infer.md).
- Guardrails **N0–N3** determinan tono, disclaimers y escalación. **N3 nunca depende del LLM.**
- El razonamiento usa el LLM **local** (Ollama). No hay dependencia obligatoria de nube: las
  integraciones cloud (Cloudflare/Cloudinary/WhatsApp/ContactShip/Siku) quedan **apagadas** por
  defecto y el motor **degrada a stubs seguros**.

## 5. Modelos LLM (Ollama, en el host)

| Rol | Variable | Dell (Arc 140V) | Server (2×4080) |
|---|---|---|---|
| Razonamiento | `AXIO_CLINICAL_MODEL_REASONING` | `qwen3:8b` | `qwen3:14b` |
| Triaje | `AXIO_CLINICAL_MODEL_TRIAGE` | `qwen3:8b` | `qwen3:14b` |
| Embeddings | `AXIO_CLINICAL_MODEL_EMBED` | `nomic-embed-text` | `nomic-embed-text` |

Ollama corre **en el host** (no en Docker) para aprovechar GPU/iGPU; el motor lo alcanza vía
`http://host.docker.internal:11434`.

## 6. Seguridad transversal

- **Auth servicio-a-servicio**: `AXIO_CLINICAL_SERVICE_TOKENS = "vega:<tok>,consola:<tok>,smoke:<tok>"`.
- **Ingesta motor→consola**: `AXIO_CLINICAL_CONSOLE_INGEST_TOKEN` debe ser **igual** a `MOTOR_INGEST_TOKEN`.
- **Crisis**: `AXIO_CLINICAL_CRISIS_WEBHOOK_URL/_TOKEN`.
- Detalle completo en [`security-phi.md`](security-phi.md).

Ver también: [`deployment.md`](deployment.md) · [`integration.md`](integration.md).
