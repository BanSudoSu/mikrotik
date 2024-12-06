#!/usr/bin/expect

# Mulai sesi telnet ke MikroTik
spawn telnet 192.168.234.132 30016
set timeout 10

# Login otomatis
expect "Mikrotik Login: " { send "admin\r" }
expect "Password: " { send "\r" }

# Tangani prompt lisensi jika muncul
expect {
    -re "Do you want to see the software license.*" { send "n\r" }
    "new password>" { send "123\r" }
}

# Ubah password baru jika diminta
expect "new password>" { 
    send "123\r"
    expect "repeat new password>" { send "123\r" }
}

# Verifikasi apakah password berhasil diubah
expect {
    "Try again, error: New passwords do not match!" {
        puts "Error: Password tidak cocok. Gagal login."
        exit 1
    }
    ">" {
        puts "Login berhasil dan konfigurasi dimulai."
    }
}

# Menambahkan IP Address
expect ">" { send "/ip address add address=192.168.200.1/24 interface=ether2\r" }

# Menambahkan NAT Masquerade
expect ">" { send "/ip firewall nat add chain=srcnat out-interface=ether1 action=masquerade\r" }

# Menambahkan Route
expect ">" { send "/ip route add dst-address=192.168.200.0/24 gateway=192.168.20.1\r" }

# Menambahkan Firewall Rule (contoh tambahan)
expect ">" { send "/ip firewall filter add chain=input action=accept protocol=tcp dst-port=22\r" }

# Keluar dari MikroTik
expect ">" { send "quit\r" }
expect eof
