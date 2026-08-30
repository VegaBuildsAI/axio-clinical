-- Segunda base en el mismo Postgres: la consola (D2: el motor es dueño del
-- hilo; la consola tendrá su propia BD hasta que la Fase 3 la haga leer la
-- del motor por subject_id).
CREATE DATABASE axio_clinical_console;
GRANT ALL PRIVILEGES ON DATABASE axio_clinical_console TO axio_clinical;

-- BD efímera para la suite del motor (AXIO_CLINICAL_TEST_SOR_DSN); los tests la
-- migran y limpian solos. Nunca correr la suite contra axio_clinical_motor.
CREATE DATABASE axio_clinical_motor_test;
GRANT ALL PRIVILEGES ON DATABASE axio_clinical_motor_test TO axio_clinical;
