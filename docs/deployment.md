# Despliegue — AXIO Clinical (single-tenant, una instancia por clínica)

Modelo: **una instancia completa por clínica**. Cada clínica corre su propio stack (su BD, sus
secretos, sus modelos Ollama, su nombre/branding). No hay multi-tenant: para una clínica nueva se
replica este stack con otro `.env`.

## Requisitos del host

- **Docker Desktop** corriendo.
- **Ollama en el host** (no en Docker) con GPU habilitada (e iGPU si aplica,
  `OLLAMA_IGPU_ENABLE=1`). Modelos: `qwen3:8b` (o `qwen3:14b` en server GPU) y `nomic-embed-text`.
- **Node 20+** y npm (para el backend Vega y el APK Expo web).

## 1. Infraestructura core (motor + consola + Postgres + oncall-sim)

```bash
cd orchestration
cp .env.example .env          # completar secretos (ver abajo)
docker compose up -d --build
docker compose ps             # 5 servicios, 4 healthy
./scripts/smoke.sh            # turno normal + crisis N3 contra Ollama real
```

Servicios: motor `:8000`, consola-api `:8001`, consola-web `:5173`, postgres `:5433`,
oncall-sim (interno).

## 2. Vega (backend paciente) + APK web

```bash
npm --prefix <ruta>/axio-clinical-platform-vega/backend install
npm --prefix <ruta>/axio-clinical-platform-vega/backend run start:dev   # :4000, BD propia postgis :5432
# APK Expo web (:8081): en axio-clinical-platform-vega/mobile → npx expo start --web
```

Móvil: `axio-clinical-platform-vega/mobile/app.json → extra.apiUrl = http://<IP-LAN>:4000`.

## 3. Secretos a generar (en `orchestration/.env`)

```bash
python -c "import secrets; print(secrets.token_urlsafe(32))"                    # tokens
python -c "import os,base64; print(base64.b64encode(os.urandom(32)).decode())"  # pepper/key
```

Completar como mínimo:

- `POSTGRES_PASSWORD`
- `AXIO_CLINICAL_IDENTITY_PEPPER`, `AXIO_CLINICAL_IDENTITY_KEY` (**obligatorios** si hay DSN)
- `AXIO_CLINICAL_SERVICE_TOKENS` (`vega:<tok>,consola:<tok>,smoke:<tok>`)
- `AXIO_CLINICAL_CRISIS_WEBHOOK_TOKEN`
- `AXIO_CLINICAL_CONSOLE_INGEST_TOKEN`, `JWT_SECRET`, `MOTOR_INGEST_TOKEN`

> ⚠️ `AXIO_CLINICAL_CONSOLE_INGEST_TOKEN` debe ser **IGUAL** a `MOTOR_INGEST_TOKEN`.
> ⚠️ La contraseña del rol `console_ro` en `scripts/initdb/02-console-ro.sql` debe coincidir con la
> de `MOTOR_DATABASE_URL` en el `.env`. Genera una nueva por clínica; **no reutilices** el placeholder.

## 4. Parámetros específicos de clínica (lo que cambia por cliente)

| Parámetro | Dónde |
|---|---|
| Nombre de la clínica / branding | tokens de tema (ver [`branding.md`](branding.md)) + textos por instancia |
| Secretos (todos los de arriba) | `orchestration/.env` por clínica |
| Modelos Ollama (8b vs 14b) | `AXIO_CLINICAL_MODEL_REASONING/_TRIAGE/_EMBED` |
| Puertos (si varias clínicas en un host) | mapeos `ports:` del compose + `.env` |
| BD / credenciales | `POSTGRES_*`, DSNs |

## 5. Nueva clínica — checklist

1. Copiar el stack a una carpeta nueva por clínica (o usar `-p <clinica>` del compose para aislar).
2. `cp .env.example .env` y **generar secretos nuevos** (no reutilizar entre clínicas).
3. Ajustar la contraseña de `console_ro` (`02-console-ro.sql`) para que coincida con el `.env`.
4. Ajustar branding (paleta/logo si la clínica lo pide) y modelos Ollama según hardware.
5. `docker compose up -d --build` + `./scripts/smoke.sh`.
6. Verificar E2E (ver [`integration.md`](integration.md) §Verificación).

## 6. Verificación end-to-end

1. `docker compose ps` → 4 servicios healthy.
2. `./scripts/smoke.sh` verde (turno normal + crisis N3 contra Ollama real).
3. Consola `:5173`: login, ver observación del turno, registrar outcome, gates fail-closed.
4. El agente responde como **AXIO Clinical Agent**; **N3 corta antes del LLM**.
5. Tests: `./scripts/test-motor.sh`, `docker compose exec consola-api python -m pytest -q`.
