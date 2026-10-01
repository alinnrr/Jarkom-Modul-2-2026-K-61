#!/bin/bash
# ==============================================================================
# Modul 19: CNAME Record & Forwarders ke Domain Eksternal http.badssl.com
# Nodes: prab (Master - 10.94.5.2), tedd (Slave - 10.94.5.3), alpha (Client)
# ==============================================================================

HOSTNAME=$(hostname)
IP_PRAB="10.94.5.2"
IP_TEDD="10.94.5.3"

echo "=================================================="
echo " Starting Configuration Task 19 on Node: $HOSTNAME"
echo "=================================================="

# ------------------------------------------------------------------------------
# 1. SETUP DNS MASTER (prab - 10.94.5.2)
# ------------------------------------------------------------------------------
if [ "$HOSTNAME" = "prab" ]; then
    echo "[+] 1. Mengonfigurasi DNS Forwarders di /etc/bind/named.conf.options..."
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

    echo "[+] 2. Memperbarui Zona /etc/bind/db.K61.com (Menambahkan CNAME ke http.badssl.com.)..."
    cat << 'EOF' > /etc/bind/db.K61.com
$TTL    15
@       IN      SOA     ns1.K61.com. root.K61.com. (
                            2026100104         ; Serial Dinaikkan
                            3600               ; Refresh
                            1800               ; Retry
                            604800             ; Expire
                            15 )               ; Negative Cache TTL

@       IN      NS      ns1.K61.com.
ns1     IN      A       10.94.5.2

; --- Record A Task 18 ---
abbey   15      IN      A       192.0.2.123

; --- Record CNAME Task 19 (Sesuai Soal: outbound.K61.com -> http.badssl.com.) ---
outbound IN     CNAME   http.badssl.com.
EOF

    echo "[+] 3. Reloading BIND9 Master..."
    pkill -9 named 2>/dev/null || true
    /usr/sbin/named -u bind
    rndc reload K61.com 2>/dev/null || true

    echo ""
    echo "=== VERIFIKASI CNAME LOKAL MASTER (prab) ==="
    dig outbound.K61.com @127.0.0.1 CNAME +short
    echo "[+] Selesai! BIND9 Master prab siap melayani CNAME & Forwarding."

# ------------------------------------------------------------------------------
# 2. SETUP DNS SLAVE (tedd - 10.94.5.3)
# ------------------------------------------------------------------------------
elif [ "$HOSTNAME" = "tedd" ]; then
    echo "[+] Retransfer Zone K61.com pada Slave tedd..."
    pkill -9 named 2>/dev/null || true
    /usr/sbin/named -u bind
    rm -f /var/cache/bind/db.K61.com
    rndc retransfer K61.com 2>/dev/null || rndc reload 2>/dev/null || true
    sleep 2

    echo ""
    echo "=== VERIFIKASI CNAME LOKAL SLAVE (tedd) ==="
    dig outbound.K61.com @127.0.0.1 CNAME +short
    echo "[+] Selesai! Zone slave di tedd berhasil diperbarui."

# ------------------------------------------------------------------------------
# 3. UJI COBA DARI NODE CLIENT (alpha)
# ------------------------------------------------------------------------------
else
    which dig >/dev/null 2>&1 || (apt-get update -y && apt-get install -y dnsutils curl) 2>/dev/null || true

    echo ""
    echo "=========================================="
    echo " UJI COBA TASK 19: CNAME & CURL BINDING"
    echo "=========================================="
    
    echo "[*] 1. Query CNAME Record (dig CNAME +short):"
    dig outbound.K61.com @$IP_TEDD CNAME +short

    echo ""
    echo "[*] 2. Query Resolusi IP Domain Eksternal (dig +short):"
    dig outbound.K61.com @$IP_TEDD +short

    echo ""
    echo "[*] 3. Uji Akses Konten HTTP (curl ke http://outbound.K61.com):"
    # Menyertakan Header Host agar web badssl.com mau merespon halaman aslinya
    curl -s -L -H "Host: http.badssl.com" http://outbound.K61.com | head -n 25 || curl -I http://outbound.K61.com
fi