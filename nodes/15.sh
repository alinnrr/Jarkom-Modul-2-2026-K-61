#!/bin/bash
# ==============================================================================
# Modul 15: Konfigurasi Path-Based Routing dengan PHP dan File Statis
# Nodes: Abbey (/orion - Static), Penny (/eternal - PHP 8.4-FPM), Client Node
# ==============================================================================

HOSTNAME=$(hostname)

echo "=================================================="
echo " Starting Configuration Task 15 on Node: $HOSTNAME"
echo "=================================================="

# ------------------------------------------------------------------------------
# 1. SETUP NODE ABBEY (Path-Based Routing Statis: /orion)
# ------------------------------------------------------------------------------
if [ "$HOSTNAME" = "abbey" ]; then
    echo "[+] Configuring Static Path /orion on node: abbey..."

    # 1. Perbarui repositori Debian Trixie & Instalasi Nginx
    echo "deb http://deb.debian.org/debian trixie main" > /etc/apt/sources.list
    echo "deb http://deb.debian.org/debian-security trixie-security main" >> /etc/apt/sources.list
    rm -f /etc/apt/sources.list.d/*.sources /etc/apt/sources.list.d/*.list 2>/dev/null || true
    apt-get update -y && apt-get install -y nginx curl

    # Update resolusi domain /etc/hosts dengan K besar
    grep -q "abbey.K61.com" /etc/hosts || echo "10.94.3.2    abbey.K61.com" >> /etc/hosts

    # 2. Buat direktori fisik dan konten statis
    mkdir -p /var/www/orion
    echo '<h1>Halo dari Abbey - Path Orion Statis Berhasil!</h1>' > /var/www/orion/index.html

    # 3. Buat struktur direktori Nginx
    mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled

    # 4. Buat konfigurasi Nginx server block
    cat << 'EOF' > /etc/nginx/sites-available/default
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index index.html index.htm;
    server_name abbey.K61.com _;

    location /orion {
        alias /var/www/orion;
        index index.html index.htm;
        try_files $uri $uri/ =404;
    }
}
EOF

    # 5. Aktifkan symlink, jalankan Nginx, dan uji
    ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
    nginx -t && (nginx -s reload 2>/dev/null || nginx 2>/dev/null || service nginx restart)

    echo ""
    echo "=== HASIL TEST CURL ABBEY (PATH /orion) ==="
    curl http://localhost/orion/index.html && echo ""

# ------------------------------------------------------------------------------
# 2. SETUP NODE PENNY (Path-Based Routing PHP 8.4-FPM: /eternal)
# ------------------------------------------------------------------------------
elif [ "$HOSTNAME" = "penny" ]; then
    echo "[+] Configuring PHP 8.4-FPM Path /eternal on node: penny..."

    # Pastikan dependensi terinstal
    apt-get update -y && apt-get install -y nginx php8.4-fpm curl 2>/dev/null || apt-get install -y nginx php-fpm curl

    # Update resolusi domain /etc/hosts dengan K besar
    grep -q "penny.K61.com" /etc/hosts || echo "10.94.4.2    penny.K61.com" >> /etc/hosts

    # 1. Hentikan Apache jika berjalan untuk menghindari konflik port
    service apache2 stop 2>/dev/null || true

    # 2. Buat direktori fisik dan file PHP
    mkdir -p /var/www/eternal
    echo '<?php echo "Halo dari Penny - Path Eternal PHP Berhasil!\n"; ?>' > /var/www/eternal/index.php

    # 3. Buat struktur direktori Nginx
    mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled

    # 4. Buat konfigurasi Nginx server block dengan FastCGI PHP-FPM
    cat << 'EOF' > /etc/nginx/sites-available/default
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index index.html index.htm;
    server_name penny.K61.com _;

    location /eternal {
        alias /var/www/eternal;
        index index.php index.html index.htm;
        try_files $uri $uri/ =404;

        location ~ \.php$ {
            include fastcgi_params;
            fastcgi_pass unix:/run/php/php8.4-fpm.sock;
            fastcgi_param SCRIPT_FILENAME $request_filename;
        }
    }
}
EOF

    # 5. Aktifkan symlink, jalankan service PHP-FPM & Nginx, lalu uji
    ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
    
    # Jalankan PHP-FPM 8.4 jika belum aktif
    php-fpm8.4 2>/dev/null || service php8.4-fpm start 2>/dev/null || true

    # Jalankan / Reload Nginx
    nginx -t && (nginx -s reload 2>/dev/null || nginx 2>/dev/null || service nginx restart)

    echo ""
    echo "=== HASIL TEST CURL PENNY (PATH /eternal) ==="
    curl http://localhost/eternal/index.php

# ------------------------------------------------------------------------------
# 3. VERIFIKASI DARI NODE KLIEN / LUAR
# ------------------------------------------------------------------------------
else
    echo "[*] Running verification test for Task 15 from $HOSTNAME..."

    # Update resolusi host domain K61.com pada client
    grep -q "abbey.K61.com" /etc/hosts || echo "10.94.3.2    abbey.K61.com" >> /etc/hosts
    grep -q "penny.K61.com" /etc/hosts || echo "10.94.4.2    penny.K61.com" >> /etc/hosts

    echo ""
    echo "=== [1] Testing Remote Static Request (Abbey - /orion) ==="
    curl http://abbey.K61.com/orion/index.html && echo ""

    echo ""
    echo "=== [2] Testing Remote PHP Execution Request (Penny - /eternal) ==="
    curl http://penny.K61.com/eternal/index.php
    echo ""
fi