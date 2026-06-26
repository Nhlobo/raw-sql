#!/bin/sh
set -e

if [ -z "$DATABASE_URL" ]; then
  echo "DATABASE_URL is required"
  exit 1
fi

psql "$DATABASE_URL" -v ON_ERROR_STOP=1 <<'SQL'
CREATE TABLE IF NOT EXISTS public.schema_migrations (
  filename text PRIMARY KEY,
  applied_at timestamptz NOT NULL DEFAULT now()
);
SQL

for f in /app/database/*.sql; do
  [ -e "$f" ] || continue

  name=$(basename "$f")

  already_applied=$(psql "$DATABASE_URL" -t -A -c \
    "SELECT 1 FROM public.schema_migrations WHERE filename = '$name' LIMIT 1;")

  if [ "$already_applied" = "1" ]; then
    echo "Skipping $name (already applied)"
    continue
  fi

  echo "Running $name"
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$f"

  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -c \
    "INSERT INTO public.schema_migrations (filename) VALUES ('$name');"
done

echo "All migrations completed successfully."
exec java -jar /app/app.jar
