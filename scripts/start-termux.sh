#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

if [[ -z "${PREFIX:-}" || "$PREFIX" != *com.termux* ]]; then
  echo "Jalankan launcher ini dari aplikasi Termux." >&2
  exit 2
fi
if ! command -v proot-distro >/dev/null 2>&1; then
  echo "proot-distro belum terpasang. Jalankan scripts/install-termux.sh terlebih dahulu." >&2
  exit 2
fi

exec proot-distro login debian -- env \
  "DEV_PORT=${DEV_PORT:-8125}" \
  "ML_PORT=${ML_PORT:-8123}" \
  "ONNX_THREADS=${ONNX_THREADS:-2}" \
  "PIPELINE_PAGE_CONCURRENCY=${PIPELINE_PAGE_CONCURRENCY:-1}" \
  bash -lc 'exec bash /root/xianscan-termux/scripts/start-termux-proot.sh'
