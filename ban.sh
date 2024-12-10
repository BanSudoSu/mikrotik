#!/bin/bash

# ASCII art untuk "Ban"
echo -e "\033[1;32m======================================="
echo "  ____              "
echo " |  _ \             "
echo " | |_) | __ _ _ __  "
echo " |  _ < / _\` | '_ \ "
echo " | |_) | (_| | | | |"
echo " |____/ \__,_|_| |_|"
echo "                    "
echo "=======================================\033[0m"

# Variabel untuk progres
PROGRES=("Menambahkan Repository Ban" "Melakukan update paket" "Mengonfigurasi netplan" "Menginstal DHCP server" \
         "Mengonfigurasi DHCP server" "Mengaktifkan IP Forwarding" "Mengonfigurasi Masquerade" \
         "Menginstal iptables-persistent" "Menyimpan konfigurasi iptables"  \
         "Menginstal Expect" "Konfigurasi Cisco" "Konfigurasi Mikrotik")

# Warna untuk output
GREEN='\033[1;32m'
NC='\033[0m'

# Fungsi untuk pesan sukses dan gagal
success_message() { echo -e "${GREEN}$1 berhasil!${NC}"; }
error_message() { echo -e "\033[1;31m$1 gagal!${NC}"; exit 1; }

# Otomasi Dimulai
echo "Otomasi Dimulai"

# Menambahkan Repository Ban
echo -e "${GREEN}${PROGRES[0]}${NC}"
REPO="http://kartolo.sby.datautama.net.id/ubuntu/"                                 
if ! grep -q "$REPO" /etc/apt/sources.list; then
    cat <<EOF | sudo tee /etc/apt/sources.list > /dev/null
deb ${REPO} focal main restricted universe multiverse
deb ${REPO} focal-updates main restricted universe multiverse
deb ${REPO} focal-security main restricted universe multiverse
deb ${REPO} focal-backports main restricted universe multiverse
deb ${REPO} focal-proposed main restricted universe multiverse
EOF
fi

# Update Paket
echo -e "${GREEN}${PROGRES[1]}${NC}"
sudo apt update -y > /dev/null 2>&1 || error_message "${PROGRES[1]}"

# Konfigurasi Netplan
echo -e "${GREEN}${PROGRES[2]}${NC}"
cat <<EOT | sudo tee /etc/netplan/01-netcfg.yaml > /dev/null
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: yes
    eth1:
      dhcp4: no
  vlans:
    eth1.10:
      id: 10
      link: eth1
      addresses:
        - 192.168.20.1/24
EOT
sudo netplan apply > /dev/null 2>&1 || error_message "${PROGRES[2]}"

# Instalasi ISC DHCP Server
echo -e "${GREEN}${PROGRES[3]}${NC}"
sudo apt install -y isc-dhcp-server > /dev/null 2>&1 || error_message "${PROGRES[3]}"

# Konfigurasi DHCP Server
echo -e "${GREEN}${PROGRES[4]}${NC}"
sudo bash -c 'cat > /etc/dhcp/dhcpd.conf' << EOF > /dev/null
subnet 192.168.20.0 netmask 255.255.255.0 {
  range 192.168.20.2 192.168.20.254;
  option domain-name-servers 8.8.8.8;
  option subnet-mask 255.255.255.0;
  option routers 192.168.20.1;
  option broadcast-address 192.168.20.255;
  default-lease-time 600;
  max-lease-time 7200;

  host Ban {
    hardware ethernet 00:50:79:66:68:0f;  
    fixed-address 192.168.20.10;
  }
}
EOF
echo 'INTERFACESv4="eth1.10"' | sudo tee /etc/default/isc-dhcp-server > /dev/null
sudo systemctl restart isc-dhcp-server > /dev/null 2>&1 || error_message "${PROGRES[4]}"

# Aktifkan IP Forwarding
echo -e "${GREEN}${PROGRES[5]}${NC}"
sudo sed -i '/^#net.ipv4.ip_forward=1/s/^#//' /etc/sysctl.conf
sudo sysctl -p > /dev/null 2>&1 || error_message "${PROGRES[5]}"

# Konfigurasi Masquerade dengan iptables
echo -e "${GREEN}${PROGRES[6]}${NC}"
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE > /dev/null 2>&1 || error_message "${PROGRES[6]}"

# Instalasi iptables-persistent dengan otomatisasi
echo -e "${GREEN}${PROGRES[7]}${NC}"
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections > /dev/null 2>&1
echo iptables-persistent iptables-persistent/autosave_v6 boolean false | sudo debconf-set-selections > /dev/null 2>&1
sudo apt install -y iptables-persistent > /dev/null 2>&1 || error_message "${PROGRES[7]}"

# Menyimpan Konfigurasi iptables
echo -e "${GREEN}${PROGRES[8]}${NC}"
sudo sh -c "iptables-save > /etc/iptables/rules.v4" > /dev/null 2>&1 || error_message "${PROGRES[8]}"
sudo sh -c "ip6tables-save > /etc/iptables/rules.v6" > /dev/null 2>&1 || error_message "${PROGRES[8]}"

# Instalasi Expect
echo -e "${GREEN}${PROGRES[9]}${NC}"
if ! command -v expect > /dev/null; then
    sudo apt install -y expect > /dev/null 2>&1 || error_message "${PROGRES[9]}"
    success_message "${PROGRES[9]}"
else
    success_message "${PROGRES[9]} sudah terinstal"
fi

# Konfigurasi Cisco
echo -e "${GREEN}${PROGRES[10]}${NC}"
CISCO_IP="192.168.234.132"
CISCO_PORT="30013"
expect <<EOF > /dev/null 2>&1
spawn telnet $CISCO_IP $CISCO_PORT
set timeout 20

expect ">" { send "enable\r" }
expect "#" { send "configure terminal\r" }
expect "(config)#" { send "interface FastEthernet0/1\r" }
expect "(config-if)#" { send "switchport mode access\r" }
expect "(config-if)#" { send "switchport access vlan 10\r" }
expect "(config-if)#" { send "no shutdown\r" }
expect "(config-if)#" { send "exit\r" }
expect "(config)#" { send "interface FastEthernet0/0\r" }
expect "(config-if)#" { send "switchport mode trunk\r" }
expect "(config-if)#" { send "switchport trunk encapsulation dot1q\r" }
expect "(config-if)#" { send "no shutdown\r" }
expect "(config-if)#" { send "exit\r" }
expect "(config)#" { send "exit\r" }
expect "#" { send "exit\r" }
expect eof
EOF

# Konfigurasi MikroTik
echo -e "${GREEN}${PROGRES[11]}${NC}"
MIKROTIK_IP="192.168.234.132"
MIKROTIK_PORT="30016"
MIKROTIK_USER="admin"
MIKROTIK_PASSWORD=""
MIKROTIK_NEWS="12345"
expect <<EOF
spawn telnet $MIKROTIK_IP $MIKROTIK_PORT
expect "Login:" { send "$MIKROTIK_USER\r" }
expect "Password:" { send "$MIKROTIK_PASSWORD\r" }
expect {
    "New password:" {
        send "$MIKROTIK_NEWS\r"
        expect "Retype new password:"
        send "$MIKROTIK_NEWS\r"
    }
    ">" {}
}
expect ">" { send "/interface ethernet set [find default-name=ether1] name=eth1\r" }
expect ">" { send "/interface ethernet set [find default-name=ether2] name=eth2\r" }
expect ">" { send "/ip address add address=192.168.20.3/24 interface=eth1 comment=\"Ke VLAN\"\r" }
expect ">" { send "/ip address add address=192.168.200.1/24 interface=eth2 comment=\"Jaringan Lokal\"\r" }
expect ">" { send "/ip dhcp-client add interface=eth1 disabled=no comment=\"DHCP ke ISP\"\r" }
expect ">" { send "/ip firewall nat add chain=srcnat out-interface=ether1 action=masquerade\r" }
expect ">" { send "/ip route add dst-address=192.168.200.0/24 gateway=192.168.20.1\r" }
expect ">" { send "/ip pool add name=dhcp_pool ranges=192.168.200.2-192.168.200.254\r" }
expect ">" { send "/ip dhcp-server add name=dhcp1 interface=eth2 address-pool=dhcp_pool disabled=no\r" }
expect ">" { send "/ip dhcp-server network add address=192.168.200.0/24 gateway=192.168.200.1 dns-server=8.8.8.8,8.8.4.4\r" }
expect ">" { send "quit\r" }
EOF
[ $? -eq 0 ] && success_message "${PROGRES[11]}" || error_message "${PROGRES[11]}"
