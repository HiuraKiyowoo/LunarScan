#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

if [[ "${EUID}" -eq 0 ]]; then
  echo "Jangan jalankan installer sebagai root. Jalankan sebagai user biasa yang punya sudo." >&2
  exit 2
fi
if [[ ! -f /etc/os-release ]]; then
  echo "Tidak bisa mendeteksi distribusi Linux." >&2
  exit 2
fi
# shellcheck disable=SC1091
source /etc/os-release
if [[ "${ID:-}" != "ubuntu" ]]; then
  echo "Installer ini ditujukan untuk Ubuntu; terdeteksi: ${PRETTY_NAME:-unknown}." >&2
  exit 2
fi
if [[ "$(uname -m)" != "x86_64" && "$(uname -m)" != "aarch64" ]]; then
  echo "Arsitektur tidak didukung: $(uname -m). Gunakan VPS x86_64 atau ARM64." >&2
  exit 2
fi
if [[ "$ROOT" =~ [[:space:]] ]]; then
  echo "Path repository tidak boleh mengandung spasi untuk dukungan systemd." >&2
  exit 2
fi
if ! command -v sudo >/dev/null 2>&1; then
  echo "Perintah sudo tidak ditemukan. Siapkan sudo untuk user ini lalu ulangi." >&2
  exit 2
fi

sudo apt-get update
sudo apt-get install -y --no-install-recommends \
  build-essential ca-certificates curl git pkg-config python3 unzip xz-utils \
  libfontconfig1 libfontconfig1-dev

if ! command -v rustup >/dev/null 2>&1; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal
fi
# shellcheck disable=SC1091
source "$HOME/.cargo/env"
rustup toolchain install stable --profile minimal
rustup default stable

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
fi
# shellcheck disable=SC1091
source "$NVM_DIR/nvm.sh"
cd "$ROOT"
nvm install
nvm use
corepack enable
corepack prepare yarn@1.22.22 --activate

printf '\n== Install UI dependencies and build production UI ==\n'
cd "$ROOT/web"
yarn install --frozen-lockfile --network-timeout 120000 --network-concurrency 4
yarn build

printf '\n== Download pinned ONNX models (about 403 MB) ==\n'
cd "$ROOT"
bash scripts/fetch-models.sh

printf '\n== Build CPU backend (Cargo jobs: %s) ==\n' "${CARGO_BUILD_JOBS:-2}"
CARGO_BUILD_JOBS="${CARGO_BUILD_JOBS:-2}" cargo build --release --no-default-features -j "${CARGO_BUILD_JOBS:-2}"

printf '\nSetup build Ubuntu selesai. Model: %s/models\n' "$ROOT"
printf 'Jalankan sekarang: %s/scripts/start-ubuntu.sh\n' "$ROOT"
printf 'Pasang service systemd: sudo bash %s/scripts/install-ubuntu-service.sh\n' "$ROOT"
printf 'Panduan lengkap: %s/docs/ubuntu-vps.md\n' "$ROOT"
