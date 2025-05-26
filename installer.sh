#!/bin/bash

# 🔧 نصب پیش‌نیازها
echo "در حال نصب پیش‌نیازها (unzip و certbot)..."
apt-get update -y
apt-get install unzip certbot -y

# ✅ منوی اصلی
while true; do
  clear
  echo "===== منوی اصلی ====="
  echo "1. نصب پنل مرزبان"
  echo "2. گرفتن سرتیفیکیت (SSL)"
  echo "3. نصب وارپ (Warp)"
  echo "4. خروج"
  echo "======================"
  read -p "لطفاً شماره گزینه مورد نظر را وارد کنید: " choice

  case $choice in
    1)
      echo ""
      echo "✅ در حال نصب پنل مرزبان..."
      bash -c "$(curl -sL https://github.com/Gozargah/Marzban-scripts/raw/master/marzban.sh)" @ install --database mariadb
      echo "✅ نصب پنل مرزبان انجام شد."

      # دریافت دامنه و پورت
      read -p "🌐 دامنه پنل را وارد کنید (مثال: panel.example.com): " DOMAIN
      read -p "🔌 شماره پورت پنل را وارد کنید (مثال: 8000): " PORT

      echo ""
      echo "⚠️  لطفاً توجه داشته باشید: پس از نصب باید از گزینه ۲ گواهی SSL دریافت کنید."
      echo ""

      ENV_FILE="/opt/marzban/.env"

      if [[ -f "$ENV_FILE" ]]; then
        sed -i "s|^UVICORN_PORT *=.*|UVICORN_PORT=$PORT|" "$ENV_FILE"
        sed -i "s|^# XRAY_SUBSCRIPTION_URL_PREFIX *=.*|XRAY_SUBSCRIPTION_URL_PREFIX=\"https://$DOMAIN:$PORT\"|" "$ENV_FILE"
      else
        echo "⚠️ فایل تنظیمات پیدا نشد: $ENV_FILE"
      fi

      # جایگزینی docker-compose.yml
      curl -fsSL https://raw.githubusercontent.com/mashkouk/files-marzban-configer/refs/heads/main/docker-compose.yml -o /opt/marzban/docker-compose.yml

      # استخراج فایل app.zip
      curl -fsSL https://raw.githubusercontent.com/mashkouk/files-marzban-configer/refs/heads/main/app.zip -o /tmp/app.zip
      unzip -o /tmp/app.zip -d /var/lib/marzban/
      rm /tmp/app.zip

      # ری‌استارت مرزبان
      echo "🔄 ری‌استارت مرزبان..."
      marzban restart
      echo "✅ پایان عملیات."

      read -p "برای بازگشت به منو Enter بزنید..."
      ;;
    2)
      echo ""
      read -p "🌐 دامنه را وارد کنید (مثال: panel.example.com): " DOMAIN

      mkdir -p /var/lib/marzban/certs/$DOMAIN

      certbot certonly --standalone --agree-tos --register-unsafely-without-email -d $DOMAIN
      cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem /var/lib/marzban/certs/$DOMAIN/fullchain.pem
      cp /etc/letsencrypt/live/$DOMAIN/privkey.pem /var/lib/marzban/certs/$DOMAIN/privkey.pem

      ENV_FILE="/etc/opt/marzneshin/.env"

      if [[ -f "$ENV_FILE" ]]; then
        sed -i "s|^# UVICORN_SSL_CERTFILE *=.*|UVICORN_SSL_CERTFILE=\"/var/lib/marzban/certs/$DOMAIN/fullchain.pem\"|" "$ENV_FILE"
        sed -i "s|^# UVICORN_SSL_KEYFILE *=.*|UVICORN_SSL_KEYFILE=\"/var/lib/marzban/certs/$DOMAIN/privkey.pem\"|" "$ENV_FILE"
      else
        echo "⚠️ فایل تنظیمات پیدا نشد: $ENV_FILE"
      fi

      echo "🔄 ری‌استارت مرزبان..."
      marzban restart
      echo "✅ پایان عملیات."

      read -p "برای بازگشت به منو Enter بزنید..."
      ;;
    3)
      echo ""
      echo "✅ در حال نصب وارپ (Warp)..."
      apt update -y
      apt install wireguard-dkms wireguard-tools resolvconf -y

      wget https://github.com/ViRb3/wgcf/releases/download/v2.2.22/wgcf_2.2.22_linux_arm64 -P /root
      mv /root/wgcf_2.2.22_linux_arm64 /usr/bin/wgcf
      chmod +x /usr/bin/wgcf

      wgcf register
      wgcf generate

      CONF_FILE="/root/wgcf-profile.conf"
      if [[ -f "$CONF_FILE" ]]; then
        sed -i '/^MTU = 1280/a Table = off' "$CONF_FILE"
        echo "✅ خط 'Table = off' اضافه شد."
      else
        echo "⚠️ فایل کانفیگ پیدا نشد."
      fi

      mv /root/wgcf-profile.conf /etc/wireguard/warp.conf
      systemctl enable --now wg-quick@warp

      echo "🔄 ری‌استارت مرزبان..."
      marzban restart
      echo "✅ نصب وارپ کامل شد."

      read -p "برای بازگشت به منو Enter بزنید..."
      ;;
    4)
      echo "👋 خروج از برنامه. موفق باشید!"
      exit 0
      ;;
    *)
      echo "❌ گزینه نامعتبر. لطفاً یکی از گزینه‌های 1 تا 4 را انتخاب کنید."
      sleep 2
      ;;
  esac
done
