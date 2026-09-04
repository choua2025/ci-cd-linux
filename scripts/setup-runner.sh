#!/usr/bin/env bash
# One-time setup of a self-hosted GitHub Actions runner inside WSL Ubuntu.
#
# Why self-hosted: this machine has no public address, so GitHub's cloud
# runners cannot reach it. A self-hosted runner polls GitHub outbound instead,
# which works fine behind NAT and needs no inbound ports, no SSH, no password.
#
# Get a registration token (valid ~1 hour) from:
#   https://github.com/choua2025/ci-cd-linux/settings/actions/runners/new
#
# Usage: ./scripts/setup-runner.sh <REGISTRATION_TOKEN>
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/choua2025/ci-cd-linux}"
RUNNER_DIR="${RUNNER_DIR:-$HOME/actions-runner}"
LABELS="${LABELS:-wsl-ubuntu}"

TOKEN="${1:-}"
if [ -z "$TOKEN" ]; then
  echo "Usage: $0 <REGISTRATION_TOKEN>" >&2
  echo "Get one at: ${REPO_URL}/settings/actions/runners/new" >&2
  exit 1
fi

command -v docker >/dev/null || { echo "!! docker not found in WSL" >&2; exit 1; }
docker info >/dev/null 2>&1 || { echo "!! docker daemon unreachable (is Docker Desktop running?)" >&2; exit 1; }

mkdir -p "$RUNNER_DIR"
cd "$RUNNER_DIR"

if [ ! -f ./config.sh ]; then
  VERSION="$(curl -fsSL https://api.github.com/repos/actions/runner/releases/latest \
    | grep -m1 '"tag_name"' | sed -E 's/.*"v?([^"]+)".*/\1/')"
  echo "==> Downloading runner v${VERSION}"
  curl -fsSL -o runner.tar.gz \
    "https://github.com/actions/runner/releases/download/v${VERSION}/actions-runner-linux-x64-${VERSION}.tar.gz"
  tar xzf runner.tar.gz && rm runner.tar.gz
  sudo ./bin/installdependencies.sh
fi

if [ ! -f .runner ]; then
  echo "==> Registering with ${REPO_URL}"
  ./config.sh --unattended --url "$REPO_URL" --token "$TOKEN" \
    --name "wsl-$(hostname)" --labels "$LABELS" --work _work --replace
fi

echo "==> Installing as a systemd service"
sudo ./svc.sh install "$USER"
sudo ./svc.sh start
sudo ./svc.sh status || true

echo
echo "Runner is live. It will pick up jobs targeting: [self-hosted, linux, ${LABELS}]"
