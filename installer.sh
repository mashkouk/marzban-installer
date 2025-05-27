#!/bin/bash

# 🔧 Install prerequisites
echo "Installing prerequisites (unzip and certbot)..."
apt-get update -y
apt-get install unzip certbot curl wget -y

# ✅ Main Menu
while true; do
  clear
  echo "===== MAIN MENU ====="
  echo "1. Nasb Panel Marzban"
  echo "2. Gereftan Certificate (SSL)"
  echo "3. Nasb Warp (WARP)"
  echo "4. Taghir Heste Xray"
  echo "5. Khorooj"
  echo "======================"
  read -p "Lotfan shomare gozine ra vared konid: " choice

  case $choice in
    1)
      echo ""
      echo "✅ Dar hale nasb panel Marzban..."
      bash -c "$(curl -sL https://github.com/Gozargah/Marzban-scripts/raw/master/marzban.sh)" @ install --database mariadb
      echo "✅ Nasb panel Marzban anjam shod."

      read -p "🌐 Domain panel ra vared konid (e.g. panel.example.com): " DOMAIN
      read -p "🔌 Port panel ra vared konid (e.g. 8000): " PORT

      echo ""
      echo "⚠️ Lotfan tavajoh konid: bayad ba gozine 2 certificate (SSL) daryaft konid."
      echo ""

      ENV_FILE="/opt/marzban/.env"

      if [[ -f "$ENV_FILE" ]]; then
        sed -i "s|^UVICORN_PORT *=.*|UVICORN_PORT=$PORT|" "$ENV_FILE"
        sed -i "s|^# XRAY_SUBSCRIPTION_URL_PREFIX *=.*|XRAY_SUBSCRIPTION_URL_PREFIX=\"https://$DOMAIN:$PORT\"|" "$ENV_FILE"
      else
        echo "⚠️ File settings peyda nashod: $ENV_FILE"
      fi

      # Replace docker-compose.yml
      curl -fsSL https://raw.githubusercontent.com/mashkouk/files-marzban-configer/refs/heads/main/docker-compose.yml -o /opt/marzban/docker-compose.yml

      # Extract app.zip
      curl -fsSL https://raw.githubusercontent.com/mashkouk/files-marzban-configer/refs/heads/main/app.zip -o /tmp/app.zip
      unzip -o /tmp/app.zip -d /var/lib/marzban/
      rm /tmp/app.zip

      echo "🔁 Restart Marzban..."
      marzban restart

      echo "👤 Sakht admin hesab:"
      marzban cli admin create --sudo

      echo "✅ Panel ba movafaghiat nasb shod."

      read -p "Baraye bazgasht be menu Enter bezanid..."
      ;;

    2)
      echo ""
      read -p "🌐 Domain ra vared konid (e.g. panel.example.com): " DOMAIN

      mkdir -p /var/lib/marzban/certs/$DOMAIN

      certbot certonly --standalone --agree-tos --register-unsafely-without-email -d $DOMAIN

      CERT_DIR=$(ls -d /etc/letsencrypt/live/${DOMAIN}*)

      if [[ -d "$CERT_DIR" ]]; then
        cp "$CERT_DIR/fullchain.pem" /var/lib/marzban/certs/$DOMAIN/fullchain.pem
        cp "$CERT_DIR/privkey.pem" /var/lib/marzban/certs/$DOMAIN/privkey.pem
      else
        echo "⚠️ Cert directory not found for domain $DOMAIN"
      fi

      ENV_FILE="/opt/marzban/.env"

      if [[ -f "$ENV_FILE" ]]; then
        sed -i '/UVICORN_SSL_CERTFILE/d' "$ENV_FILE"
        sed -i '/UVICORN_SSL_KEYFILE/d' "$ENV_FILE"

        echo "UVICORN_SSL_CERTFILE=\"/var/lib/marzban/certs/$DOMAIN/fullchain.pem\"" >> "$ENV_FILE"
        echo "UVICORN_SSL_KEYFILE=\"/var/lib/marzban/certs/$DOMAIN/privkey.pem\"" >> "$ENV_FILE"

        echo "✅ فایل .env ba movafaghiat update shod."
      else
        echo "⚠️ File settings peyda nashod: $ENV_FILE"
      fi

      # 📥 Download and edit xray_config.json
      XRAY_CONFIG_PATH="/var/lib/marzban/xray_config.json"
      curl -fsSL https://github.com/mashkouk/files-marzban-configer/raw/refs/heads/main/xray_config.json -o "$XRAY_CONFIG_PATH"

      if [[ -f "$XRAY_CONFIG_PATH" ]]; then
        sed -i "s|\"certificateFile\": \".*\"|\"certificateFile\": \"/var/lib/marzban/certs/$DOMAIN/fullchain.pem\"|" "$XRAY_CONFIG_PATH"
        sed -i "s|\"keyFile\": \".*\"|\"keyFile\": \"/var/lib/marzban/certs/$DOMAIN/privkey.pem\"|" "$XRAY_CONFIG_PATH"
        echo "✅ xray_config.json ba movafaghiat update shod."
      else
        echo "⚠️ xray_config.json peyda nashod."
      fi

      echo "🔁 Restart Marzban..."
      marzban restart
      echo "✅ SSL gerefte shod."

      read -p "Baraye bazgasht be menu Enter bezanid..."
      ;;

    3)
      echo ""
      echo "✅ Dar hale nasb Warp..."
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
        echo "✅ Table = off ezafe shod."
      else
        echo "⚠️ File config peyda nashod."
      fi

      mv /root/wgcf-profile.conf /etc/wireguard/warp.conf
      systemctl enable --now wg-quick@warp

      echo "🔁 Restart Marzban..."
      marzban restart
      echo "✅ Warp ba movafaghiat nasb shod."

      read -p "Baraye bazgasht be menu Enter bezanid..."
      ;;

    4)
      echo ""
      echo "🧠 Taghir heste Marzban"

      ARCH=$(uname -m)
      case "$ARCH" in
        x86_64)
          ARCH_DL="amd64"
          ;;
        aarch64 | arm64)
          ARCH_DL="arm64"
          ;;
        *)
          echo "⚠️ معماری ناشناخته: $ARCH"
          read -p "Baraye bazgasht be menu Enter bezanid..."
          continue
          ;;
      esac

      LATEST_XRAY_VERSION=$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases/latest | grep tag_name | cut -d '"' -f4)
      XRAY_URL="https://github.com/XTLS/Xray-core/releases/download/${LATEST_XRAY_VERSION}/Xray-linux-${ARCH_DL}.zip"

      LATEST_GFW_VERSION=$(curl -s https://api.github.com/repos/GFW-knocker/Xray-core/releases/latest | grep tag_name | cut -d '"' -f4)
      GFW_URL="https://github.com/GFW-knocker/Xray-core/releases/download/${LATEST_GFW_VERSION}/Xray-linux-${ARCH_DL}.zip"

      echo ""
      echo "🔧 Gozine mored nazar ra entekhab konid:"
      echo "1. Xray-core rasmi (XTLS) - $LATEST_XRAY_VERSION"
      echo "2. Xray-core GFW-knocker - $LATEST_GFW_VERSION"
      echo "3. Link delkhah"
      read -p "Shomare gozine ra vared konid: " CORE_CHOICE

      case $CORE_CHOICE in
        1)
          DOWNLOAD_URL="$XRAY_URL"
          ;;
        2)
          DOWNLOAD_URL="$GFW_URL"
          ;;
        3)
          read -p "🔗 Link delkhah ra vared konid: " DOWNLOAD_URL
          ;;
        *)
          echo "❌ Gozine namotabar."
          read -p "Baraye bazgasht be menu Enter bezanid..."
          continue
          ;;
      esac

      CORE_DIR="/var/lib/marzban/xray-core"
      mkdir -p "$CORE_DIR"
      TEMP_ZIP="/tmp/xray-core.zip"

      echo "⬇️ Dar hale download az: $DOWNLOAD_URL"
      wget -O "$TEMP_ZIP" "$DOWNLOAD_URL"

      if [[ $? -ne 0 ]]; then
        echo "❌ دانلود ناموفق بود."
        rm -f "$TEMP_ZIP"
        read -p "Baraye bazgasht be menu Enter bezanid..."
        continue
      fi

      unzip -o "$TEMP_ZIP" -d "$CORE_DIR"
      rm -f "$TEMP_ZIP"

      XRAY_BIN="$CORE_DIR/xray"
      if [[ -f "$XRAY_BIN" ]]; then
        chmod +x "$XRAY_BIN"
        echo "✅ Heste ba movafaghiat dar $XRAY_BIN gharar gereft."
      else
        echo "❌ فایل اجرایی xray پیدا نشد در: $CORE_DIR"
        read -p "Baraye bazgasht be menu Enter bezanid..."
        continue
      fi

      ENV_FILE="/opt/marzban/.env"
      if [[ -f "$ENV_FILE" ]]; then
        grep -q "XRAY_EXECUTABLE_PATH" "$ENV_FILE" && \
          sed -i "s|^XRAY_EXECUTABLE_PATH=.*|XRAY_EXECUTABLE_PATH=\"$XRAY_BIN\"|" "$ENV_FILE" || \
          echo "XRAY_EXECUTABLE_PATH=\"$XRAY_BIN\"" >> "$ENV_FILE"
        echo "📌 Path be .env ezafe shod."
      else
        echo "⚠️ File .env peyda nashod: $ENV_FILE"
      fi

      echo "🔁 Restart Marzban..."
      marzban restart
      echo "✅ Taghir heste anjam shod."

      read -p "Baraye bazgasht be menu Enter bezanid..."
      ;;

    5)
      echo "👋 Khorooj az barname. Movafagh bashid!"
      exit 0
      ;;

    *)
      echo "❌ Gozine namotabar. Lotfan 1 ta 5 entekhab konid."
      sleep 2
      ;;
  esac
done
