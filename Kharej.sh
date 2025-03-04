#!/bin/bash

# بررسی ورود آی‌پی سرور 2 به عنوان ورودی
if [ -z "$1" ]; then
  echo "لطفاً آی‌پی سرور 2 (سرور داخلی) را وارد کنید:"
  read SERVER2_IP
else
  SERVER2_IP=$1
fi

# دستورات مربوط به سرور 1
echo "در حال ایجاد تونل روی سرور 1 ..."

# ایجاد تونل 6to4
sudo ip tunnel add tun6to4 mode sit ttl 254 remote $SERVER2_IP
sudo ip link set tun6to4 up
sudo ip addr add fc01::1/64 dev tun6to4

# ایجاد تونل GRE
sudo ip tunnel add gre1 mode ip6gre remote fc01::2 local fc01::1
sudo ip link set gre1 up
sudo ip addr add 10.10.15.1/30 dev gre1

# فعال‌سازی forwarding IPv4
sudo sysctl -w net.ipv4.ip_forward=1

echo "تنظیمات تونل با موفقیت انجام شد."
