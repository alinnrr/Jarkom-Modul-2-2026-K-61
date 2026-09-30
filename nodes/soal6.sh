#!/bin/bash

echo "=== Memulai Konfigurasi Slave DNS di tedd ==="

# 1. Update dan install BIND9
apt-get update
apt-get install bind9 -y

# 2. Buat folder dan atur izinnya terlebih dahulu
mkdir -p /etc/bind/jarkom
chown -R bind:bind /etc/bind/jarkom
chmod 755 /etc/bind/jarkom

# 3. Konfigurasi named.conf.local menggunakan printf (aman dari error spasi)
printf 'zone "K61.com" {\n    type slave;\n    masters { 10.94.5.2; };\n    file                                                                                                              "/etc/bind/jarkom/K61.com";\n};\n\nzone "5.94.10.in-addr.arpa" {\n    type slav                                                                                                             e;\n    masters { 10.94.5.2; };\n    file "/etc/bind/jarkom/5.94.10.in-addr.arpa                                                                                                             ";\n};\n' > /etc/bind/named.conf.local

# 4. Restart layanan named
service named restart

echo "=== Konfigurasi Slave DNS Selesai! ==="
