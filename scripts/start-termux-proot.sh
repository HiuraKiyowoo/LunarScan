#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
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
  echo "Binary belum dibangun. Dari Termux jalankan scripts/install-termux.sh." >&2
  exit 2
fi
if [[ ! -d "$ROOT/web/node_modules" ]]; then
  echo "Dependency UI belum terpasang. Jalankan scripts/install-termux.sh." >&2
  exit 2
fi

cd "$ROOT"
export MODELS_DIR="${MODELS_DIR:-$ROOT/models}"
export MT_DEVICE="${MT_DEVICE:-cpu}"
export ONNX_THREADS="${ONNX_THREADS:-2}"
export PIPELINE_PAGE_CONCURRENCY="${PIPELINE_PAGE_CONCURRENCY:-1}"
export ML_PORT="${ML_PORT:-8123}"
export DEV_PORT="${DEV_PORT:-8125}"

printf 'XianScan UI: http://127.0.0.1:%s\n' "$DEV_PORT"
printf 'Berhenti dengan Ctrl+C. Pertahankan Termux di foreground.\n'
exec "$ROOT/target/release/xianscan" --dev
