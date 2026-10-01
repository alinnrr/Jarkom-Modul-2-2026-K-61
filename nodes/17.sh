#!/bin/bash
# ==============================================================================
# Modul 17: Konfigurasi DNS Server BIND9 & TXT Records Klien Sayap Kiri/Kanan
# Nodes: Rootkit (10.94.1.1 - DNS Server) & Client Nodes (Alpha, Beta, dll.)
# ==============================================================================

HOSTNAME=$(hostname)

echo "=================================================="
echo " Starting Configuration Task 17 on Node: $HOSTNAME"
echo "=================================================="

# ------------------------------------------------------------------------------
# 1. SETUP NODE DNS SERVER (rootkit)
# ------------------------------------------------------------------------------
if [ "$HOSTNAME" = "rootkit" ]; then
    echo "[+] Configuring BIND9 DNS Server on Gateway node: rootkit..."

    # 1. Instalasi BIND9 dan paket pendukung
    apt-get update -y && apt-get install -y bind9 bind9utils dnsutils

    # 2. Tambahkan konfigurasi zone di /etc/bind/named.conf.local
    # Memastikan tidak ada duplikasi zone K61.com
    if ! grep -q 'zone "K61.com"' /etc/bind/named.conf.local; then
        cat << 'EOF' >> /etc/bind/named.conf.local

zone "K61.com" {
    type master;
    file "/etc/bind/db.K61.com";
};
EOF
    fi

    # 3. Buat File Zona /etc/bind/db.K61.com dengan TXT Record untuk seluruh klien
    cat << 'EOF' > /etc/bind/db.K61.com
$TTL    604800
@       IN      SOA     ns1.K61.com. root.K61.com. (
                              2026093001         ; Serial
                              604800         ; Refresh
                               86400         ; Retry
                             2419200         ; Expire
                              604800 )       ; Negative Cache TTL

@       IN      NS      ns1.K61.com.
ns1     IN      A       10.94.1.1

; --- TXT Records untuk Klien ---
alpha   IN      TXT     "alpha"
beta    IN      TXT     "beta"
gamma   IN      TXT     "gamma"
delta   IN      TXT     "delta"
epsilon IN      TXT     "epsilon"
EOF

    echo "[+] Zone file /etc/bind/db.K61.com successfully created."

    # 4. Validasi sintaks konfigurasi zona BIND9
    named-checkconf
    named-checkzone K61.com /etc/bind/db.K61.com

    # 5. Jalankan daemon BIND9 / named (fleksibel untuk non-systemd)
    pkill named 2>/dev/null || true
    named -g &
    sleep 2

    echo ""
    echo "=== VERIFIKASI QUERY DNS LOKAL ROOTKIT ==="
    dig TXT alpha.K61.com @10.94.1.1 +short
    dig TXT beta.K61.com @10.94.1.1 +short

# ------------------------------------------------------------------------------
# 2. TESTING DARI NODE CLIENT (Alpha / client lainnya)
# ------------------------------------------------------------------------------
else
    echo "[+] Running DNS TXT Query verification from node: $HOSTNAME..."

    # Pastikan utilitas 'dig' (dnsutils) terinstal
    if ! command -v dig &> /dev/null; then
        echo "[+] Installing dnsutils..."
        apt-get update -y && apt-get install -y dnsutils
    fi

    echo ""
    echo "=================================================="
    echo " [1] Testing DNS TXT Record Queries (@10.94.1.1)"
    echo "=================================================="
    
    for client in alpha beta gamma delta epsilon; do
        printf "Querying %-18s -> " "${client}.K61.com:"
        dig TXT "${client}.K61.com" @10.94.1.1 +short
    done
fi