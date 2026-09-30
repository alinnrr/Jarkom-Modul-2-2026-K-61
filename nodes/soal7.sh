#!/bin/bash

echo "=== Menambahkan A Record & CNAME (Soal 7) ==="

ZONE_FILE="/etc/bind/jarkom/K61.com"

# Cek apakah record 'vault' sudah ada di dalam file zona untuk mencegah duplikat
if ! grep -q "vault" "$ZONE_FILE"; then
    cat << 'EOF' >> "$ZONE_FILE"

vault   IN  A   10.94.5.4
vault   IN  A   10.94.5.5
core    IN  A   10.94.5.6
core    IN  A   10.94.5.7
www     IN  CNAME   penny.K61.com.
static  IN  CNAME   abbey.K61.com.
EOF
    echo "Record tambahan berhasil ditambahkan."
else
    echo "Record sudah ada sebelumnya, melewati penambahan baris."
fi

# 2. Otomatis menaikkan nomor serial SOA agar slave DNS mendeteksi perubahan
CURRENT_SERIAL=$(grep -oP '\d+(?=\s*;\s*Serial)' "$ZONE_FILE")
NEW_SERIAL=$((CURRENT_SERIAL + 1))
sed -i "s/$CURRENT_SERIAL/$NEW_SERIAL/g" "$ZONE_FILE"

echo "Nomor Serial SOA diperbarui dari $CURRENT_SERIAL menjadi $NEW_SERIAL"

# 3. Restart layanan named di prab
sed -i -e 's/\r$//' "$ZONE_FILE"
service named restart

echo "=== Soal 7 Selesai! ==="

