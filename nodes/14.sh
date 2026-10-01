#!/bin/bash
# ==============================================================================
# Modul 14: Implementasi Logging IP Klien Asli via Header X-Real-IP
# Nodes: Backend Nodes (molly, oblada, obladi, desmond) & Testing
# ==============================================================================

HOSTNAME=$(hostname)

echo "=================================================="
echo " Starting Configuration Task 14 on Node: $HOSTNAME"
echo "=================================================="

# ------------------------------------------------------------------------------
# 1. SETUP BACKEND NODES (molly, oblada, obladi, desmond)
# ------------------------------------------------------------------------------
if [ "$HOSTNAME" = "molly" ] || [ "$HOSTNAME" = "oblada" ] || [ "$HOSTNAME" = "obladi" ] || [ "$HOSTNAME" = "desmond" ]; then
    echo "[+] Configuring Nginx Custom Logging (proxy_combined) on backend node: $HOSTNAME..."

    # Pastikan Nginx terinstal
    if command -v apk &> /dev/null; then
        apk update && apk add nginx curl bash 2>/dev/null || true
    else
        apt-get update -y && apt-get install -y nginx curl 2>/dev/null || true
    fi

    # Update resolusi host K61.com jika dibutuhkan
    grep -q "abbey.K61.com" /etc/hosts || echo "10.94.3.2    abbey.K61.com" >> /etc/hosts
    grep -q "penny.K61.com" /etc/hosts || echo "10.94.4.2    penny.K61.com" >> /etc/hosts

    # 1. Tambahkan log_format proxy_combined ke dalam nginx.conf jika belum ada
    if ! grep -q "proxy_combined" /etc/nginx/nginx.conf; then
        # Sisipkan log_format proxy_combined di dalam blok http {
        sed -i '/http {/a \    log_format proxy_combined '\''$http_x_real_ip - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent"'\'';' /etc/nginx/nginx.conf
        echo "[+] Format log proxy_combined berhasil ditambahkan ke /etc/nginx/nginx.conf"
    else
        echo "[*] Format log proxy_combined sudah ada di /etc/nginx/nginx.conf"
    fi

    # 2. Buat direktori sites-available dan sites-enabled jika belum ada
    mkdir -p /etc/nginx/sites-available
    mkdir -p /etc/nginx/sites-enabled
    mkdir -p /var/www/html

    # Buat file index sederhana jika belum ada
    if [ ! -f /var/www/html/index.html ]; then
        echo "<h1>Response from Backend Node: $HOSTNAME (K61 Network)</h1>" > /var/www/html/index.html
    fi

    # 3. Buat file konfigurasi default dengan format log kustom proxy_combined
    cat << 'EOF' > /etc/nginx/sites-available/default
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;

    server_name _;

    access_log /var/log/nginx/access.log proxy_combined;
    error_log /var/log/nginx/error.log;

    location / {
        try_files $uri $uri/ =404;
    }
}
EOF
    echo "[+] File konfigurasi default berhasil dibuat."

    # 4. Pastikan symlink aktif
    ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

    # Jika struktur Nginx menggunakan /etc/nginx/http.d/ (di Alpine Linux)
    if [ -d /etc/nginx/http.d ]; then
        cp /etc/nginx/sites-available/default /etc/nginx/http.d/default.conf
    fi

    # 5. Uji konfigurasi dan restart Nginx
    nginx -t && (nginx -s reload 2>/dev/null || systemctl restart nginx 2>/dev/null || service nginx restart)
    echo "[+] Nginx berhasil diuji dan dijalankan/restart!"

    echo ""
    echo "=== VERIFIKASI LOKAL ($HOSTNAME) ==="
    curl -I http://localhost/
    echo ""
    echo "=== TAIL LOG AKSES DENGAN FORMAT PROXY_COMBINED ==="
    tail -n 5 /var/log/nginx/access.log

# ------------------------------------------------------------------------------
# 2. VERIFIKASI / TESTING DARI LUAR / CLIENT NODE
# ------------------------------------------------------------------------------
else
    echo "[*] Running verification test for Task 14 from $HOSTNAME..."

    # Tambahkan entri host domain K61.com
    grep -q "abbey.K61.com" /etc/hosts || echo "10.94.3.2    abbey.K61.com" >> /etc/hosts
    grep -q "penny.K61.com" /etc/hosts || echo "10.94.4.2    penny.K61.com" >> /etc/hosts

    echo ""
    echo "[1] Testing Request ke Core Tier Load Balancer (abbey.K61.com):"
    curl -I http://abbey.K61.com/

    echo ""
    echo "[2] Testing Request langsung dengan Header Simulated X-Real-IP:"
    curl -H "X-Real-IP: 202.158.10.50" -I http://10.94.5.6/ # IP oblada
    echo ""
fi