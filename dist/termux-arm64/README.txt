XianScan Android ARM64 Rust ML/API backend (Termux)

This package contains only the native Rust ML/API process and libc++_shared.so.
It does not include the web studio, Node.js, or ONNX model weights.

On an ARM64 Android device with Termux, copy this directory into Termux's
private home (not shared /sdcard storage), make sure model files are under
$HOME/xianscan/models (or set MODELS_DIR), then run:
  ./run-ml.sh

Default ML-only endpoint: 127.0.0.1:8123. This is a backend/API build, not a
complete interactive XianScan app. Model downloads and end-to-end inference
must be validated on the target phone. Android GPU acceleration is not enabled.
Build API level: 24
