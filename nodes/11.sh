#!/bin/bash
# ==============================================================================
# Modul 11: Automated Multi-Tier Load Balancing & Reverse Proxy Setup
# Nodes: Abbey (Core Tier), Penny (Vault Tier), & Alpine Backends
# ==============================================================================

HOSTNAME=$(hostname)

echo "=================================================="
echo " Starting Configuration on Node: $HOSTNAME"
echo "=================================================="

# ------------------------------------------------------------------------------
# 1. SETUP CORE TIER: ABBEY (Nginx Load Balancer)
# ------------------------------------------------------------------------------
if [ "$HOSTNAME" = "abbey" ]; then
    echo "[+] Configuring Core Tier on node: abbey..."
    apt-get update -y && apt-get install -y nginx curl
    
    # Resolusi Host (Domain K61.com dengan K Besar)
    grep -q "abbey.K61.com" /etc/hosts || echo "10.94.3.2   abbey.K61.com" >> /etc/hosts
    grep -q "penny.K61.com" /etc/hosts || echo "10.94.4.2   penny.K61.com" >> /etc/hosts

    # Konfigurasi Load Balancing Nginx ke Backend Core Tier (oblada & molly)
    cat << 'EOF' > /etc/nginx/sites-available/default
upstream core_backend {
    server 10.94.5.6:80; # oblada
    server 10.94.5.7:80; # molly
}

server {
    listen 80;
    server_name abbey.K61.com;

    location / {
        proxy_pass http://core_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
EOF

    systemctl restart nginx
    systemctl enable nginx
    echo "[+] Node abbey ready!"

# ------------------------------------------------------------------------------
# 2. SETUP VAULT TIER: PENNY (Apache Reverse Proxy & Load Balancer)
# ------------------------------------------------------------------------------
elif [ "$HOSTNAME" = "penny" ]; then
    echo "[+] Configuring Vault Tier on node: penny..."
    apt-get update -y && apt-get install -y apache2 curl

    # Aktifkan Modul Proxy Apache
    a2enmod proxy proxy_http proxy_balancer lbmethod_byrequests

    # Resolusi Host (Domain K61.com dengan K Besar)
    grep -q "abbey.K61.com" /etc/hosts || echo "10.94.3.2   abbey.K61.com" >> /etc/hosts
    grep -q "penny.K61.com" /etc/hosts || echo "10.94.4.2   penny.K61.com" >> /etc/hosts

    # Konfigurasi Load Balancing Apache ke Backend Vault Tier (obladi & desmond)
    cat << 'EOF' > /etc/apache2/sites-available/000-default.conf
<VirtualHost *:80>
    ServerName penny.K61.com

    <Proxy balancer://vaultcluster>
        BalancerMember http://10.94.5.4:80
        BalancerMember http://10.94.5.5:80
        ProxySet lbmethod=byrequests
    </Proxy>

    ProxyPreserveHost On
    ProxyPass / balancer://vaultcluster/
    ProxyPassReverse / balancer://vaultcluster/
</VirtualHost>
EOF

    systemctl restart apache2
    systemctl enable apache2
    echo "[+] Node penny ready!"

# ------------------------------------------------------------------------------
# 3. SETUP BACKEND CORE TIER: OBLADA (Alpine / Nginx)
# ------------------------------------------------------------------------------
elif [ "$HOSTNAME" = "oblada" ]; then
    echo "[+] Configuring Backend Node: oblada..."
    apk update && apk add nginx

    mkdir -p /var/www/html
    echo "<h1>Response from Node: oblada</h1>" > /var/www/html/index.html

    cat << 'EOF' > /etc/nginx/http.d/default.conf
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    root /var/www/html;
    index index.html;
    location / {
        try_files $uri $uri/ =404;
    }
}
EOF

    nginx -s reload || (pkill nginx && nginx)
    echo "[+] Node oblada ready!"

# ------------------------------------------------------------------------------
# 4. SETUP BACKEND CORE TIER: MOLLY (Alpine / Nginx)
# ------------------------------------------------------------------------------
elif [ "$HOSTNAME" = "molly" ]; then
    echo "[+] Configuring Backend Node: molly..."
    apk update && apk add nginx

    mkdir -p /var/www/html
    echo "<h1>Response from Node: molly</h1>" > /var/www/html/index.html

    cat << 'EOF' > /etc/nginx/http.d/default.conf
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    root /var/www/html;
    index index.html;
    location / {
        try_files $uri $uri/ =404;
    }
}
EOF

    nginx -s reload || (pkill nginx && nginx)
    echo "[+] Node molly ready!"

# ------------------------------------------------------------------------------
# 5. SETUP BACKEND VAULT TIER: OBLADI (Alpine / Nginx)
# ------------------------------------------------------------------------------
elif [ "$HOSTNAME" = "obladi" ]; then
    echo "[+] Configuring Backend Node: obladi..."
    apk update && apk add nginx

    mkdir -p /var/www/html
    echo "<h1>Response from Node: obladi</h1>" > /var/www/html/index.html

    cat << 'EOF' > /etc/nginx/http.d/default.conf
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    root /var/www/html;
    index index.html;
    location / {
        try_files $uri $uri/ =404;
    }
}
EOF

    nginx -s reload || (pkill nginx && nginx)
    echo "[+] Node obladi ready!"

# ------------------------------------------------------------------------------
# 6. SETUP BACKEND VAULT TIER: DESMOND (Alpine / Nginx)
# ------------------------------------------------------------------------------
elif [ "$HOSTNAME" = "desmond" ]; then
    echo "[+] Configuring Backend Node: desmond..."
    apk update && apk add nginx

    mkdir -p /var/www/html
    echo "<h1>Response from Node: desmond</h1>" > /var/www/html/index.html

    cat << 'EOF' > /etc/nginx/http.d/default.conf
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    root /var/www/html;
    index index.html;
    location / {
        try_files $uri $uri/ =404;
    }
}
EOF

    nginx -s reload || (pkill nginx && nginx)
    echo "[+] Node desmond ready!"

else
    echo "[!] Error: Hostname '$HOSTNAME' tidak dikenali!"
    echo "Pastikan hostname pada node diset sesuai (abbey, penny, oblada, molly, obladi, desmond)."
fi