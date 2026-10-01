#!/bin/bash
# ==============================================================================
# Modul 16: Verifikasi Gateway dan Stress Testing Nginx Menggunakan ApacheBench
# Nodes: Rootkit (10.94.1.1 - Gateway/Nginx) & Alpha (Client / Stress Tester)
# ==============================================================================

HOSTNAME=$(hostname)

echo "=================================================="
echo " Starting Configuration Task 16 on Node: $HOSTNAME"
echo "=================================================="

# ------------------------------------------------------------------------------
# 1. SETUP NODE GATEWAY (rootkit)
# ------------------------------------------------------------------------------
if [ "$HOSTNAME" = "rootkit" ]; then
    echo "[+] Configuring Nginx Virtual Hosts on Gateway node: rootkit..."

    # Update paket dan instal Nginx serta ApacheBench
    apt-get update -y && apt-get install -y nginx apache2-utils curl

    # Buat direktori web dasar jika belum ada
    mkdir -p /var/www/html

    if [ ! -f /var/www/html/index.html ]; then
        echo "<h1>Welcome to K61 Network Gateway (Rootkit)</h1>" > /var/www/html/index.html
    fi

    # Buat file konfigurasi server block Nginx
    # Mendukung variasi kapital (www.K61.com) dan huruf kecil (www.k61.com)
    cat << 'EOF' > /etc/nginx/conf.d/k61.conf
server {
    listen 80;
    server_name www.K61.com www.k61.com;

    location / {
        root /var/www/html;
        index index.html index.htm;
    }
}

server {
    listen 80;
    server_name static.K61.com static.k61.com;

    location / {
        root /var/www/html;
        index index.html index.htm;
    }
}
EOF

    echo "[+] Configuration file /etc/nginx/conf.d/k61.conf successfully created."

    # Uji sintaks dan reload / jalankan Nginx
    nginx -t && (nginx -s reload 2>/dev/null || nginx 2>/dev/null || service nginx restart)

    echo ""
    echo "=== VERIFIKASI LOKAL ROOTKIT ==="
    curl -I http://localhost/

# ------------------------------------------------------------------------------
# 2. SETUP DAN TESTING DARI NODE CLIENT (Alpha / client)
# ------------------------------------------------------------------------------
else
    echo "[+] Running Stress Test with ApacheBench from node: $HOSTNAME..."

    # Pastikan dependensi ApacheBench (ab) terinstal
    if ! command -v ab &> /dev/null; then
        echo "[+] Installing apache2-utils (ApacheBench)..."
        apt-get update -y && apt-get install -y apache2-utils curl
    fi

    # Pemetaan resolusi domain /etc/hosts ke IP Gateway (10.94.1.1) dengan K besar
    grep -q "www.K61.com" /etc/hosts || echo "10.94.1.1 www.K61.com static.K61.com" >> /etc/hosts

    echo ""
    echo "=================================================="
    echo " [1] Stress Testing: http://www.K61.com/"
    echo "=================================================="
    ab -n 250 -c 10 -k http://www.K61.com/

    echo ""
    echo "=================================================="
    echo " [2] Stress Testing: http://static.K61.com/"
    echo "=================================================="
    ab -n 250 -c 10 -k http://static.K61.com/
fi