#!/usr/bin/env bash
set -euo pipefail

# Cross-build the Rust ML/API backend for Android ARM64 (Termux). This does NOT
# bundle the SvelteKit/Node web UI or model weights; run with --ml-only.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="aarch64-linux-android"
API="${ANDROID_API_LEVEL:-24}"
NDK_ROOT="${ANDROID_NDK_HOME:-${ANDROID_NDK_ROOT:-}}"

if [[ -z "$NDK_ROOT" ]]; then
  echo "Set ANDROID_NDK_HOME (or ANDROID_NDK_ROOT) to an installed Android NDK." >&2
  exit 2
fi
HOST_TAG="${ANDROID_NDK_HOST_TAG:-linux-x86_64}"
TOOLCHAIN="$NDK_ROOT/toolchains/llvm/prebuilt/$HOST_TAG/bin"
CLANG="$TOOLCHAIN/aarch64-linux-android${API}-clang"
AR="$TOOLCHAIN/llvm-ar"
CXX_SHARED="$NDK_ROOT/toolchains/llvm/prebuilt/$HOST_TAG/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so"

if [[ -f "$HOME/.cargo/env" ]]; then
  # shellcheck disable=SC1091
  source "$HOME/.cargo/env"
fi

for f in "$CLANG" "$AR" "$CXX_SHARED"; do
  if [[ ! -e "$f" ]]; then
    echo "Missing NDK file: $f" >&2
    exit 2
  fi
done

if ! command -v cargo >/dev/null 2>&1; then
  echo "Install Rust/Cargo and add the Android target first." >&2
  exit 2
fi
rustup target add "$TARGET"

cd "$ROOT"
CC_aarch64_linux_android="$CLANG" \
AR_aarch64_linux_android="$AR" \
CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER="$CLANG" \
cargo build --release --no-default-features --target "$TARGET"

OUT="$ROOT/dist/termux-arm64"
mkdir -p "$OUT/lib"
install -m 0755 "$ROOT/target/$TARGET/release/xianscan" "$OUT/xianscan"
install -m 0644 "$CXX_SHARED" "$OUT/lib/libc++_shared.so"
cat > "$OUT/run-ml.sh" <<'RUNNER'
#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
export LD_LIBRARY_PATH="$HERE/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export MODELS_DIR="${MODELS_DIR:-$HOME/xianscan/models}"
export MT_DEVICE="${MT_DEVICE:-cpu}"
export ONNX_THREADS="${ONNX_THREADS:-2}"
export PIPELINE_PAGE_CONCURRENCY="${PIPELINE_PAGE_CONCURRENCY:-1}"
exec "$HERE/xianscan" --ml-only "$@"
RUNNER
chmod 0755 "$OUT/run-ml.sh"
cat > "$OUT/README.txt" <<TXT
Lunar Android ARM64 Rust ML/API backend (Termux), based on XianScan upstream

This package contains only the native Rust ML/API process and libc++_shared.so.
It does not include the web studio, Node.js, or ONNX model weights.

On an ARM64 Android device with Termux, copy this directory into Termux's
private home (not shared /sdcard storage), make sure model files are under
\$HOME/xianscan/models (or set MODELS_DIR), then run:
  ./run-ml.sh

Default ML-only endpoint: 127.0.0.1:8123. This is a backend/API build, not a
complete interactive Lunar app. Model downloads and end-to-end inference
must be validated on the target phone. Android GPU acceleration is not enabled.
Build API level: $API
TXT

printf 'Android ARM64 ML backend packaged at: %s\n' "$OUT"
printf 'Next: copy dist/termux-arm64 to Termux private home and test on an ARM64 Android device.\n'
