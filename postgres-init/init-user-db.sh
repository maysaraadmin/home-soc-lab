#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE USER cortex WITH PASSWORD 'cortex';
    GRANT ALL PRIVILEGES ON DATABASE cortex TO cortex;
EOSQL
