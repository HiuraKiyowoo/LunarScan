# XianScan di Android/Termux

> **Status port:** source Rust XianScan berhasil di-cross-check dan di-link sebagai ELF Android ARM64 menggunakan Android NDK. Skrip `scripts/build-android-termux.sh` menghasilkan **backend ML/API saja** (`--ml-only`), bukan paket aplikasi lengkap. Eksekusi binary, model, dan inferensi masih harus diuji di perangkat Android ARM64. Untuk UI web penuh, jalur eksperimen yang disiapkan adalah Debian lewat `proot-distro`.

## A. Backend native Termux (Android ARM64)

Build dilakukan di Linux x86_64 dengan Rust stable dan Android NDK r27c (atau NDK kompatibel). Di checkout proyek:

```sh
rustup target add aarch64-linux-android
ANDROID_NDK_HOME=/path/to/android-ndk-r27c \
ANDROID_API_LEVEL=24 \
./scripts/build-android-termux.sh
```

Hasil ada di `dist/termux-arm64/`: executable `xianscan`, `lib/libc++_shared.so`, runner `run-ml.sh`, dan catatan paket. Build ini tidak menyertakan Node/SvelteKit, UI, atau model ONNX.

Salin seluruh direktori `dist/termux-arm64` ke **private home** Termux di ponsel ARM64, bukan ke `/sdcard` (filesystem berbagi bisa menghalangi eksekusi). Siapkan model ONNX di `$HOME/xianscan/models` sesuai `models/manifest.tsv`, kemudian:

```sh
cd ~/termux-arm64
chmod +x xianscan run-ml.sh
MODELS_DIR="$HOME/xianscan/models" ./run-ml.sh
```

Backend ML-only seharusnya mendengarkan di `127.0.0.1:8123`; ia tidak menyajikan studio web. Jalankan dengan Termux di foreground. Mulai dengan konfigurasi CPU bawaan (`ONNX_THREADS=2`, `PIPELINE_PAGE_CONCURRENCY=1`). Jika startup atau load model gagal, simpan log lengkap; jangan menganggap cross-link sebagai bukti runtime/inference berhasil.

## B. UI web penuh lewat Debian proot-distro

Jalur ini menjalankan Linux ARM64 userspace Debian di Android dan berusaha menghindari ketidakcocokan Node native addons dengan Android/bionic.

Di Termux:

```sh
pkg update -y
pkg install proot-distro -y
proot-distro install debian
proot-distro login debian
```

Semua langkah selanjutnya dijalankan **di dalam sesi Debian**.

Pasang toolchain:

```sh
apt update
apt install -y git curl ca-certificates build-essential python3 pkg-config libfontconfig1-dev unzip xz-utils
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal
. "$HOME/.cargo/env"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
. "$HOME/.bashrc"
git clone https://github.com/ArbenApura/xianscan-rust.git /root/xianscan-rust
cd /root/xianscan-rust
nvm install
corepack enable
```

Pastikan tersedia ruang kosong beberapa GB untuk models, Node dependencies, cache, dan build. RAM serta kecepatan CPU ponsel mempengaruhi kelayakan inferensi.

Build dan jalankan mode development CPU:

```sh
cd /root/xianscan-rust
. "$HOME/.cargo/env"
cd web
corepack yarn install
cd ..
bash scripts/fetch-models.sh
MODELS_DIR="$PWD/models" MT_DEVICE=cpu ONNX_THREADS=2 PIPELINE_PAGE_CONCURRENCY=1 cargo run --release -- --dev
```

Buka `http://127.0.0.1:8125` di browser Android. Jika instalasi `better-sqlite3` atau `@napi-rs/canvas` gagal, jangan salin addon dari arsitektur/OS lain—perbaiki dependency di Debian ARM64.

## C. Batasan dan tes wajib di ponsel

- Rilis resmi yang ada bukan paket Android; jangan jalankan arsip Linux x86_64 pada ponsel ARM64.
- Build native yang diuji di sandbox adalah Rust backend saja dengan target Android API 24 dan tanpa fitur akselerasi GPU. Belum diuji runtime langsung di Android, akses filesystem Termux, lifecycle proses, pemuatan model, atau respons inferensi.
- Untuk backend native, tes di perangkat: `./run-ml.sh`, cek log startup dan port `8123`, health endpoint, lalu request analyze/inpaint menggunakan model dan gambar uji. Verifikasi restart dan lokasi database.
- Untuk UI penuh proot, tes: buka studio dari browser Android, buat buku, muat gambar, jalankan OCR/inpainting, restart, dan pastikan database/cache bertahan.
- Android dapat menghentikan Termux saat aplikasi di latar belakang atau dibatasi baterai; pertahankan Termux di foreground selama proses panjang.
- Gunakan `127.0.0.1` untuk lokal. Jangan aktifkan akses LAN kecuali memang dibutuhkan dan token akses dijaga.
