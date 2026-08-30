-- Rol de SOLO LECTURA con el que la consola lee la BD del motor (Fase 3, D2):
-- aunque un bug intentara escribir el hilo desde la consola, Postgres lo
-- rechaza. La contraseña real vive en .env (MOTOR_DATABASE_URL); si se cambia
-- acá, cambiala allá. DEFAULT PRIVILEGES cubre las tablas que las migraciones
-- Alembic del motor crean después de este init.
CREATE ROLE console_ro LOGIN PASSWORD '__SET_CONSOLE_RO_PASSWORD__';  -- reemplazar en el deploy; debe coincidir con MOTOR_DATABASE_URL en .env
GRANT CONNECT ON DATABASE axio_clinical_motor TO console_ro;

\connect axio_clinical_motor
GRANT USAGE ON SCHEMA public TO console_ro;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO console_ro;
ALTER DEFAULT PRIVILEGES FOR ROLE axio_clinical IN SCHEMA public
    GRANT SELECT ON TABLES TO console_ro;
