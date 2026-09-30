#!/bin/bash

echo "=== Mengupdate Master DNS K61.com (Soal 5) ==="

# 1. Update Forward Zone (Menambahkan semua node & pengecualian ns1/ns2)
cat << 'EOF' > /etc/bind/jarkom/K61.com
$TTL    604800
@       IN      SOA     K61.com. root.K61.com. (
                        2026092902 ; Serial
                        604800     ; Refresh
                        86400      ; Retry
                        2419200    ; Expire
                        604800 )   ; Negative Cache TTL
;
; Pengecualian prab & tedd menjadi Name Server (ns1 & ns2)
@       IN      NS      ns1.K61.com.
@       IN      NS      ns2.K61.com.
@       IN      A       10.94.4.2
www     IN      CNAME   K61.com.

ns1     IN      A       10.94.5.2
ns2     IN      A       10.94.5.3

; Pemetaan Semua Entitas/Node Lainnya
rootkit IN      A       10.94.1.1
alpha   IN      A       10.94.1.2
beta    IN      A       10.94.1.3
gamma   IN      A       10.94.1.4
delta   IN      A       10.94.2.2
epsilon IN      A       10.94.2.3
abbey   IN      A       10.94.3.2
penny   IN      A       10.94.4.2
obladi  IN      A       10.94.5.4
desmond IN      A       10.94.5.5
oblada  IN      A       10.94.5.6
molly   IN      A       10.94.5.7

; Alias tambahan untuk sub-area
vault   IN      A       10.94.5.4
vault   IN      A       10.94.5.5
core    IN      A       10.94.5.6
core    IN      A       10.94.5.7
EOF

# 2. Update Reverse Zone menyesuaikan ns1 dan ns2
cat << 'EOF' > /etc/bind/jarkom/5.94.10.in-addr.arpa
$TTL    604800
@       IN      SOA     K61.com. root.K61.com. (
                        2026092902 ; Serial
                        604800     ; Refresh
                        86400      ; Retry
                        2419200    ; Expire
                        604800 )   ; Negative Cache TTL
;
@       IN      NS      ns1.K61.com.
@       IN      NS      ns2.K61.com.
2       IN      PTR     ns1.K61.com.
3       IN      PTR     ns2.K61.com.
4       IN      PTR     obladi.K61.com.
5       IN      PTR     desmond.K61.com.
6       IN      PTR     oblada.K61.com.
7       IN      PTR     molly.K61.com.
EOF

# 3. Restart Layanan
service named restart

echo "=== Soal 5 Selesai! Semua node telah terdaftar. ==="
