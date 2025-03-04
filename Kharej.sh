#!/bin/bash

# بررسی ماژول‌های لازم
if ! lsmod | grep -q sit; then
    modprobe sit
fi

if ! lsmod | grep -q ip6_gre; then
    modprobe ip6_gre
fi

# فعال کردن IPv6 در صورت نیاز
sysctl -w net.ipv6.conf.all.disable_ipv6=0

# گرفتن آی‌پی سرور 1
echo "لطفاً آی‌پی سرور 1 (سرور خارجی) را وارد کنید:"
read SERVER1_IP

# بررسی وضعیت تونل
if ip link show tun6to4; then
    echo "تونل قبلاً ایجاد شده است. در حال حذف تونل ..."
    ip tunnel del tun6to4
fi

# ایجاد تونل
echo "در حال ایجاد تونل روی سرور 1 ..."
ip tunnel add tun6to4 mode sit ttl 254 remote $SERVER1_IP
ip link set tun6to4 up
ip addr add fc01::1/64 dev tun6to4
ip tunnel add gre1 mode ip6gre remote fc01::2 local fc01::1
ip link set gre1 up
ip addr add 10.10.15.1/30 dev gre1
ip route add default via 10.10.15.2

# فعال کردن مسیریابی IPv4
sysctl -w net.ipv4.ip_forward=1

# حذف سرویس قدیمی (در صورت وجود)
echo "در حال حذف سرویس قبلی (در صورت وجود)..."
systemctl stop tunnel_check.service
systemctl disable tunnel_check.service
rm -f /etc/systemd/system/tunnel_check.service

# ایجاد سرویس systemd برای چک کردن تونل
echo "[Unit]
Description=Check Tunnel Status
After=network.target

[Service]
User=root
ExecStart=/bin/bash /path/to/your/tunnel_creation_script.sh
Restart=always
RestartSec=300

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/tunnel_check.service

# فعال‌سازی سرویس جدید
systemctl daemon-reload
systemctl enable tunnel_check.service
systemctl start tunnel_check.service

echo "سرویس با موفقیت راه‌اندازی شد. تونل به صورت خودکار بررسی و ایجاد می‌شود."
