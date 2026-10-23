#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# One-command Termux bootstrap. The actual build runs in Debian ARM64 proot,
# where glibc Node native addons are supported more reliably than on Android.
if [[ -z "${PREFIX:-}" || "$PREFIX" != *com.termux* ]]; then
  echo "Jalankan skrip ini dari aplikasi Termux, bukan Debian proot atau Linux biasa." >&2
  exit 2
fi

pkg update -y
pkg install -y proot-distro git

if ! proot-distro list --installed 2>/dev/null | grep -qi 'debian'; then
  proot-distro install debian
fi

proot-distro login debian -- bash -lc '
set -euo pipefail
if [[ ! -d /root/xianscan-termux/.git ]]; then
  git clone https://github.com/HiuraKiyowoo/xianscan-termux.git /root/xianscan-termux
else
  git -C /root/xianscan-termux pull --ff-only
fi
bash /root/xianscan-termux/scripts/setup-termux-proot-debian.sh
'

echo
echo "Instalasi selesai. Jalankan: $HOME/xianscan-termux/scripts/start-termux.sh"
echo "Lalu buka http://127.0.0.1:8125 di browser Android."
