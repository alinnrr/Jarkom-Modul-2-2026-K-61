#!/bin/bash

echo "=== Konfigurasi Web Server & Autoindex (Soal 9) ==="

# 0. Hentikan Apache jika running agar port 80 bebas
service apache2 stop 2>/dev/null
pkill -9 apache2 2>/dev/null

# 1. Pastikan Nginx terinstal
if ! dpkg -l | grep -q nginx; then
    echo "Menginstal Nginx..."
    apt-get update
    apt-get install nginx -y
else
    echo "Nginx sudah terinstal."
fi

# 2. Buat direktori /arsip/ dan isi file dummy untuk autoindex
echo "Membuat direktori /arsip/ dan file contoh..."
mkdir -p /arsip
echo "Dokumen Rahasia 1" > /arsip/dokumen1.txt
echo "Laporan Penting Jarkom" > /arsip/laporan2.pdf
chmod -R 755 /arsip

# 3. Buat konfigurasi Nginx dengan autoindex on
echo "Menulis konfigurasi Nginx..."
cat << 'EOF' > /etc/nginx/sites-available/default
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name vault.K61.com;

    root /var/www/html;
    index index.html index.htm;

    location /arsip/ {
        alias /arsip/;
        autoindex on;
        autoindex_exact_size off;
        autoindex_localtime on;
    }
}
EOF

# 4. Tes konfigurasi dan restart Nginx
echo "Menjalankan Nginx..."
nginx -t
service nginx restart

echo "=== Soal 9 di Node Obladi Selesai & Berhasil! ==="
