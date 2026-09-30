#!/bin/bash

echo "=== Konfigurasi Routing Internal & Network Interfaces Rootkit (Soal 3) ==="

# 1. Pasang IP Gateway untuk masing-masing Subnet Internal di Rootkit
# Sesuaikan nama interface (eth1, eth2, dst) sesuai slot kabel di GNS3 topologimu
ip addr add 10.94.1.1/24 dev eth1 2>/dev/null
ip addr add 10.94.2.1/24 dev eth2 2>/dev/null
ip addr add 10.94.3.1/24 dev eth3 2>/dev/null
ip addr add 10.94.4.1/24 dev eth4 2>/dev/null
ip addr add 10.94.5.1/24 dev eth5 2>/dev/null

# Nyalakan semua interface
ip link set eth1 up 2>/dev/null
ip link set eth2 up 2>/dev/null
ip link set eth3 up 2>/dev/null
ip link set eth4 up 2>/dev/null
ip link set eth5 up 2>/dev/null

# 2. Aktifkan IP Forwarding
echo "Mengaktifkan IP Forwarding..."
sysctl -w net.ipv4.ip_forward=1 > /dev/null

# 3. Set Resolver lokal Rootkit
echo "nameserver 192.168.122.1" > /etc/resolv.conf

echo "=== Selesai! Routing Internal Lintas Subnet via Rootkit Aktif ==="
