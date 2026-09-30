#!/bin/sh

echo "=== Konfigurasi Resolver NAT Internet Non-Router (Soal 3) ==="

# 1. Tuliskan DNS Server Lokal (Master & Slave) + Resolver NAT Internet 192.168.122.1
cat << 'EOF' > /etc/resolv.conf
nameserver 10.94.5.2
nameserver 10.94.5.3
nameserver 192.168.122.1
EOF

# 2. Tambahkan otomatisasi isi resolv.conf agar tidak tertimpa saat reboot
if ! grep -q "192.168.122.1" ~/.profile 2>/dev/null; then
    echo 'echo "nameserver 10.94.5.2" > /etc/resolv.conf' >> ~/.profile
    echo 'echo "nameserver 10.94.5.3" >> /etc/resolv.conf' >> ~/.profile
    echo 'echo "nameserver 192.168.122.1" >> /etc/resolv.conf' >> ~/.profile
fi

echo "Isi /etc/resolv.conf saat ini:"
cat /etc/resolv.conf

echo "=== Selesai! Resolver 192.168.122.1 Berhasil Ditambahkan ==="
