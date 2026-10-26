# LunarScan — port eksperimental XianScan untuk Android ARM64

Port komunitas untuk menjalankan [XianScan](https://github.com/ArbenApura/xianscan-rust) di Android. Repo ini tidak resmi dan tidak dikelola oleh upstream.
Nama repo GitHub: **LunarScan**. Brand UI aplikasi: **Lunar**. Proyek ini berbasis XianScan oleh Arben Apura; credit dan lisensi upstream dipertahankan di repo ini.

## Instalasi full app: sekali setup, lalu jalankan

Cara yang direkomendasikan memakai **Termux + Debian `proot-distro`**. Installer menyiapkan UI web, backend Rust, dependency Node, dan model ONNX. Setup dilakukan satu kali; setelah itu cukup jalankan launcher untuk membuka studio web lokal.

Di aplikasi Termux:

```sh
pkg update -y
pkg install -y git proot-distro
git clone https://github.com/HiuraKiyowoo/LunarScan.git "$HOME/xianscan-termux"
cd "$HOME/xianscan-termux"
bash scripts/install-termux.sh
```

Installer memasang Debian proot, toolchain Rust dan Node, dependency UI, lalu mengunduh 7 model ONNX (total sekitar **403 MB**) dan membangun backend. UI Vite dijalankan oleh launcher. Perlu koneksi internet yang stabil, beberapa GB ruang kosong, dan waktu build yang bergantung pada kecepatan HP; biarkan Termux tetap terbuka selama proses.

Setelah selesai, jalankan di Termux:

```sh
bash "$HOME/xianscan-termux/scripts/start-termux.sh"
```

Buka **http://127.0.0.1:8125** di browser Android. Untuk berhenti, tekan `Ctrl+C` di Termux. Jalankan dari direktori privat Termux, bukan `/sdcard`.

## Instalasi Ubuntu VPS

Lunar juga bisa dibangun langsung di Ubuntu VPS tanpa `proot-distro`. Jalur ini membangun UI production dan backend CPU, mengunduh model ONNX, serta menyediakan service `systemd` agar otomatis hidup kembali setelah reboot. Disarankan Ubuntu 22.04/24.04 LTS, 4 vCPU, RAM 8 GB, dan 20 GB ruang kosong. Gunakan user biasa dengan akses `sudo`.

```bash
sudo apt update && sudo apt install -y git
git clone https://github.com/HiuraKiyowoo/LunarScan.git "$HOME/LunarScan"
cd "$HOME/LunarScan"
bash scripts/install-ubuntu.sh
sudo bash scripts/install-ubuntu-service.sh
```

Service bind ke localhost secara default. Akses privat lewat SSH tunnel atau gunakan reverse proxy HTTPS untuk domain; jangan buka port aplikasi `8124` maupun API ML `8123` langsung ke internet. Ikuti [panduan Ubuntu VPS](docs/ubuntu-vps.md) untuk akses remote, systemd, token, update, dan NaraRouter.

## Pakai NaraRouter untuk penerjemahan

**Tidak perlu mengunduh LLM penerjemah lokal.** Lunar dapat mengirim permintaan penerjemahan ke layanan cloud seperti NaraRouter. Model ONNX tetap diunduh untuk tugas gambar lokal seperti deteksi balon/teks, OCR, dan inpainting; total model pada manifest saat ini sekitar 403 MB.

Di UI Lunar, buka **Settings → AI Translation Providers**, pilih **Custom (OpenAI-Compatible)**, lalu masukkan:

- **Base URL:** `https://router.bynara.id/v1`
- **API key:** token API NaraRouter milikmu
- **Model:** pilih/scan alias model yang tersedia untuk akunmu

Tekan **Test Connection**, lalu pilih provider tersebut untuk terjemahan. [Dokumentasi API NaraRouter](https://router.bynara.id/docs). Jangan kirim API key di chat atau commit ke repo.

## Pilihan backend native saja (tanpa UI)

Untuk yang ingin mencoba backend Rust Android ARM64 tanpa Debian proot, paket ada di [`dist/termux-arm64/`](dist/termux-arm64/). Paket ini **tidak termasuk UI web atau Node**; gunakan launcher `run-ml.sh` dan siapkan folder model. Lihat [panduan Termux lengkap](docs/termux-proot.md) untuk batasan dan tes.

## Build paket Android ARM64 sendiri

Cross-build backend native dilakukan di Linux x86_64 dengan Rust stable dan Android NDK:

```sh
rustup target add aarch64-linux-android
ANDROID_NDK_HOME=/path/to/android-ndk-r27c \
ANDROID_API_LEVEL=24 \
./scripts/build-android-termux.sh
```

## Status port dan batasan

- Backend Rust berhasil di-cross-build dan di-link menjadi ELF Android ARM64. Paket native itu belum diuji langsung di HP.
- Full UI dengan brand Lunar dijalankan di Debian ARM64 dalam `proot-distro`, bukan sebagai Android APK. Setup memasang dependency UI dan membangun backend Rust; launcher menjalankan SvelteKit/Vite.
- Inferensi OCR/deteksi/inpainting berjalan di CPU pada konfigurasi awal; Android GPU/NNAPI belum diaktifkan.
- Runtime di perangkat fisik—termasuk pemuatan model, OCR, inpainting, suhu, RAM, dan lifecycle Termux—belum diverifikasi. Mulai dengan satu halaman uji dan pantau suhu/RAM.
- Model ONNX punya lisensi masing-masing dan tidak otomatis tercakup oleh lisensi MIT source.

## Kredit dan lisensi

Source dasar berasal dari [XianScan upstream](https://github.com/ArbenApura/xianscan-rust) oleh Arben Apura. Perubahan port Termux ini bersifat eksperimental. Lisensi source mengikuti [MIT](LICENSE); lisensi model, font, dan aset pihak ketiga mengikuti ketentuan masing-masing.
