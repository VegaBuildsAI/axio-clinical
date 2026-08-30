# Contribuir — AXIO Clinical

Repo umbrella (docs + orquestación). Para código de componentes, ver su repo/carpeta
([`components.md`](components.md)).

## Convenciones de naming (obligatorias)

- Marca **AXIO Clinical**; agente **AXIO Clinical Agent**.
- Env keys con prefijo `AXIO_CLINICAL_*`.
- DB en **minúsculas**: `axio_clinical_motor`, `axio_clinical_console`; user `axio_clinical`.
- Endpoint del agente: `/axio-clinical-agent/infer` (cliente y servidor deben coincidir).
- Seudónimo de sujeto: `ax_<id>`.
- Codenames internos conservados (no marca): `vega`, `motor`, `consola`, `siku`.

## Reglas de oro

1. **Nunca** commitees secretos. Todo secreto va en `.env` (gitignored). El repo solo lleva `.env.example`.
2. **Nunca** subas `node_modules`, `.venv`, `dist`, `build`, `*.egg-info`, caches ni backups.
3. Antes de commitear, corré:
   ```bash
   git ls-files | grep -E '(^|/)\.env$|node_modules|\.venv|/dist/' && echo "STOP" || echo "OK"
   ```
4. Al renombrar/rebrandear, verificá con `rg --hidden` (ripgrep salta dotfiles por defecto).

## Levantar en local

Ver [`docs/deployment.md`](docs/deployment.md). Resumen:

```bash
cd orchestration && cp .env.example .env   # completar secretos
docker compose up -d --build && ./scripts/smoke.sh
```

## Documentación

Toda decisión de arquitectura/despliegue/seguridad se refleja en `docs/`. Mantené el diagrama
Mermaid ([`docs/diagrams/architecture.mmd`](docs/diagrams/architecture.mmd)) y el README en sincronía
con la realidad del stack.
