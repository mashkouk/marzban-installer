#!/bin/bash

# 🔧 نصب پیش‌نیازها
echo "در حال نصب پیش‌نیازها (unzip و certbot)..."
sudo apt-get update -y
sudo apt-get install unzip certbot -y

# ✅ منوی اصلی
while true; do
  clear
  echo "===== منوی اصلی ====="
  echo "1. نصب پنل مرزبان"
  echo "2. گرفتن سرتیفیکیت (SSL)"
  echo "3. خروج"
  echo "======================"
  read -p "لطفاً شماره گزینه مورد نظر را وارد کنید: " choice

  case $choice in
    1)
      echo ""
      echo "✅ در حال نصب پنل مرزبان..."
      echo "------------------------------------"
      sudo bash -c "$(curl -sL https://github.com/Gozargah/Marzban-scripts/raw/master/marzban.sh)" @ install --database mariadb
      echo "------------------------------------"
      echo "✅ نصب پنل مرزبان به پایان رسید."

      # 🧾 دریافت دامنه و پورت از کاربر
      echo ""
      read -p "🌐 لطفاً دامنه مربوط به پنل را وارد کنید (مثال: panel.example.com): " DOMAIN
      read -p "🔌 لطفاً شماره پورت دلخواه برای پنل را وارد کنید (مثال: 8443): " PORT

      echo ""
      echo "⚠️  هشدار: برای عملکرد صحیح پنل، باید ابتدا سرتیفیکیت را از گزینه ۲ دریافت کنید."
      echo ""

      ENV_FILE="/opt/marzban/.env"

      if [[ -f "$ENV_FILE" ]]; then
        # جایگزینی مقدار پورت
        sudo sed -i "s|^UVICORN_PORT *=.*|UVICORN_PORT=$PORT|" "$ENV_FILE"

        # فعال‌سازی و جایگزینی آدرس XRAY
        sudo sed -i "s|^# XRAY_SUBSCRIPTION_URL_PREFIX *=.*|XRAY_SUBSCRIPTION_URL_PREFIX=\"https://$DOMAIN:$PORT\"|" "$ENV_FILE"

        echo "✅ پورت و آدرس XRAY در فایل .env به‌روزرسانی شدند."
      else
        echo "❌ فایل .env در مسیر $ENV_FILE یافت نشد!"
      fi

      # ری‌استارت سرویس مرزبان
      echo "در حال ری‌استارت سرویس مرزبان..."
      marzban restart
      echo "✅ سرویس مرزبان ری‌استارت شد."

      read -p "برای بازگشت به منو Enter بزنید..."
      ;;
    2)
      echo ""
      read -p "🌐 لطفاً دامنه مربوط به پنل مرزبان را وارد کنید (مثال: panel.example.com): " DOMAIN

      if [[ -z "$DOMAIN" ]]; then
        echo "❌ دامنه نمی‌تواند خالی باشد."
        sleep 2
        continue
      fi

      echo "✅ در حال دریافت گواهی SSL برای دامنه $DOMAIN ..."
      sudo mkdir -p /var/lib/marzban/certs/$DOMAIN

      sudo certbot certonly --standalone --agree-tos --register-unsafely-without-email -d $DOMAIN
      if [[ $? -ne 0 ]]; then
        echo "❌ دریافت گواهی با خطا مواجه شد."
        read -p "برای بازگشت به منو Enter بزنید..."
        continue
      fi

      sudo cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem /var/lib/marzban/certs/$DOMAIN/fullchain.pem
      sudo cp /etc/letsencrypt/live/$DOMAIN/privkey.pem /var/lib/marzban/certs/$DOMAIN/privkey.pem

      ENV_FILE="/etc/opt/marzneshin/.env"

      if [[ -f "$ENV_FILE" ]]; then
        echo "🔧 در حال به‌روزرسانی مسیرهای SSL در فایل .env..."

        sudo sed -i "s|^# UVICORN_SSL_CERTFILE *=.*|UVICORN_SSL_CERTFILE=\"/var/lib/marzban/certs/$DOMAIN/fullchain.pem\"|" "$ENV_FILE"
        sudo sed -i "s|^# UVICORN_SSL_KEYFILE *=.*|UVICORN_SSL_KEYFILE=\"/var/lib/marzban/certs/$DOMAIN/privkey.pem\"|" "$ENV_FILE"

        echo "✅ مسیرهای گواهی در فایل .env وارد شدند."
      else
        echo "❌ فایل .env در مسیر $ENV_FILE یافت نشد!"
      fi

      # ری‌استارت سرویس مرزبان
      echo "در حال ری‌استارت سرویس مرزبان..."
      marzban restart
      echo "✅ سرویس مرزبان ری‌استارت شد."

      read -p "برای بازگشت به منو Enter بزنید..."
      ;;
    3)
      echo "👋 خداحافظ!"
      exit 0
      ;;
    *)
      echo "❌ گزینه نامعتبر است. لطفاً عدد صحیح وارد کنید."
      sleep 2
      ;;
  esac
done
