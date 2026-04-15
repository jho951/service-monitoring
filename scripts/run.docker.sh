#!/bin/bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
COMPOSE_FILE="$PROJECT_ROOT/docker/compose.yml"
COMPOSE_PROJECT_NAME="monitoring-server"
ACTION="${1:-up}"
SERVICE_SHARED_NETWORK="${SERVICE_SHARED_NETWORK:-service-backbone-shared}"

case "$ACTION" in
  up|down)
    ;;
  *)
    echo "Usage: ./scripts/run.docker.sh [up|down]"
    exit 1
    ;;
esac

ensure_network() {
  local network_name="$1"
  if ! docker network inspect "$network_name" >/dev/null 2>&1; then
    echo "Creating external network: $network_name"
    docker network create "$network_name" >/dev/null
  fi
}

if [[ "$ACTION" == "up" ]]; then
  ensure_network "$SERVICE_SHARED_NETWORK"
  SERVICE_SHARED_NETWORK="$SERVICE_SHARED_NETWORK" docker compose -p "$COMPOSE_PROJECT_NAME" -f "$COMPOSE_FILE" up -d
else
  SERVICE_SHARED_NETWORK="$SERVICE_SHARED_NETWORK" docker compose -p "$COMPOSE_PROJECT_NAME" -f "$COMPOSE_FILE" down --remove-orphans
fi

