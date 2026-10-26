#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
if [[ -f "$HOME/.cargo/env" ]]; then
  # shellcheck disable=SC1091
  source "$HOME/.cargo/env"
fi
if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
  # shellcheck disable=SC1091
  source "$HOME/.nvm/nvm.sh"
  cd "$ROOT"
  nvm use --silent
fi

if [[ ! -x "$ROOT/target/release/xianscan" ]]; then
  echo "Binary belum dibangun. Jalankan scripts/install-ubuntu.sh terlebih dahulu." >&2
  exit 2
fi
if [[ ! -f "$ROOT/web/build/index.js" ]]; then
  echo "Build UI production belum ada. Jalankan scripts/install-ubuntu.sh terlebih dahulu." >&2
  exit 2
fi
if ! command -v node >/dev/null 2>&1; then
  echo "Node.js tidak ditemukan di PATH. Muat Node.js v24.18.1 terlebih dahulu." >&2
  exit 2
fi

cd "$ROOT"
export MODELS_DIR="${MODELS_DIR:-$ROOT/models}"
export MT_DEVICE="${MT_DEVICE:-cpu}"
export ONNX_THREADS="${ONNX_THREADS:-2}"
export PIPELINE_PAGE_CONCURRENCY="${PIPELINE_PAGE_CONCURRENCY:-1}"
export ML_PORT="${ML_PORT:-8123}"
export PORT="${PORT:-8124}"

printf 'Lunar production UI: http://127.0.0.1:%s\n' "$PORT"
printf 'Bind default: localhost only. Untuk akses remote gunakan SSH tunnel atau reverse proxy HTTPS.\n'
printf 'Berhenti dengan Ctrl+C.\n'
exec "$ROOT/target/release/xianscan"
