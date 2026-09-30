#!/bin/sh

echo "=== Konfigurasi Nginx + PHP-FPM + URL Rewrite (Soal 10 - Alpine) ==="

# 1. Update & Install Nginx serta PHP-FPM di Alpine
echo "Menginstal Nginx dan PHP-FPM..."
apk update
apk add nginx php83-fpm php83 || apk add nginx php82-fpm php82 || apk add nginx                                                                                                              php81-fpm php81 || apk add nginx php-fpm

# 2. Buat Direktori Web Root & File PHP
echo "Membuat file aplikasi PHP..."
mkdir -p /var/www/core
chmod -R 755 /var/www/core

# Halaman Beranda (index.php)
cat << 'EOF' > /var/www/core/index.php
<?php
echo "<h1>Selamat Datang di Beranda Node Core (K61.com)</h1>";
echo "<p>Layanan PHP-FPM & Nginx berjalan dengan sukses!</p>";
echo "<a href='/profil'>Ke Halaman Profil (Clean URL)</a>";
?>
EOF

# Halaman Profil (profil.php)
cat << 'EOF' > /var/www/core/profil.php
<?php
echo "<h1>Halaman Profil Node Core</h1>";
echo "<p>Ini adalah halaman profil yang diakses tanpa ekstensi .php!</p>";
echo "<a href='/'>Kembali ke Beranda</a>";
?>
EOF

# 3. Cari lokasi socket/port PHP-FPM
PHP_SOCK=$(ls /var/run/php*/php*-fpm.sock 2>/dev/null | head -n 1)
if [ -z "$PHP_SOCK" ]; then
    PHP_PASS="127.0.0.1:9000"
else
    PHP_PASS="unix:$PHP_SOCK"
fi

# 4. Buat Konfigurasi Nginx Utama
echo "Menulis konfigurasi Nginx..."
mkdir -p /etc/nginx/http.d

cat << EOF > /etc/nginx/http.d/default.conf
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name core.K61.com;
    root /var/www/core;
    index index.php index.html;

    # Aturan URL Rewrite (Clean URL)
    location / {
        try_files \$uri \$uri/ \$uri.php?\$args;
    }

    # Konfigurasi Pemrosesan PHP via PHP-FPM
    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass $PHP_PASS;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }
}
EOF

# 5. Jalankan Layanan PHP-FPM dan Nginx
echo "Menjalankan layanan PHP-FPM & Nginx..."

# Start PHP-FPM
pkill php-fpm 2>/dev/null
php-fpm83 2>/dev/null || php-fpm82 2>/dev/null || php-fpm81 2>/dev/null || php-f                                                                                                             pm 2>/dev/null

# Start Nginx
pkill nginx 2>/dev/null
nginx -t && nginx

echo "=== Soal 10 Selesai & Berhasil! ==="
