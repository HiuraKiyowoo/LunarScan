#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ ! -f /etc/debian_version ]]; then
  echo "Skrip ini harus dijalankan di Debian proot-distro." >&2
  exit 2
fi

apt-get update
apt-get install -y --no-install-recommends \
  build-essential ca-certificates curl git python3 pkg-config \
  libfontconfig1 libfontconfig1-dev unzip xz-utils coreutils

if [[ ! -x "$HOME/.cargo/bin/rustc" ]]; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal
fi
# shellcheck disable=SC1091
source "$HOME/.cargo/env"

if [[ ! -s "$HOME/.nvm/nvm.sh" ]]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
fi
# shellcheck disable=SC1091
source "$HOME/.nvm/nvm.sh"
cd "$ROOT"
nvm install
nvm use

if command -v corepack >/dev/null 2>&1; then
  corepack enable
  corepack prepare yarn@1.22.22 --activate
else
  npm install --global yarn@1.22.22
fi

cd "$ROOT/web"
yarn install --frozen-lockfile

cd "$ROOT"
echo "Mengunduh model ONNX (total manifest sekitar 403 MB)..."
bash scripts/fetch-models.sh

# Compile the full Rust API/ML server for Debian ARM64. `--dev` starts the
# already-installed Vite web UI alongside it when the user launches the app.
cargo build --release --no-default-features

echo
echo "Setup Debian proot selesai. Model tersimpan di: $ROOT/models"
echo "Keluar dari Debian, lalu jalankan dari Termux: bash \"\$HOME/xianscan-termux/scripts/start-termux.sh\""
