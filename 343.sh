#!/usr/bin/expect

# Mulai sesi telnet ke MikroTik
spawn telnet 192.168.234.132 30016
set timeout 10

# Login otomatis
expect "Mikrotik Login: " { send "admin\r" }
expect "Password: " { send "\r" }

# Tangani prompt lisensi atau permintaan password baru
expect {
    -re "Do you want to see the software license.*" { send "n\r" }
    "new password>" { send "123\r" }
    "repeat new password>" { send "123\r" }
}

# Tangani login sukses atau error pada password
expect {
    "Try again, error: New passwords do not match!" {
        puts "Error: Password tidak cocok. Gagal login."
        exit 1
    }
    ">" {
        puts "Login berhasil dan konfigurasi dimulai."
    }
}

# Menambahkan IP Address pada interface ether2
expect ">" { send "/ip address add address=192.168.200.1/24 interface=ether2\r" }

# Konfigurasi DHCP Server
expect ">" { send "/ip pool add name=dhcp_pool ranges=192.168.200.10-192.168.200.100\r" }
expect ">" { send "/ip dhcp-server add name=dhcp1 interface=ether2 address-pool=dhcp_pool disabled=no\r" }
expect ">" { send "/ip dhcp-server network add address=192.168.200.0/24 gateway=192.168.200.1 dns-server=8.8.8.8\r" }

# Menambahkan Default Route untuk akses internet
expect ">" { send "/ip route add dst-address=192.168.200.0/24 gateway=192.168.20.1\r" }

# Menambahkan NAT Masquerade untuk mengakses internet
expect ">" { send "/ip firewall nat add chain=srcnat out-interface=ether1 action=masquerade\r" }

# Keluar dari MikroTik
expect ">" { send "/quit\r" }
expect eof
