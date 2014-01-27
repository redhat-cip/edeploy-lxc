#!/bin/sh
dev=$(ip -4 r|awk '/^default via/ {print $5}')
iptables -A FORWARD -i bibi0 -j ACCEPT
iptables -A FORWARD -o bibi0 -j ACCEPT
iptables -t nat -A POSTROUTING -o $dev -j MASQUERADE
echo 1 > /proc/sys/net/ipv4/ip_forward
