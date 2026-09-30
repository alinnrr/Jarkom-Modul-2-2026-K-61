#!/bin/bash

echo "=== Konfigurasi Reverse DNS Zone (Soal 8) ==="

ZONE_FILE="/etc/bind/jarkom/5.94.10.in-addr.arpa"
LOCAL_CONF="/etc/bind/named.conf.local"

# 1. Pastikan reverse zone terdaftar di named.conf.local
if ! grep -q "5.94.10.in-addr.arpa" "$LOCAL_CONF"; then
    cat << 'EOF' >> "$LOCAL_CONF"

zone "5.94.10.in-addr.arpa" {
    type master;
    file "/etc/bind/jarkom/5.94.10.in-addr.arpa";
    allow-transfer { 10.94.5.3; };
};
EOF
    echo "Deklarasi zona berhasil ditambahkan ke named.conf.local"
else
    echo "Deklarasi zona sudah ada di named.conf.local"
fi

# 2. Tulis file reverse zone menggunakan cat EOF (Bersih & aman dari error newline)
cat << 'EOF' > "$ZONE_FILE"
$TTL 86400
@   IN  SOA ns1.K61.com. root.K61.com. (
        2026092901 ; Serial
        600        ; Refresh
        180        ; Retry
        604800     ; Expire
        86400 )    ; Minimum TTL

@   IN  NS  ns1.K61.com.
@   IN  NS  ns2.K61.com.

2   IN  PTR ns1.K61.com.
3   IN  PTR ns2.K61.com.
4   IN  PTR vault.K61.com.
5   IN  PTR vault.K61.com.
6   IN  PTR core.K61.com.
7   IN  PTR core.K61.com.
10  IN  PTR abbey.K61.com.
11  IN  PTR penny.K61.com.

EOF

# 3. Restart layanan named di prab
service named restart

echo "=== Soal 8 di Master (prab) Selesai! ==="
