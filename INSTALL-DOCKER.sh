#!/usr/bin/env bash
set -e

# ---- sanity check ----
if [ "$EUID" -eq 0 ]; then
  echo "❌ Do NOT run as root"
  exit 1
fi

# ---- minimal dependencies ----
sudo apt-get update -qq
sudo apt-get install -y --no-install-recommends \
  uidmap \
  dbus-user-session \
  curl

# ---- kernel limits (required for rootless) ----
sudo sysctl -w kernel.unprivileged_userns_clone=1 >/dev/null

# ---- install rootless docker ----
curl -fsSL https://get.docker.com/rootless | sh

# ---- environment ----
export PATH="$HOME/bin:$PATH"
export DOCKER_HOST="unix:///run/user/$(id -u)/docker.sock"

# ---- persist env ----
grep -q docker.sock ~/.bashrc || cat >> ~/.bashrc <<EOF

# Rootless Docker
export PATH="\$HOME/bin:\$PATH"
export DOCKER_HOST="unix:///run/user/\$(id -u)/docker.sock"
EOF

# ---- enable linger so docker survives SSH logout ----
sudo loginctl enable-linger "$USER"

# ---- start docker ----
systemctl --user enable docker
systemctl --user start docker

echo "✔ Rootless Docker installed"
docker --version
docker compose version
