#!/usr/bin/env bash
# Deploys the app locally with docker compose and verifies it came up healthy.
# Safe to run by hand or from the self-hosted GitHub Actions runner.
set -euo pipefail

cd "$(dirname "$0")/.."

# Pin the compose project name so a CI deploy and a manual `docker compose up`
# from a different directory manage the SAME stack instead of two rival copies.
export COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-ci-cd-linux}"
PORT="${PORT:-3030}"
export PORT

echo "==> Building and starting (project=$COMPOSE_PROJECT_NAME, port=$PORT)"
docker compose up -d --build --remove-orphans

CONTAINER="$(docker compose ps -q app)"
if [ -z "$CONTAINER" ]; then
  echo "!! app container did not start" >&2
  docker compose logs --no-color app >&2 || true
  exit 1
fi

echo "==> Waiting for health"
for _ in $(seq 1 60); do
  status="$(docker inspect --format '{{.State.Health.Status}}' "$CONTAINER" 2>/dev/null || echo unknown)"
  [ "$status" = "healthy" ] && break
  if [ "$status" = "unhealthy" ]; then
    echo "!! container reported unhealthy" >&2
    docker compose logs --no-color app >&2
    exit 1
  fi
  sleep 2
done

if [ "${status:-}" != "healthy" ]; then
  echo "!! timed out waiting for health (last status: ${status:-none})" >&2
  docker compose logs --no-color app >&2
  exit 1
fi

echo "==> Smoke test"
body="$(curl -fsS --max-time 5 "http://127.0.0.1:${PORT}/hello")"
if [ "$body" != "Hello world" ]; then
  echo "!! unexpected response: '$body'" >&2
  exit 1
fi

echo "==> Deployed OK: http://localhost:${PORT}/hello -> $body"
docker compose ps
