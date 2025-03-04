#!/bin/bash

# گرفتن آی‌پی سرور 1 (سرور خارجی)
echo "لطفاً آی‌پی سرور 1 (سرور خارجی) را وارد کنید:"
read SERVER1_IP

# دستورات مربوط به سرور 2
echo "در حال ایجاد تونل روی سرور 2 ..."
ip tunnel add tun6to4 mode sit ttl 254 remote $SERVER1_IP
ip link set tun6to4 up
ip addr add fc01::2/64 dev tun6to4
ip tunnel add gre1 mode ip6gre remote fc01::1 local fc01::2
ip link set gre1 up
ip addr add 10.10.15.2/30 dev gre1
ip route add default via 10.10.15.1
sysctl -w net.ipv4.ip_forward=1
