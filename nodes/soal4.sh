#!/bin/bash

echo "=== Memulai Konfigurasi Master DNS K61.com ==="

# Update dan install BIND9
apt-get update
apt-get install bind9 -y

# 1. Konfigurasi zona lokal
echo "-> Membuat named.conf.local..."
cat << 'EOF' > /etc/bind/named.conf.local
zone "K61.com" {
    type master;
    file "/etc/bind/jarkom/K61.com";
};

zone "5.94.10.in-addr.arpa" {
    type master;
    file "/etc/bind/jarkom/5.94.10.in-addr.arpa";
};
EOF

# 2. Buat direktori jarkom
mkdir -p /etc/bind/jarkom

# 3. Konfigurasi Forward Zone
echo "-> Membuat file zona K61.com..."
cat << 'EOF' > /etc/bind/jarkom/K61.com
$TTL    604800
@       IN      SOA     K61.com. root.K61.com. (
                        2026092901 ; Serial
                        604800     ; Refresh
                        86400      ; Retry
                        2419200    ; Expire
                        604800 )   ; Negative Cache TTL
;
@       IN      NS      K61.com.
@       IN      A       10.94.4.2
www     IN      CNAME   K61.com.

prab    IN      A       10.94.5.2
tedd    IN      A       10.94.5.3
abbey   IN      A       10.94.3.2
penny   IN      A       10.94.4.2
obladi  IN      A       10.94.5.4
desmond IN      A       10.94.5.5
oblada  IN      A       10.94.5.6
molly   IN      A       10.94.5.7

vault   IN      A       10.94.5.4
vault   IN      A       10.94.5.5
core    IN      A       10.94.5.6
core    IN      A       10.94.5.7
EOF

# 4. Konfigurasi Reverse Zone
echo "-> Membuat file reverse 5.94.10.in-addr.arpa..."
cat << 'EOF' > /etc/bind/jarkom/5.94.10.in-addr.arpa
$TTL    604800
@       IN      SOA     K61.com. root.K61.com. (
                        2026092901 ; Serial
                        604800     ; Refresh
                        86400      ; Retry
                        2419200    ; Expire
                        604800 )   ; Negative Cache TTL
;
@       IN      NS      K61.com.
2       IN      PTR     prab.K61.com.
3       IN      PTR     tedd.K61.com.
4       IN      PTR     obladi.K61.com.
5       IN      PTR     desmond.K61.com.
6       IN      PTR     oblada.K61.com.
7       IN      PTR     molly.K61.com.
EOF

# 5. Restart DNS Server
echo "-> Merestart layanan named..."
service named restart

echo "=== Konfigurasi Master DNS Selesai! ==="
