#!/bin/bash
# ==============================================================================
# Modul 20: Normalisasi Konfigurasi, Stabilitas Layanan, dan Verifikasi Akhir DNS
# Nodes: prab (Master - 10.94.5.2), tedd (Slave - 10.94.5.3), alpha (Client)
# ==============================================================================

HOSTNAME=$(hostname)
IP_PRAB="10.94.5.2"
IP_TEDD="10.94.5.3"

echo "=================================================="
echo " Starting Configuration Task 20 on Node: $HOSTNAME"
echo "=================================================="

# ------------------------------------------------------------------------------
# 1. NORMALISASI NODE DNS MASTER (prab - 10.94.5.2)
# ------------------------------------------------------------------------------
if [ "$HOSTNAME" = "prab" ]; then
    echo "[+] 1. Memperbarui Zona /etc/bind/db.K61.com (Normalisasi TTL 86400, Serial 2026100105)..."
    cat << 'EOF' > /etc/bind/db.K61.com
$TTL    86400
@       IN      SOA     ns1.K61.com. root.K61.com. (
                            2026100105         ; Serial SOA Dinaikkan
                            3600               ; Refresh
                            1800               ; Retry
                            604800             ; Expire
                            86400 )            ; Negative Cache TTL Normal

@       IN      NS      ns1.K61.com.
ns1     IN      A       10.94.5.2

; --- Normalisasi Record A Abbey ---
abbey   IN      A       10.94.5.2

; --- CNAME Record Outbound Tetap Aktif ---
outbound IN     CNAME   http.badssl.com.
EOF

    echo "[+] 2. Memastikan DNS Forwarders Aktif di /etc/bind/named.conf.options..."
    cat << 'EOF' > /etc/bind/named.conf.options
options {
        directory "/var/cache/bind";

        forwarders {
                8.8.8.8;
                1.1.1.1;
        };

        dnssec-validation auto;
        allow-query { any; };
};
EOF

    echo "[+] 3. Memastikan BIND9 Berjalan Normal & Auto-Start..."
    pkill -9 named 2>/dev/null || true
    /usr/sbin/named -u bind
    rndc reload K61.com 2>/dev/null || true

    # Memasang daemon launcher di ~/.bashrc untuk mensimulasikan autostart saat container boot
    grep -q "named" ~/.bashrc || echo "pgrep named >/dev/null || /usr/sbin/named -u bind" >> ~/.bashrc

    echo "[+] 4. Status Layanan BIND9 Master:"
    if pgrep named > /dev/null; then
        echo "   [SUCCESS] BIND9 di prab berjalan stabil!"
    else
        echo "   [FAILED] BIND9 tidak terdeteksi."
    fi

    echo ""
    echo "=== VERIFIKASI NORMALISASI LOKAL MASTER ==="
    dig abbey.K61.com @127.0.0.1 +noall +answer

# ------------------------------------------------------------------------------
# 2. NORMALISASI NODE DNS SLAVE (tedd - 10.94.5.3)
# ------------------------------------------------------------------------------
elif [ "$HOSTNAME" = "tedd" ]; then
    echo "[+] 1. Memastikan BIND9 Slave Berjalan Normal & Retransfer..."
    pkill -9 named 2>/dev/null || true
    /usr/sbin/named -u bind
    rm -f /var/cache/bind/db.K61.com
    rndc retransfer K61.com 2>/dev/null || rndc reload 2>/dev/null || true
    sleep 2

    grep -q "named" ~/.bashrc || echo "pgrep named >/dev/null || /usr/sbin/named -u bind" >> ~/.bashrc

    echo "[+] 2. Status Layanan BIND9 Slave:"
    if pgrep named > /dev/null; then
        echo "   [SUCCESS] BIND9 di tedd berjalan stabil!"
    else
        echo "   [FAILED] BIND9 tidak terdeteksi."
    fi

    echo ""
    echo "=== VERIFIKASI NORMALISASI LOKAL SLAVE ==="
    dig abbey.K61.com @127.0.0.1 +noall +answer

# ------------------------------------------------------------------------------
# 3. VERIFIKASI AKHIR DARI NODE CLIENT (alpha)
# ------------------------------------------------------------------------------
else
    which dig >/dev/null 2>&1 || (apt-get update -y && apt-get install -y dnsutils curl) 2>/dev/null || true

    echo ""
    echo "=========================================================="
    echo " UJI COBA AKHIR TASK 20: NORMALISASI & STABILITAS DNS"
    echo "=========================================================="

    echo "[*] 1. Cek Normalisasi TTL 86400 pada Record A (abbey.K61.com):"
    dig abbey.K61.com @$IP_TEDD +noall +answer

    echo ""
    echo "[*] 2. Cek CNAME & Forwarding DNS (outbound.K61.com):"
    dig outbound.K61.com @$IP_TEDD +noall +answer

    echo ""
    echo "[*] 3. Uji Akses Layanan Web HTTP Akhir (curl ke http://outbound.K61.com):"
    curl -s -L -H "Host: http.badssl.com" http://outbound.K61.com | head -n 15 || curl -I http://outbound.K61.com
fi