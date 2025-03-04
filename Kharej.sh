#!/bin/bash

# گرفتن آی‌پی سرور 2 (سرور داخلی)
echo "لطفاً آی‌پی سرور 2 (سرور داخلی) را وارد کنید:"
read SERVER2_IP

# 1. حذف سرویس قبلی در صورت وجود
echo "در حال حذف سرویس قبلی (در صورت وجود)..."
systemctl stop tunnel_check.service
systemctl disable tunnel_check.service
rm -f /etc/systemd/system/tunnel_check.service

# 2. حذف اسکریپت قبلی در صورت وجود
echo "در حال حذف اسکریپت قبلی (در صورت وجود)..."
rm -f /usr/local/bin/tunnel_check.sh

# 3. ساخت اسکریپت بررسی و برقراری تونل
echo "در حال ایجاد اسکریپت بررسی و برقراری تونل..."
cat <<EOF > /usr/local/bin/tunnel_check.sh
#!/bin/bash

# بررسی وضعیت تونل
TUNNEL_STATUS=\$(ip link show tun6to4 2>/dev/null)

if [[ -z "\$TUNNEL_STATUS" ]]; then
    echo "تونل یافت نشد. در حال برقراری تونل جدید..."
    ip tunnel add tun6to4 mode sit ttl 254 remote \$SERVER2_IP
    ip link set tun6to4 up
    ip addr add fc01::1/64 dev tun6to4
    ip tunnel add gre1 mode ip6gre remote fc01::2 local fc01::1
    ip link set gre1 up
    ip addr add 10.10.15.1/30 dev gre1
    ip route add default via 10.10.15.2
    sysctl -w net.ipv4.ip_forward=1
else
    echo "تونل قبلاً ایجاد شده است."
fi
EOF

# دادن اجازه اجرا به اسکریپت
chmod +x /usr/local/bin/tunnel_check.sh

# 4. ایجاد فایل سرویس systemd
echo "در حال ایجاد سرویس systemd..."
cat <<EOF > /etc/systemd/system/tunnel_check.service
[Unit]
Description=بررسی و راه‌اندازی تونل

[Service]
ExecStart=/usr/local/bin/tunnel_check.sh $SERVER2_IP
Restart=always
RestartSec=300  # هر ۵ دقیقه یک‌بار اجرا شود

[Install]
WantedBy=multi-user.target
EOF

# 5. بارگذاری مجدد سرویس‌ها و فعال‌سازی سرویس جدید
echo "در حال فعال‌سازی سرویس..."
systemctl daemon-reload
systemctl enable tunnel_check.service
systemctl start tunnel_check.service

echo "سرویس با موفقیت راه‌اندازی شد. تونل به صورت خودکار بررسی و ایجاد می‌شود."
