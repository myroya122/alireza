#!/bin/bash

# فایل ذخیره‌سازی آی‌پی
IP_FILE="/etc/tunnel_ip.txt"

# بررسی وجود فایل آی‌پی و دریافت آی‌پی از کاربر
#if [ -f $IP_FILE ]; then
   # echo "آی‌پی قبلی موجود است: $(cat $IP_FILE)"
   # echo "آیا می‌خواهید آی‌پی جدید وارد کنید؟ (y/n)"
    # read -t 5 RESPONSE
  #  if [[ "$RESPONSE" == "y" || "$RESPONSE" == "Y" ]]; then
     #   echo "لطفاً آی‌پی سرور 1 (سرور خارجی) را وارد کنید:"
      #  read SERVER1_IP
      #  echo $SERVER1_IP > $IP_FILE
 #   fi
#else
   # echo "لطفاً آی‌پی سرور 1 (سرور خارجی) را وارد کنید:"
  #  read SERVER1_IP
  #  echo $SERVER1_IP > $IP_FILE
#fi

# مسیر فایل سرویس systemd
SERVICE_PATH="/etc/systemd/system/tunnel_check.service"

# بررسی و حذف سرویس قبلی در صورت وجود
if systemctl is-active --quiet tunnel_check.service; then
    echo "سرویس قبلی حذف می‌شود..."
    systemctl stop tunnel_check.service
    systemctl disable tunnel_check.service
    rm -f $SERVICE_PATH
fi

# ایجاد فایل سرویس systemd
echo "در حال ایجاد سرویس systemd..."

cat <<EOL > $SERVICE_PATH
[Unit]
Description=بررسی و راه‌اندازی تونل
After=network.target

[Service]
Type=simple
ExecStart=/bin/bash /usr/local/bin/Kharej.sh
# دریافت آی‌پی از فایل
SERVER1_IP=\$(cat $IP_FILE)

# برقراری تونل 6to4
echo 'در حال ایجاد تونل 6to4 ...'
ip tunnel add tun6to4 mode sit ttl 254 remote \$SERVER1_IP
ip link set tun6to4 up
ip addr add fc01::1/64 dev tun6to4

# برقراری تونل GRE
echo 'در حال ایجاد تونل GRE ...'
ip tunnel add gre1 mode ip6gre remote fc01::2 local fc01::1
ip link set gre1 up
ip addr add 10.10.15.1/30 dev gre1
ip route add default via 10.10.15.2

# فعال کردن فوروارد کردن IPv4
sysctl -w net.ipv4.ip_forward=1

# بررسی وضعیت تونل و برقراری مجدد آن در صورت قطع شدن
while true; do
    if ! ip link show tun6to4 &>/dev/null; then
        echo 'تونل 6to4 یافت نشد. در حال برقراری مجدد تونل ...'
        ip tunnel add tun6to4 mode sit ttl 254 remote \$SERVER1_IP
        ip link set tun6to4 up
        ip addr add fc01::1/64 dev tun6to4
    fi
    sleep 300
done
"
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOL

# بارگذاری سرویس جدید و فعال‌سازی آن
echo "در حال بارگذاری و فعال‌سازی سرویس..."
systemctl daemon-reload
systemctl enable tunnel_check.service
systemctl start tunnel_check.service

echo "سرویس با موفقیت راه‌اندازی شد. تونل به صورت خودکار بررسی و ایجاد می‌شود."
