#!/usr/bin/expect

# Spawn telnet session
spawn telnet 192.168.234.132 30016

# Set timeout untuk menunggu respon dari telnet
set timeout 10

# Login dengan username "admin" dan password kosong
expect "Mikrotik Login: " { send "admin\r" }
expect "Password: " { send "\r" }   # Kosongkan password

# Set password baru (apabila diminta) dan ulangi password baru
expect "new password>" { send "123\r" }
expect "repeat new password>" { send "123\r" }

# Setelah login, kirim perintah untuk menambahkan IP address
expect ">" { send "/ip address add address=192.168.200.1/24 interface=ether2\r" }

# Kirim perintah untuk menambahkan NAT rule
expect ">" { send "/ip firewall nat add chain=srcnat out-interface=ether2 action=masquerade\r" }

# Kirim perintah untuk menambahkan route
expect ">" { send "/ip route add dst-address=192.168.200.0/24 gateway=192.168.20.1\r" }

# Keluar dari session
expect ">" { send "quit\r" }

# Tunggu hingga session selesai
expect eof
