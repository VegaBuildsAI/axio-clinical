# Seguridad — AXIO Clinical

AXIO Clinical procesa información clínica sensible (PHI). El diseño es **local-first / on-premise**:
los datos de pacientes **no salen** de la infraestructura de la clínica.

## Principios

- **De-identificación Safe-Harbor**: identificadores directos nunca en claro entre servicios; sujeto
  por seudónimo `ax_<id>`; identidad directa **cifrada y separada**.
- **Fail-closed**: el motor **no arranca** sin llaves de cifrado (`AXIO_CLINICAL_IDENTITY_KEY/_PEPPER`)
  cuando hay SoR; los gates de la consola cierran ante duda o fallo.
- **Crisis determinista (N3)**: la escalación ocurre **antes** del LLM; no depende del modelo.
- **Audit append-only**: las observaciones de cada turno son auditables y no reescribibles.
- **Menor privilegio**: la consola lee el SoR con rol `console_ro` (**solo SELECT**).

## Gestión de secretos

- **Ningún secreto se versiona.** Todos viven en `.env` por instancia (ver [`.env.example`](.env.example)).
- Generá secretos **nuevos por clínica** (no reutilizar):
  ```bash
  python -c "import secrets; print(secrets.token_urlsafe(32))"                    # tokens
  python -c "import os,base64; print(base64.b64encode(os.urandom(32)).decode())"  # pepper/key
  ```
- La contraseña del rol `console_ro` (`orchestration/scripts/initdb/02-console-ro.sql`) es un
  **placeholder** en el repo; reemplazala en el deploy y hacela coincidir con `MOTOR_DATABASE_URL`.

## Antes de publicar cualquier repo del stack

Verificar que **no** entren secretos ni artefactos:

```bash
git ls-files | grep -E '(^|/)\.env$|node_modules|\.venv|/dist/|/build/' && echo "STOP: hay basura/secretos" || echo "OK"
```

## Divulgación responsable

Repositorio **privado**. Reportá cualquier hallazgo de seguridad **de forma privada** al equipo AXIO
por el canal interno. No abras issues públicos ni compartas detalles fuera de ese canal.

Detalle técnico de controles PHI en [`docs/security-phi.md`](docs/security-phi.md).
