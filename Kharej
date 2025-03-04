#!/bin/bash

# گرفتن آی‌پی سرور 2 (سرور داخلی)
echo "لطفاً آی‌پی سرور 2 (سرور داخلی) را وارد کنید:"
read SERVER2_IP

# دستورات مربوط به سرور 1
echo "در حال ایجاد تونل روی سرور 1 ..."
ip tunnel add tun6to4 mode sit ttl 254 remote $SERVER2_IP
ip link set tun6to4 up
ip addr add fc01::1/64 dev tun6to4
ip tunnel add gre1 mode ip6gre remote fc01::2 local fc01::1
ip link set gre1 up
ip addr add 10.10.15.1/30 dev gre1
ip route add default via 10.10.15.2
sysctl -w net.ipv4.ip_forward=1
