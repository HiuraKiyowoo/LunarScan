#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
export LD_LIBRARY_PATH="$HERE/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export MODELS_DIR="${MODELS_DIR:-$HOME/xianscan/models}"
export MT_DEVICE="${MT_DEVICE:-cpu}"
export ONNX_THREADS="${ONNX_THREADS:-2}"
export PIPELINE_PAGE_CONCURRENCY="${PIPELINE_PAGE_CONCURRENCY:-1}"
exec "$HERE/xianscan" --ml-only "$@"
