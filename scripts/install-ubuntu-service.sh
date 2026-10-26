#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 || -z "${SUDO_USER:-}" || "$SUDO_USER" == "root" ]]; then
  echo "Jalankan sebagai: sudo bash scripts/install-ubuntu-service.sh (dari user biasa)." >&2
  exit 2
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SERVICE_USER="$SUDO_USER"
SERVICE_HOME="$(getent passwd "$SERVICE_USER" | cut -d: -f6)"
NODE_VERSION="$(tr -d '[:space:]' < "$ROOT/.nvmrc")"
NODE_BIN="$SERVICE_HOME/.nvm/versions/node/v$NODE_VERSION/bin/node"

if [[ -z "$SERVICE_HOME" || ! -x "$NODE_BIN" ]]; then
  echo "Node.js v$NODE_VERSION tidak ditemukan di $SERVICE_HOME/.nvm. Jalankan scripts/install-ubuntu.sh sebagai $SERVICE_USER." >&2
  exit 2
fi
if [[ ! -x "$ROOT/target/release/xianscan" || ! -f "$ROOT/web/build/index.js" ]]; then
  echo "Build belum lengkap. Jalankan scripts/install-ubuntu.sh sebagai $SERVICE_USER." >&2
  exit 2
fi
if [[ "$ROOT" =~ [[:space:]] || "$SERVICE_HOME" =~ [[:space:]] ]]; then
  echo "Path service tidak boleh mengandung spasi." >&2
  exit 2
fi

NODE_DIR="${NODE_BIN%/*}"
UNIT_TMP="$(mktemp)"
trap 'rm -f "$UNIT_TMP"' EXIT
cat > "$UNIT_TMP" <<UNIT
[Unit]
Description=Lunar comic translation studio
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$SERVICE_USER
WorkingDirectory=$ROOT
Environment=HOME=$SERVICE_HOME
Environment=PATH=$NODE_DIR:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
Environment=MODELS_DIR=$ROOT/models
Environment=MT_DEVICE=cpu
Environment=PORT=8124
Environment=ML_PORT=8123
Environment=ONNX_THREADS=2
Environment=PIPELINE_PAGE_CONCURRENCY=1
UMask=0077
ExecStart=$ROOT/target/release/xianscan
Restart=on-failure
RestartSec=5
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
UNIT

install -o root -g root -m 0644 "$UNIT_TMP" /etc/systemd/system/lunar.service
systemctl daemon-reload
systemctl enable --now lunar.service
systemctl --no-pager --full status lunar.service
printf '\nService lunar.service aktif. Log: sudo journalctl -u lunar.service -f\n'
printf 'Port aplikasi 8124 hanya bind ke localhost secara default; port ML 8123 juga tidak diekspos.\n'
