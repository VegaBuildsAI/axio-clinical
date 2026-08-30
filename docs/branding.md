# Branding — Tema visual AXIO Clinical

Marca AXIO: **monocroma navy + steel/plateado**, wordmark **AXIO** geométrico con la **"A" en
chevron** (sin travesaño).

## Paleta

| Rol | HEX | Uso |
|---|---|---|
| primario (navy) | `#1E293B` | marca / botones / sidebar |
| primario-dark | `#0F172A` | hover / texto ink |
| acento (steel) | `#64748B` | acentos / secundarios |
| CTA (steel-navy) | `#334155` | acción |
| gradient | `linear-gradient(135deg,#1E293B 0%,#475569 100%)` | botones / hero |
| bg | `#F8FAFC` | fondo |
| surface | `#FFFFFF` | superficie |
| border | `#E2E8F0` | bordes |
| muted | `#64748B` | texto atenuado |
| sidebar | `#0B1020` | navy de marca (sidebar) |

## Dónde viven los tokens

- Consola: `frontend/tailwind.config.ts`.
- Vega: `mobile/src/theme.ts`, `admin/lib/brand.ts` + `admin/app/globals.css` +
  `admin/components/routeColors.ts`.

Se conservan los **nombres** de token (usados como clases); solo cambian los HEX. Los colores de
estado de cita (`ESTADO` / `ESTADO_COLOR`) se mantienen: son **semánticos**, no marca.

## Logo

Geometría vectorial exacta (chevron "A", no tipografía de sistema). Variantes monocromas:

- **navy→steel sobre claro** (`#1E293B→#475569`, sin fondo): login mobile y admin.
- **plateado sobre navy** (`#EEF3FF→#A8B4CC`): ícono de app (la "A" aislada).
- Consola: `favicon.svg` (A chevron) + `axio-logo.svg` (wordmark), navy sin fondo.

## Personalización por clínica

El branding (paleta/logo) es un **parámetro por instancia**. Una clínica puede pedir su propia
paleta: se ajustan los HEX de los tokens (no los nombres) y los assets de logo/favicon. Ver
[`deployment.md`](deployment.md) §4.

## Pendiente (opcional)

- Tipografías AXIO reales (hoy la UI usa `Inter` / `system-ui`; el logo es geometría vectorial).
- Splash de mobile; revisar hover/activo tras cualquier ajuste fino de paleta.
