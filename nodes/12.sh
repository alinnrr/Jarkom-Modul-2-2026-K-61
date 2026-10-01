#!/bin/bash
# ==============================================================================
# Modul 12: Automated HTTP Basic Authentication Setup pada Path /admin
# Nodes: penny (Server Proxy/Nginx) & Client Node (Testing)
# ==============================================================================

HOSTNAME=$(hostname)

echo "=================================================="
echo " Starting Configuration Task 12 on Node: $HOSTNAME"
echo "=================================================="

# ------------------------------------------------------------------------------
# 1. SETUP SERVER: PENNY (Nginx Basic Auth)
# ------------------------------------------------------------------------------
if [ "$HOSTNAME" = "penny" ]; then
    echo "[+] Configuring HTTP Basic Auth on node: penny..."

    # Pastikan dependensi terinstal (apache2-utils menyediakan htpasswd)
    apt-get update -y && apt-get install -y nginx apache2-utils curl

    # Resolusi Host (Domain K61.com dengan K Besar)
    grep -q "penny.K61.com" /etc/hosts || echo "10.94.4.2   penny.K61.com" >> /etc/hosts

    # 1. Hentikan Apache jika berjalan untuk menghindari konflik port 80
    service apache2 stop 2>/dev/null || true

    # 2. Buat direktori dan file konten halaman admin
    mkdir -p /var/www/html/admin
    echo "<h1>Halaman Rahasia Admin Sindikat K61</h1>" > /var/www/html/admin/index.html
    chmod -R 755 /var/www/html/admin

    # 3. Buat file .htpasswd untuk kredensial user prabs
    htpasswd -b -c /etc/nginx/.htpasswd prabs "pakar_pinter_jadi_gob***"

    # 4. Update konfigurasi Nginx default site
    cat << 'EOF' > /etc/nginx/sites-available/default
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    root /var/www/html;
    index index.html index.htm;
    server_name penny.K61.com;

    location /admin {
        auth_basic "Area Rahasia Sindikat - K61";
        auth_basic_user_file /etc/nginx/.htpasswd;
        try_files $uri $uri/ =404;
    }

    location / {
        try_files $uri $uri/ =404;
    }
}
EOF

    # 5. Uji sintaks Nginx dan restart/start layanan
    nginx -t && service nginx restart

    echo "=== Setup Basic Auth pada Node Penny Selesai ==="

# ------------------------------------------------------------------------------
# 2. TESTING DARI KLIEN / NODE LAIN
# ------------------------------------------------------------------------------
else
    echo "[*] Running verification test for Task 12 from $HOSTNAME..."

    # Pastikan resolusi host ada pada client
    grep -q "penny.K61.com" /etc/hosts || echo "10.94.4.2   penny.K61.com" >> /etc/hosts

    echo ""
    echo "[1] Testing Unauthorized Access (Expected: HTTP/1.1 401 Unauthorized):"
    curl -I http://penny.K61.com/admin/

    echo ""
    echo "[2] Testing Authorized Access (Expected: HTTP/1.1 200 OK & Secret Page):"
    curl -u 'prabs:pakar_pinter_jadi_gob***' http://penny.K61.com/admin/
    echo ""
fi