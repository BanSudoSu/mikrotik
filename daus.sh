#!/usr/bin/expect

spawn telnet 192.168.234.132 30016
set timeout 10

# Login
expect "Mikrotik Login: " { send "admin\r" }
expect "Password: " { send "\r" }

# Jika ada prompt untuk lisensi, jawab "n"
expect {
    "Do you want to see the software license? [Y/n]:" { send "n\r" }
    "new password>" { send "123\r" }
}

# Mengubah password baru
expect "new password>" { 
    sleep 1
    send "123\r"
}         
expect "repeat new password>" { 
    sleep 1
    send "123\r"
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
