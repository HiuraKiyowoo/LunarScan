# Menjalankan Lunar di Ubuntu VPS

Panduan ini memasang Lunar langsung di Ubuntu—tanpa Termux atau `proot-distro`. Installer membangun backend Rust dan UI SvelteKit production di VPS, lalu mengunduh model ONNX untuk deteksi, OCR, dan inpainting lokal. Penerjemahan LLM tetap bisa memakai layanan cloud seperti NaraRouter.

## Kebutuhan

Gunakan Ubuntu 22.04/24.04 LTS pada VPS `x86_64` atau `aarch64` (ARM64). Disarankan minimal **4 vCPU, RAM 8 GB, dan 20 GB ruang disk kosong**. Inferensi OCR/deteksi/inpainting berjalan di CPU; satu halaman/concurrency 1 menjadi setelan awal yang lebih ramah RAM. Build Rust pertama kali bisa memakan waktu beberapa menit dan memakai ruang tambahan untuk cache Cargo/Node.

Installer harus dijalankan oleh user biasa yang memiliki `sudo`, bukan sebagai `root`. Simpan checkout repo di folder home yang path-nya tidak mengandung spasi. Butuh koneksi internet saat mengunduh paket, dependency, dan sekitar **403 MB model ONNX**.

## Instalasi dan jalankan

```bash
sudo apt update
sudo apt install -y git

git clone https://github.com/HiuraKiyowoo/LunarScan.git "$HOME/LunarScan"
cd "$HOME/LunarScan"
bash scripts/install-ubuntu.sh
```

Installer memasang paket build Ubuntu, Rust stable, Node.js sesuai `.nvmrc` (saat ini 24.18.1), Yarn, dependency UI, model, kemudian membangun UI production dan binary CPU. Build Cargo dibatasi 2 job secara default agar penggunaan RAM lebih terkendali. Jika VPS lebih besar, jumlahnya bisa diubah, misalnya:

```bash
CARGO_BUILD_JOBS=4 bash scripts/install-ubuntu.sh
```

Untuk uji coba foreground:

```bash
bash scripts/start-ubuntu.sh
```

Aplikasi production tersedia di `http://127.0.0.1:8124`. Tekan `Ctrl+C` untuk menghentikannya.

## Menjalankan otomatis dengan systemd

Dari direktori repo, jalankan helper sebagai user biasa lewat `sudo`:

```bash
sudo bash scripts/install-ubuntu-service.sh
sudo systemctl status lunar
sudo journalctl -u lunar -f
```

Service berjalan sebagai user pemilik repo dan otomatis dimulai saat boot. Perintah menaruh binary dan Node production di systemd, menggunakan CPU, `ONNX_THREADS=2`, serta concurrency halaman 1. Untuk menghentikan atau menjalankan ulang service:

```bash
sudo systemctl stop lunar
sudo systemctl restart lunar
```

Default Lunar hanya listen di `127.0.0.1:8124`; API ML ada di `127.0.0.1:8123`. Jangan membuka kedua port itu di firewall publik. Untuk mengetahui access token pada akun service:

```bash
sudo -u "$USER" -H "$HOME/LunarScan/target/release/xianscan" --print-token
```

Gunakan token saat pertama kali membuka Lunar dari browser/perangkat lain.

## Akses dari perangkat sendiri dengan SSH tunnel

Jika tidak perlu URL publik, pertahankan bind localhost dan buka tunnel dari komputer/ponsel yang memiliki SSH:

```bash
ssh -L 8124:127.0.0.1:8124 USER_VPS@IP_VPS
```

Selama sesi SSH itu aktif, buka `http://127.0.0.1:8124` pada perangkat yang menjalankan tunnel. Port aplikasi tidak perlu diekspos ke internet.

## Akses memakai domain dan HTTPS

Untuk akses publik, gunakan domain dan reverse proxy TLS (contohnya Nginx + Certbot). Jangan jalankan Lunar dengan `--lan` hanya untuk membuatnya dapat diakses melalui Nginx; reverse proxy pada VPS yang sama dapat menghubungi bind localhost. Buka hanya SSH dan port 80/443 pada firewall VPS dan firewall provider.

Contoh konfigurasi Nginx untuk domain `lunar.example.com`:

```nginx
server {
    listen 80;
    server_name lunar.example.com;

    client_max_body_size 64M;

    location / {
        proxy_pass http://127.0.0.1:8124;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_read_timeout 3600;
    }
}
```

Pasang Nginx dan Certbot terlebih dahulu, lalu simpan contoh konfigurasi di atas sebagai `/etc/nginx/sites-available/lunarscan` setelah mengganti domain. Aktifkan site, tes konfigurasi, lalu terbitkan HTTPS:

```bash
sudo apt install -y nginx certbot python3-certbot-nginx
sudo ln -s /etc/nginx/sites-available/lunarscan /etc/nginx/sites-enabled/lunarscan
sudo nginx -t
sudo systemctl reload nginx
sudo certbot --nginx -d lunar.example.com
```

Pastikan DNS domain sudah menunjuk ke IP VPS. Sesuaikan firewall provider/UFW dengan kondisi VPS; jangan mengunci diri sendiri dengan menyalakan UFW sebelum memastikan aturan SSH. HTTPS penting karena sesi aplikasi dan access token melewati browser.

## NaraRouter dan penyimpanan

Untuk penerjemahan melalui NaraRouter, di UI pilih **Settings → AI Translation Providers → Custom (OpenAI-Compatible)**, lalu gunakan Base URL `https://router.bynara.id/v1`, API key milikmu, dan model alias yang tersedia di akun. Jangan menaruh token di file repo atau unit systemd.

Data buku, halaman, database, dan access token disimpan terpisah dari repo pada `~/.local/share/xianscan/data` (atau lokasi di bawah `$XDG_DATA_HOME` jika environment itu disetel). Backup folder data tersebut secara berkala. Download ulang repo/rebuild tidak menggantikan backup data.

## Update atau hapus service

Dari direktori repo:

```bash
git pull
bash scripts/install-ubuntu.sh
sudo systemctl restart lunar
```

Menghapus service saja (data aplikasi tidak ikut dihapus):

```bash
sudo systemctl disable --now lunar
sudo rm /etc/systemd/system/lunar.service
sudo systemctl daemon-reload
```

## Batasan

Panduan ini menguji jalur build web/Rust production pada Linux x86_64, bukan mengonfigurasi GPU. ARM64 diterima installer, tetapi kompatibilitas runtime ONNX dan paket native UI bergantung pada ketersediaan artifact upstream untuk VPS tersebut. Untuk pemakaian pertama, uji satu halaman komik dan pantau RAM sebelum menaikkan jumlah worker/concurrency.
