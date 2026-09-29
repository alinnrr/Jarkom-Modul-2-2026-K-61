# JARKOM MODUL 1 2026 - K61

## Member

| Nama               | NRP        |
| ------------------ | ---------- |
| Ferlin Erdina Sari | 5027251002 |
| Achmad Rifqy Aqila | 5027251102 |

## Laporan

1. Sebagai pusat kesadaran The Mesh, rootkit harus merentangkan koneksinya ke lima gerbang utama (Switch). Tetapkan alamat IP dan default gateway untuk seluruh Entitas, mulai dari para operator (alpha, beta, gamma), penjaga directory (prab, tedd), gerbang penyaring (abbey, penny), hingga repository (obladi, desmond, oblada, molly) sesuai dengan topologi pembagian switch yang dirancang.

![Topologi Jaringan GNS3](assets/Topologi.png)

Pada tahap ini dibuatlah topologi jaringan GNS3 yang menghubungkan Router Utama **`rootkit`** ke lima switch internal dan sebuah NAT1 untuk koneksi WAN (Internet). Pembagian subnet dan gateway pada topologi ini ditentukan sebagai berikut:

- **Subnet 1 (`10.94.1.0/24`)**: Switch 1 menuju para Operator (`alpha`, `beta`, `gamma`) dengan Gateway `10.94.1.1`.
- **Subnet 2 (`10.94.2.0/24`)**: Switch 2 menuju Klien Tambahan (`delta`, `epsilon`) dengan Gateway `10.94.2.1`.
- **Subnet 3 (`10.94.3.0/24`)**: Switch 3 menuju Gerbang Penyaring / Client (`abbey`) dengan Gateway `10.94.3.1`.
- **Subnet 4 (`10.94.4.0/24`)**: Switch 4 menuju Gerbang Penyaring / Client (`penny`) dengan Gateway `10.94.4.1`.
- **Subnet 5 (`10.94.5.0/24`)**: Switch 5 menuju Penjaga Directory (`prab`, `tedd`) dan Repository (`obladi`, `desmond`, `oblada`, `molly`) dengan Gateway `10.94.5.1`.

---

### Konfigurasi IP & Gateway Seluruh Host Non-Router

Konfigurasi IP Static dan Gateway diterapkan langsung pada berkas `/etc/network/interfaces` di masing-masing node host agar bersifat persisten. Selain itu, dibuatkan skrip otomatisasi `soal1.sh` yang secara dinamis mengenali _hostname_ node untuk mempermudah pemulihan konfigurasi (_recovery_):

#### Kode Skrip Otomatisasi (`soal1.sh`):

````bash
#!/bin/bash

# Deteksi Hostname
NODE_NAME=$(hostname)

echo "=== Konfigurasi Network Soal 1 untuk Node: $NODE_NAME ==="

# Tentukan IP dan Gateway berdasarkan Hostname Node
case "$NODE_NAME" in
    alpha)
        IP="10.94.1.2"
        GW="10.94.1.1"
        ;;
    beta)
        IP="10.94.1.3"
        GW="10.94.1.1"
        ;;
    gamma)
        IP="10.94.1.4"
        GW="10.94.1.1"
        ;;
    abbey)
        IP="10.94.3.2"
        GW="10.94.3.1"
        ;;
    penny)
        IP="10.94.4.2"
        GW="10.94.4.1"
        ;;
    delta)
        IP="10.94.2.2"
        GW="10.94.2.1"
        ;;
    epsilon)
        IP="10.94.2.3"
        GW="10.94.2.1"
        ;;
    prab)
        IP="10.94.5.2"
        GW="10.94.5.1"
        ;;
    tedd)
        IP="10.94.5.3"
        GW="10.94.5.1"
        ;;
    obladi)
        IP="10.94.5.4"
        GW="10.94.5.1"
        ;;
    desmond)
        IP="10.94.5.5"
        GW="10.94.5.1"
        ;;
    oblada)
        IP="10.94.5.6"
        GW="10.94.5.1"
        ;;
    molly)
        IP="10.94.5.7"
        GW="10.94.5.1"
        ;;
    *)
        echo "Error: Hostname '$NODE_NAME' tidak dikenali!"
        exit 1
        ;;
esac

# Detect OS (Debian vs Alpine)
if [ -f /etc/debian_version ]; then
    # --- Konfigurasi untuk Debian/Ubuntu ---
    cat << EOF > /etc/network/interfaces
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address $IP
    netmask 255.255.255.0
    gateway $GW
    dns-nameservers 10.94.5.2 10.94.5.3 192.168.122.1
EOF
    service networking restart 2>/dev/null || ifreload -a 2>/dev/null

elif [ -f /etc/alpine-release ]; then
    # --- Konfigurasi untuk Alpine Linux ---
    cat << EOF > /etc/network/interfaces
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address $IP
    netmask 255.255.255.0
    gateway $GW
EOF
    rc-service networking restart 2>/dev/null
fi

# Terapkan IP secara langsung ke Interface eth0
ip addr flush dev eth0 2>/dev/null
ip addr add $IP/24 dev eth0 2>/dev/null
ip route add default via $GW dev eth0 2>/dev/null

# Set DNS Resolver ke Master, Slave DNS, dan Resolver Internet
echo "nameserver 10.94.5.2" > /etc/resolv.conf
echo "nameserver 10.94.5.3" >> /etc/resolv.conf
echo "nameserver 192.168.122.1" >> /etc/resolv.conf

echo "=== Selesai! IP $IP/24 & GW $GW berhasil dipasang pada $NODE_NAME ==="
```bash
````
