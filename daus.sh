#!/usr/bin/expect

# Aktifkan log untuk debugging
log_file -a debug_output.log

# Mulai sesi telnet
spawn telnet 192.168.234.132 30016
set timeout 10

# Login
expect "Mikrotik Login: " { send "admin\r" }
expect "Password: " { send "\r" }

# Jika ada prompt untuk lisensi, jawab "n"
expect {
    -re "Do you want to see the software license.*" { send "n\r" }
    "new password>" { send "123\r" }
}

# Ubah password dengan waktu tunggu tambahan
expect "new password>" { 
    sleep 1
    send "123\r"
}         
expect "repeat new password>" { 
    sleep 1
    send "123\r"
}

# Verifikasi keberhasilan
expect {
    "Try again, error: New passwords do not match!" {
        puts "Error: Password tidak cocok. Harap periksa kembali input password."
        exit 1
    }
    ">" {
        puts "Password berhasil diubah."
    }
}

# Menambahkan IP Address
expect ">" { send "/ip address add address=192.168.200.1/24 interface=ether2\r" }

# Menambahkan NAT Masquerade
expect ">" { send "/ip firewall nat add chain=srcnat out-interface=ether2 action=masquerade\r" }

# Menambahkan Route
expect ">" { send "/ip route add dst-address=192.168.200.1/24 gateway=192.168.20.1\r" }

# Keluar dari MikroTik
expect ">" { send "quit\r" }
expect eof
