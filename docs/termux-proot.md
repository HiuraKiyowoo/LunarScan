# Panduan instalasi XianScan di Android/Termux

## Setup full app sekali saja

Cara yang direkomendasikan menjalankan UI web dan backend bersama-sama di Debian ARM64 melalui `proot-distro`. Di Termux:

```sh
pkg update -y
pkg install -y git proot-distro
git clone https://github.com/HiuraKiyowoo/xianscan-termux.git "$HOME/xianscan-termux"
cd "$HOME/xianscan-termux"
bash scripts/install-termux.sh
```

Installer akan memasang Debian, Rust, Node.js, dependency SvelteKit, membangun backend, dan mengunduh model ONNX. UI Vite dijalankan oleh launcher. Setup membutuhkan beberapa GB ruang kosong dan koneksi internet stabil. Model ONNX pada manifest total sekitar **403 MB**; build Rust/Node dan cache memerlukan ruang tambahan. Waktu setup tergantung perangkat, jadi jaga Termux tetap terbuka dan perangkat tidak masuk mode hemat daya.

Untuk penggunaan berikutnya, di Termux jalankan:

```sh
bash "$HOME/xianscan-termux/scripts/start-termux.sh"
```

Lalu buka **http://127.0.0.1:8125** di browser Android. UI dan API hanya diakses lokal. Tekan `Ctrl+C` untuk berhenti. Jika port default sedang dipakai, coba `DEV_PORT=8126 bash "$HOME/xianscan-termux/scripts/start-termux.sh"`.

Script setup dapat dijalankan ulang dari Termux jika pemasangan terputus:

```sh
proot-distro login debian -- bash -lc 'bash /root/xianscan-termux/scripts/setup-termux-proot-debian.sh'
```

## Gunakan NaraRouter untuk LLM terjemahan

LLM penerjemah tidak harus lokal. Di studio web buka **Settings → AI Translation Providers → Custom (OpenAI-Compatible)**, lalu isi:

- Base URL: `https://router.bynara.id/v1`
- API key: token NaraRouter milikmu
- Model: pilih/scan alias yang tersedia pada akun NaraRouter

Tekan **Test Connection**, kemudian jadikan provider itu aktif. Format ini mengikuti [dokumentasi API NaraRouter](https://router.bynara.id/docs). Jangan tempel token ke chat atau commit ke GitHub; masukkan langsung pada Settings di browser lokal.

Model ONNX tetap digunakan **secara lokal** untuk bagian pemrosesan gambar: deteksi teks/balon, OCR, dan inpainting. Ia bukan LLM penerjemah. Model yang diunduh saat ini berjumlah 7 dengan total sekitar 403 MB; dua yang terbesar adalah model deteksi (136 MB) dan inpainting (206 MB).

## Backend native Android tanpa UI (opsional)

Untuk eksperimen backend Rust native ARM64 saja, tersedia binary di `dist/termux-arm64/`. Binary ini tidak berisi Node, UI, atau model; jalankan `run-ml.sh` setelah menyiapkan bobot model. Port backend lokal default `8123`. Build Android ARM64 berhasil di Sandbox, tetapi runtime pada HP belum diuji. Untuk full UI, gunakan setup Debian proot di atas.

Build ulang binary native dilakukan di Linux x86_64 dengan Rust stable dan Android NDK:

```sh
rustup target add aarch64-linux-android
ANDROID_NDK_HOME=/path/to/android-ndk-r27c \
ANDROID_API_LEVEL=24 \
./scripts/build-android-termux.sh
```

## Status dan diagnosis awal

- Full-stack proot menjalankan source Linux ARM64 di Debian, bukan native Android APK. Node native addons tidak dijalankan langsung di bionic Termux.
- Setup dan cross-build berhasil divalidasi di Sandbox Linux; belum ada verifikasi langsung pada perangkat Android. Termux Android dapat menghentikan proses saat aplikasi masuk latar belakang, jadi pertahankan Termux di foreground.
- Mulai dengan CPU (`ONNX_THREADS=2`, `PIPELINE_PAGE_CONCURRENCY=1`) dan halaman uji kecil. Pantau suhu serta penggunaan RAM.
- Jika UI tidak terbuka, pastikan startup menampilkan port `8125`; akses `127.0.0.1` dan periksa apakah port sedang dipakai. Jika model gagal dimuat, cek log dan pastikan `bash scripts/fetch-models.sh` selesai tanpa error.
- Setelah UI terbuka, uji koneksi NaraRouter dari Settings sebelum mulai menerjemahkan. OCR/inpainting tetap bergantung pada model lokal meskipun LLM memakai layanan cloud.
