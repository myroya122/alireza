#!/bin/bash

# دریافت آی‌پی سرور 1 به طور تعاملی
echo "لطفاً آی‌پی سرور 1 (سرور خارجی) را وارد کنید:"
read SERVER1_IP

# دستورات مربوط به سرور 2
echo "در حال ایجاد تونل روی سرور 2 ..."

# ایجاد تونل 6to4
sudo ip tunnel add tun6to4 mode sit ttl 254 remote $SERVER1_IP
sudo ip link set tun6to4 up
sudo ip addr add fc01::2/64 dev tun6to4

# ایجاد تونل GRE
sudo ip tunnel add gre1 mode ip6gre remote fc01::1 local fc01::2
sudo ip link set gre1 up
sudo ip addr add 10.10.15.2/30 dev gre1

# فعال‌سازی forwarding IPv4
sudo sysctl -w net.ipv4.ip_forward=1

echo "تنظیمات تونل با موفقیت انجام شد."
