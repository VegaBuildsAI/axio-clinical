#!/usr/bin/env bash
# Suite completa del motor (188) dentro del contenedor, contra el Postgres del
# compose. Desetea las AXIO_CLINICAL_* del runtime (los tests traen su propio env;
# con el env real heredado fallan 16) y usa la BD axio_clinical_motor_test — NUNCA
# la axio_clinical_motor real.
set -euo pipefail
cd "$(dirname "$0")/.."

PGPASS=$(grep '^POSTGRES_PASSWORD=' .env | cut -d= -f2)
docker compose exec -T motor sh -c '
  for v in $(env | grep "^AXIO_CLINICAL_" | cut -d= -f1); do unset $v; done
  export AXIO_CLINICAL_TEST_SOR_DSN="postgresql+psycopg://axio_clinical:'"$PGPASS"'@postgres:5432/axio_clinical_motor_test"
  python -m pytest -q "$@"
' sh "$@"
