# Componentes — mapa de repos y estado

Este repo umbrella documenta el sistema completo; el **código de cada componente** vive en su propia
carpeta (hoy local) y, a medida que se publiquen, en su propio repo privado bajo
[`github.com/VegaBuildsAI`](https://github.com/VegaBuildsAI).

> **Estado de publicación (2026-08-30):** el único repo AXIO Clinical publicado es este umbrella
> (`VegaBuildsAI/axio-clinical`). Los repos de componentes `axio-clinical-*` están **planificados**
> (aún no creados). La fuente de verdad de cada componente es su carpeta local en `AXIO Clinic/`.

| Componente | Carpeta local | Rol | Repo (planificado) | Estado |
|---|---|---|---|---|
| **Motor Clínico** | `axio-clinical-motor-clinico` | Razonamiento, triaje N0–N3, crisis, SoR | `VegaBuildsAI/axio-clinical-motor-clinico` | local · repo pendiente |
| **Consola** | `axio-clinical-console` | Observabilidad, HITL, gates, precios | `VegaBuildsAI/axio-clinical-console` | local · repo pendiente |
| **Plataforma Vega** | `axio-clinical-platform-vega` | Backend paciente (NestJS) + APK (Expo) + admin (Next.js) | `VegaBuildsAI/axio-clinical-platform` | local · repo pendiente |
| **Web (demo)** | `axio-clinical-web` | Demo web del agente (Vite/React) | `VegaBuildsAI/axio-clinical-web` | local · repo pendiente |
| **Siku** | `axio-clinical-siku` | Conector IoLab/Siku | `VegaBuildsAI/axio-clinical-siku` | local · repo pendiente |
| **ContactShip** | `axio-clinical-contactship` | Puente voz/omnicanal | `VegaBuildsAI/axio-clinical-contactship` | local · repo pendiente |
| **Cashflow** | `axio-clinical-cashflow` | Módulo financiero/actas (satélite) | `VegaBuildsAI/repo-actas-solidaristas` | ver repo existente |
| **Orquestación** | `orchestration/` (ex `axio-clinical-local`) | Compose: motor+consola+postgres+oncall-sim | **incluido en este repo** | ✅ publicado aquí |
| **Docs** | `axio-clinical-docs` | Docs técnicos/planeación (PRD, auditorías, marca) | `VegaBuildsAI/axio-clinical-docs` | local · repo pendiente |

## Convención de publicación

Cuando se publique un componente, crear el repo **privado** bajo `VegaBuildsAI` con el nombre de la
columna "Repo (planificado)", y actualizar este archivo con el enlace real y el estado `✅ publicado`.

```bash
# ejemplo (desde la carpeta del componente, ya con su .gitignore y sin secretos):
gh repo create VegaBuildsAI/axio-clinical-motor-clinico --private --source=. --push \
  --description "AXIO Clinical · Motor Clínico (triaje N0–N3, crisis determinista, SoR cifrado)"
```

> Antes de publicar cualquier componente: verificar que `.env`, `node_modules`, `.venv`, builds y
> credenciales estén en `.gitignore` y **no** aparezcan en `git ls-files`.
