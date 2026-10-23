# XianScan Termux — port eksperimental Android ARM64

**Fork/port komunitas untuk menjalankan backend penerjemah komik XianScan di Termux.** Proyek ini berasal dari [ArbenApura/xianscan-rust](https://github.com/ArbenApura/xianscan-rust), yang dibuat oleh Arben Apura. Repo ini tidak resmi dan bukan proyek yang dikelola upstream.

> **Status saat ini:** backend Rust berhasil di-cross-build dan di-link untuk Android ARM64 menggunakan Android NDK. Paket native menjalankan **ML/API backend saja**. UI web dan proses Node belum menjadi bagian dari paket Android native. Eksekusi binary, model AI, dan inferensi tetap harus diuji langsung di HP Termux.

XianScan memproses halaman manga, manhwa, dan manhua melalui deteksi teks, OCR, penerjemahan LLM, inpainting, dan typesetting. Port native Termux ini berfokus dahulu pada server Rust dan inferensi CPU.

## Pilih cara menjalankan

- **Backend native Termux (Android ARM64):** gunakan paket `dist/termux-arm64/` atau build sendiri. Tersedia endpoint backend lokal di port `8123`; **tidak ada UI web**.
- **Aplikasi dengan UI web:** gunakan Debian melalui `proot-distro` dan ikuti [Panduan Android/Termux](docs/termux-proot.md). Ini jalur eksperimental Linux ARM64 di userspace Debian, bukan binary Android native.

Jangan gunakan rilis Linux `x86_64` upstream pada ponsel Android `ARM64`.

## Instalasi backend native di Termux

Paket prebuilt ARM64 tersedia pada folder [`dist/termux-arm64/`](dist/termux-arm64/). Untuk memasangnya di perangkat:

1. Clone repo ini di Termux. Repo sudah menyertakan paket prebuilt di `dist/termux-arm64/`:

   ```sh
   pkg update -y
   pkg install git bash curl coreutils -y
   git clone https://github.com/HiuraKiyowoo/xianscan-termux.git "$HOME/xianscan-termux"
   cp -a "$HOME/xianscan-termux/dist/termux-arm64" "$HOME/xianscan-backend"
   ```

   Jalankan dari **direktori privat Termux**, bukan `/sdcard`; filesystem berbagi Android dapat memblokir eksekusi.

2. Unduh bobot model di Termux:

   ```sh
   cd "$HOME/xianscan-termux"
   bash scripts/fetch-models.sh
   ```

3. Jalankan backend dengan folder model tersebut:

   ```sh
   cd "$HOME/xianscan-backend"
   chmod +x xianscan run-ml.sh
   MODELS_DIR="$HOME/xianscan-source/models" ./run-ml.sh
   ```

Launcher memakai CPU, membatasi ONNX ke 2 thread dan memproses 1 halaman bersamaan sebagai nilai awal. Log startup akan menunjukkan apakah model tersedia dan berhasil dimuat. Backend ML-only seharusnya mendengarkan di `127.0.0.1:8123`; ia tidak menyajikan studio web.

Untuk pemrosesan gambar, model ONNX **wajib diunduh**. Model tidak disertakan dalam repo atau paket prebuilt. Ruang kosong beberapa GB mungkin dibutuhkan, bergantung bobot model, cache, dan halaman yang diproses.

## Build paket Android ARM64 sendiri

Build dilakukan pada host Linux x86_64 dengan Rust stable dan Android NDK. Contoh berikut menggunakan NDK r27c:

```sh
rustup target add aarch64-linux-android
ANDROID_NDK_HOME=/path/to/android-ndk-r27c \
ANDROID_API_LEVEL=24 \
./scripts/build-android-termux.sh
```

Hasil paket berada di `dist/termux-arm64/`. Skrip membangun backend Rust release untuk ARM64 Android dan menyalin `libc++_shared.so` yang diperlukan. API level minimum build bawaan adalah 24; perangkat dan versi Android yang sebenarnya tetap perlu diuji.

## Menjalankan UI web penuh lewat Debian proot

Untuk UI SvelteKit, API terjemahan, dan workflow penuh, ikuti [Panduan Android/Termux](docs/termux-proot.md). Jalur tersebut menggunakan Debian ARM64 di Termux:

```sh
pkg install proot-distro -y
proot-distro install debian
proot-distro login debian
```

Panduan menjelaskan toolchain, unduh model, instalasi dependency web, dan perintah menjalankan mode development di Debian. Dukungan native Android untuk Node dan addon web belum dinyatakan selesai.

## Model dan penyedia terjemahan

Deteksi, OCR, dan inpainting memakai model ONNX lokal. Unduh model yang terdaftar di `models/manifest.tsv` dengan `bash scripts/fetch-models.sh`. Model memiliki lisensi masing-masing dan tidak otomatis tercakup oleh lisensi MIT kode aplikasi.

Terjemahan memerlukan layanan LLM terpisah. XianScan mendukung endpoint OpenAI-compatible kustom. Contoh untuk NaraRouter:

- **Base URL:** `https://router.bynara.id/v1`
- **API key:** token API milik pengguna
- **Model:** alias model yang tersedia pada akun/router

Masukkan key di pengaturan provider XianScan; jangan commit atau publikasikan API key. Konfigurasi provider melalui UI memerlukan jalur yang menyertakan UI web, bukan paket backend native ML-only.

## Hasil pengujian dan batasan

- `cargo check --target aarch64-linux-android --no-default-features`: berhasil di Sandbox dengan Android NDK.
- `cargo build --target aarch64-linux-android --no-default-features --release`: berhasil; binary terdeteksi sebagai ELF Android ARM64 dengan interpreter `/system/bin/linker64`.
- `scripts/build-android-termux.sh`: berhasil menghasilkan paket backend native.
- Runtime di HP Android/Termux, load model, OCR, inpainting, suhu, RAM, dan lifecycle aplikasi Android **belum diuji di perangkat fisik**.
- Test di host Linux belum seluruhnya lulus: dua test GPU gagal pada lingkungan Sandbox dan satu API test analisis gambar gagal saat model tidak tersedia. Jalankan ulang setelah menyiapkan model dan gunakan perangkat target untuk tes akhir.
- Android GPU/NNAPI belum diaktifkan; gunakan CPU. Pertahankan Termux di foreground saat pemrosesan panjang.

## Kredit dan lisensi

Source dasar berasal dari [XianScan upstream](https://github.com/ArbenApura/xianscan-rust) oleh Arben Apura. Perubahan untuk port Termux dalam repo ini adalah eksperimen komunitas. Lisensi source mengikuti [MIT](LICENSE); lisensi model, font, dan aset pihak ketiga mengikuti ketentuan masing-masing.
