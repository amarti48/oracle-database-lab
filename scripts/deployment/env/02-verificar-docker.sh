#!/usr/bin/env bash
# scripts/deployment/env/02-verificar-docker.sh
echo "== Cliente y Servidor Docker =="
docker version
echo
echo "== Información del sistema Docker =="
docker info | grep -E "Server Version|Storage Driver|Logging Driver|Cgroup Driver|Operating System"
