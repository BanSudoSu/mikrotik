#!/usr/bin/expect

spawn telnet 192.168.234.132 30016
set timeout 10
expect "Mikrotik Login: " { send "admin\r" }
expect "Password: " { send "\r" }
expect {
    "Do you want to see the software license? [Y/n]:" { send "n\r" }
    "new password>" { send "123\r" }
expect "new password>" { 
    sleep 1
    send "123\r"         
expect "repeat new password>" { 
    sleep 1
    send "123\r"
expect ">" { send "/ip address add address=192.168.200.1/24 interface=ether2\r" }
expect ">" { send "/ip firewall nat add chain=srcnat out-interface=ether2 action=masquerade\r" }
expect ">" { send "/ip route add dst-address=192.168.200.1/24 gateway=192.168.20.1\r" }
expect ">" { send "quit\r" }
expect eof
