#!/bin/bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
COMPOSE_PROJECT_NAME="monitoring-server"
ACTION="${1:-up}"
ENV_NAME="${2:-dev}"
shift $(( $# > 0 ? 1 : 0 )) || true
shift $(( $# > 0 ? 1 : 0 )) || true

usage() {
  echo "Usage: ./scripts/run.docker.sh [up|down|logs|ps|restart] [dev|prod] [docker compose options]" >&2
}

case "$ACTION" in
  up|down|logs|ps|restart) ;;
  *) usage; exit 1 ;;
esac

case "$ENV_NAME" in
  dev|prod) COMPOSE_FILE="$PROJECT_ROOT/docker/$ENV_NAME/compose.yml" ;;
  *) usage; exit 1 ;;
esac

SERVICE_SHARED_NETWORK="${SERVICE_SHARED_NETWORK:-service-backbone-shared}"
if ! docker network inspect "$SERVICE_SHARED_NETWORK" >/dev/null 2>&1; then
  echo "Creating external network: $SERVICE_SHARED_NETWORK"
  docker network create "$SERVICE_SHARED_NETWORK" >/dev/null
fi

compose() {
  SERVICE_SHARED_NETWORK="$SERVICE_SHARED_NETWORK" docker compose -p "$COMPOSE_PROJECT_NAME" -f "$COMPOSE_FILE" "$@"
}

case "$ACTION" in
  up)
    if [[ "$ENV_NAME" == "prod" ]]; then
      compose pull "$@"
    fi
    compose up -d "$@"
    ;;
  down) compose down --remove-orphans "$@" ;;
  logs) compose logs -f "$@" ;;
  ps) compose ps "$@" ;;
  restart)
    compose down --remove-orphans
    if [[ "$ENV_NAME" == "prod" ]]; then
      compose pull "$@"
    fi
    compose up -d "$@"
    ;;
esac
