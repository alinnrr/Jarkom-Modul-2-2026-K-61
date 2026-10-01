#!/bin/bash
# ==============================================================================
# Modul 13: Konfigurasi Redirection Domain & IP Berbasis Aturan Akses
# Nodes: abbey (302 Redirect) & penny (301 Redirect)
# ==============================================================================

HOSTNAME=$(hostname)

echo "=================================================="
echo " Starting Configuration Task 13 on Node: $HOSTNAME"
echo "=================================================="

# ------------------------------------------------------------------------------
# 1. SETUP NODE ABBEY (302 Temporary Redirect ke static.K61.com)
# ------------------------------------------------------------------------------
if [ "$HOSTNAME" = "abbey" ]; then
    echo "[+] Configuring Nginx 302 Temporary Redirect on node: abbey..."

    # Pastikan dependensi terinstal
    apt-get update -y && apt-get install -y nginx curl

    # Update resolusi domain /etc/hosts dengan K besar
    grep -q "abbey.K61.com" /etc/hosts || echo "10.94.3.2    abbey.K61.com" >> /etc/hosts
    grep -q "static.K61.com" /etc/hosts || echo "10.94.3.2   static.K61.com" >> /etc/hosts

    # Konfigurasi Nginx Server Block
    cat << 'EOF' > /etc/nginx/sites-available/default
upstream core_backend {
    server 10.94.5.6:80; # oblada
    server 10.94.5.7:80; # molly
}

# Blok Redirect 302 untuk abbey.K61.com & IP ke static.K61.com
server {
    listen 80;
    server_name abbey.K61.com 10.94.3.2;
    return 302 http://static.K61.com$request_uri;
}

# Blok Utama / Core Tier untuk core.K61.com dan www.K61.com
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name core.K61.com www.K61.com;
    root /var/www/html;
    index index.html index.htm;

    location / {
        proxy_pass http://core_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
EOF

    # Uji konfigurasi dan restart Nginx
    nginx -t && service nginx restart

    echo "=== HASIL TEST CURL LOCAL (ABBEY) ==="
    curl -I http://abbey.K61.com/

# ------------------------------------------------------------------------------
# 2. SETUP NODE PENNY (301 Permanent Redirect ke www.K61.com)
# ------------------------------------------------------------------------------
elif [ "$HOSTNAME" = "penny" ]; then
    echo "[+] Configuring Nginx 301 Permanent Redirect on node: penny..."

    # Pastikan dependensi terinstal
    apt-get update -y && apt-get install -y nginx curl

    # Update resolusi domain /etc/hosts dengan K besar
    grep -q "penny.K61.com" /etc/hosts || echo "10.94.4.2    penny.K61.com" >> /etc/hosts
    grep -q "www.K61.com" /etc/hosts || echo "10.94.4.2    www.K61.com" >> /etc/hosts

    # Hentikan Apache jika sebelumnya berjalan
    service apache2 stop 2>/dev/null || true

    # Konfigurasi Nginx Server Block
    cat << 'EOF' > /etc/nginx/sites-available/default
server {
    listen 80;
    server_name penny.K61.com 10.94.4.2;
    return 301 http://www.K61.com$request_uri;
}
EOF

    # Uji konfigurasi dan restart Nginx
    nginx -t && service nginx restart

    echo "=== HASIL TEST CURL LOCAL (PENNY) ==="
    curl -I http://penny.K61.com/

# ------------------------------------------------------------------------------
# 3. VERIFIKASI DARI NODE KLIEN / LUAR
# ------------------------------------------------------------------------------
else
    echo "[*] Running verification tests for Task 13 from $HOSTNAME..."

    # Tambahkan entri host jika belum ada
    grep -q "abbey.K61.com" /etc/hosts || echo "10.94.3.2    abbey.K61.com" >> /etc/hosts
    grep -q "penny.K61.com" /etc/hosts || echo "10.94.4.2    penny.K61.com" >> /etc/hosts

    echo ""
    echo "=== [1] Testing Abbey 302 Temporary Redirect ==="
    curl -I http://abbey.K61.com/

    echo ""
    echo "=== [2] Testing Penny 301 Permanent Redirect ==="
    curl -I http://penny.K61.com/
    echo ""
fi