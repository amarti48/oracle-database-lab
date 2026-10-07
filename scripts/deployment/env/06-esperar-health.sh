#!/usr/bin/env bash
# scripts/deployment/env/06-esperar-health.sh
set -euo pipefail
source scripts/deployment/env/00-config.sh

echo "== Esperando a que el contenedor $CONT_NAME cambie a estado HEALTHY =="

until [ "$(docker inspect --format='{{.State.Health.Status}}' "$CONT_NAME" 2>/dev/null)" = "healthy" ]; do
  STATUS=$(docker inspect --format='{{.State.Health.Status}}' "$CONT_NAME" 2>/dev/null || echo "desconocido")
  echo "[$(date +'%H:%M:%S')] Estado actual: $STATUS. Reintentando en 15 segundos..."
  sleep 15
done

echo "== ¡Contenedor $CONT_NAME en estado HEALTHY! =="
docker ps --filter "name=$CONT_NAME"
