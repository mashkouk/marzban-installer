#!/bin/bash

echo ""
echo "✅ Dar hale nasb Warp..."

# نصب ابزارهای لازم
apt update -y
apt install wireguard-dkms wireguard-tools resolvconf cron curl -y

# تعیین معماری سیستم (amd64 یا arm64)
ARCH=$(dpkg --print-architecture)
if [[ "$ARCH" == "amd64" ]]; then
  ARCH_DL="linux_amd64"
elif [[ "$ARCH" == "arm64" ]]; then
  ARCH_DL="linux_arm64"
else
  echo "❌ معماری ناشناخته: $ARCH"
  exit 1
fi

# دریافت آخرین نسخه wgcf از GitHub
echo "📦 Dar hale daryaft akharin version wgcf az GitHub..."
LATEST_VERSION=$(curl -s https://api.github.com/repos/ViRb3/wgcf/releases/latest | grep '"tag_name"' | cut -d '"' -f4)

if [[ -z "$LATEST_VERSION" ]]; then
  echo "❌ Natavanest version jadid ra peyda konad."
  exit 1
fi

# دانلود باینری wgcf
WGCF_BIN="wgcf_${LATEST_VERSION}_${ARCH_DL}"
DOWNLOAD_URL="https://github.com/ViRb3/wgcf/releases/download/${LATEST_VERSION}/${WGCF_BIN}"

echo "⬇️ Downloading: $DOWNLOAD_URL"
curl -L -o /usr/bin/wgcf "$DOWNLOAD_URL"
chmod +x /usr/bin/wgcf

# ثبت و تولید کانفیگ
wgcf register --accept-tos
wgcf generate

# ویرایش فایل کانفیگ و انتقال آن
CONF_FILE="/root/wgcf-profile.conf"
if [[ -f "$CONF_FILE" ]]; then
  sed -i '/^MTU = 1280/a Table = off' "$CONF_FILE"
  echo "✅ Table = off ezafe shod."
else
  echo "⚠️ File config peyda nashod."
fi

mv /root/wgcf-profile.conf /etc/wireguard/warp.conf

# اجرای سرویس WireGuard با warp
systemctl enable --now wg-quick@warp

# ریستارت Marzban در صورت موجود بودن
if command -v marzban &> /dev/null; then
  echo "🔁 Restart Marzban..."
  marzban restart
fi

echo "✅ Warp ba movafaghiat nasb shod."

# دریافت زمان دلخواه از کاربر برای بروزرسانی خودکار
echo ""
read -p "🕒 Lotfan zaman baraye update (مثal: 0 3 * * * baraye saat 3 sobh har roz) vared konid: " cron_time

# ساخت اسکریپت بروزرسانی
cat <<'EOF' > /usr/local/bin/update-warp-config.sh
#!/bin/bash
wgcf generate
CONF_FILE="/root/wgcf-profile.conf"
if [[ -f "$CONF_FILE" ]]; then
  sed -i '/^MTU = 1280/a Table = off' "$CONF_FILE"
  mv "$CONF_FILE" /etc/wireguard/warp.conf
  systemctl restart wg-quick@warp
  echo "[$(date)] Config updated successfully." > /var/log/warp-update.log
else
  echo "[$(date)] Config file not found!" > /var/log/warp-update.log
fi
EOF

chmod +x /usr/local/bin/update-warp-config.sh

# اضافه کردن کرون‌جاب
(crontab -l 2>/dev/null; echo "$cron_time /usr/local/bin/update-warp-config.sh") | crontab -

echo "🛠️ Cron job baraye update config ba movafaghiat set shod."
echo "📅 Zaman entekhab shode: $cron_time"
echo "📂 Log har bar dar: /var/log/warp-update.log"

read -p "Baraye bazgasht be menu Enter bezanid..."
