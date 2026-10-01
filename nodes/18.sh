#!/bin/bash

# ==============================================================================
# KONFIGURASI IP NODE (SESUAI TOPOLOGI)
# ==============================================================================
IP_PRAB="10.94.5.2"   # Master
IP_TEDD="10.94.5.3"   # Slave

HOSTNAME=$(hostname)

echo "=================================================="
echo " Starting Configuration Task 18 on Node: $HOSTNAME"
echo "=================================================="

# ------------------------------------------------------------------------------
# 1. KONFIGURASI NODE MASTER (prab - 10.94.5.2)
# ------------------------------------------------------------------------------
if [ "$HOSTNAME" = "prab" ]; then
    echo "[+] Konfigurasi Zone Master K61.com pada node prab..."

    cat << 'EOF' > /etc/bind/named.conf.local
zone "K61.com" {
    type master;
    file "/etc/bind/db.K61.com";
    allow-transfer { 10.94.5.3; };
    notify yes;
};
EOF

    cat << 'EOF' > /etc/bind/db.K61.com
$TTL    1D
@       IN      SOA     ns1.K61.com. root.K61.com. (
                              2026100103         ; Serial
                              3600               ; Refresh
                              1800               ; Retry
                              604800             ; Expire
                              86400 )            ; Negative Cache TTL

@       IN      NS      ns1.K61.com.
ns1     IN      A       10.94.5.2

; Record A abbey dengan TTL khusus 15 detik ke IP Fiktif
abbey   15      IN      A       192.0.2.123
EOF

    pkill -9 named 2>/dev/null
    /usr/sbin/named -u bind
    rndc reload K61.com 2>/dev/null || true

    echo "[+] Selesai! Zone master di prab berhasil diperbarui."

# ------------------------------------------------------------------------------
# 2. KONFIGURASI NODE SLAVE (tedd - 10.94.5.3)
# ------------------------------------------------------------------------------
elif [ "$HOSTNAME" = "tedd" ]; then
    echo "[+] Konfigurasi Zone Slave K61.com pada node tedd..."

    cat << 'EOF' > /etc/bind/named.conf.local
zone "K61.com" {
    type slave;
    masters { 10.94.5.2; };
    file "/var/cache/bind/db.K61.com";
};
EOF

    pkill -9 named 2>/dev/null
    /usr/sbin/named -u bind
    rm -f /var/cache/bind/db.K61.com
    rndc retransfer K61.com 2>/dev/null || rndc reload 2>/dev/null || true

    echo "[+] Selesai! Zone slave di tedd berhasil disinkronkan."

# ------------------------------------------------------------------------------
# 3. VERIFIKASI PENGUJI DARI NODE CLIENT (alpha)
# ------------------------------------------------------------------------------
else
    which dig >/dev/null 2>&1 || (apt-get update -y && apt-get install -y dnsutils) 2>/dev/null || true

    echo ""
    echo "=========================================================="
    echo " FASE 1: Sebelum Perubahan / Kueri Awal"
    echo "=========================================================="
    dig abbey.K61.com @$IP_TEDD +noall +answer

    echo ""
    echo "=========================================================="
    echo " FASE 2: Momen Jeda Cache (< 15 Detik)"
    echo "=========================================================="
    echo "Kueri Ke-1 (Menangkap cache baru):"
    dig abbey.K61.com @$IP_TEDD +noall +answer
    
    echo ""
    echo "Kueri Ke-2 (Selang 3 detik - Perhatikan TTL 15s aktif):"
    sleep 3
    dig abbey.K61.com @$IP_TEDD +noall +answer

    echo ""
    echo "=========================================================="
    echo " FASE 3: Setelah Batas Waktu TTL Expired (> 15 Detik)"
    echo "=========================================================="
    echo "Menunggu 13 detik lagi agar total waktu > 15 detik..."
    sleep 13

    echo ""
    echo "Hasil query setelah cache expired (TTL ter-reset ke 15):"
    dig abbey.K61.com @$IP_TEDD +noall +answer
fi