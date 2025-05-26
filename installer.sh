#!/bin/bash

# 🔧 Install prerequisites
echo "Installing prerequisites (unzip and certbot)..."
apt-get update -y
apt-get install unzip certbot -y

# ✅ Main Menu
while true; do
  clear
  echo "===== MAIN MENU ====="
  echo "1. Nasb Panel Marzban"
  echo "2. Gereftan Certificate (SSL)"
  echo "3. Nasb Warp (WARP)"
  echo "4. Khorooj"
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

      # Download xray_config.json
      XRAY_FILE="/var/lib/marzban/xray_config.json"
      curl -fsSL https://raw.githubusercontent.com/mashkouk/files-marzban-configer/refs/heads/main/xray_config.json -o "$XRAY_FILE"

      if [[ -f "$XRAY_FILE" ]]; then
        sed -i "65s|\".*\"|\"/var/lib/marzban/certs/$DOMAIN/fullchain.pem\"|" "$XRAY_FILE"
        sed -i "66s|\".*\"|\"/var/lib/marzban/certs/$DOMAIN/privkey.pem\"|" "$XRAY_FILE"
      else
        echo "⚠️ File xray_config peyda nashod."
      fi

      echo "🔄 Restart Marzban..."
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
      cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem /var/lib/marzban/certs/$DOMAIN/fullchain.pem
      cp /etc/letsencrypt/live/$DOMAIN/privkey.pem /var/lib/marzban/certs/$DOMAIN/privkey.pem

      ENV_FILE="/etc/opt/marzneshin/.env"

      if [[ -f "$ENV_FILE" ]]; then
        sed -i "s|^# UVICORN_SSL_CERTFILE *=.*|UVICORN_SSL_CERTFILE=\"/var/lib/marzban/certs/$DOMAIN/fullchain.pem\"|" "$ENV_FILE"
        sed -i "s|^# UVICORN_SSL_KEYFILE *=.*|UVICORN_SSL_KEYFILE=\"/var/lib/marzban/certs/$DOMAIN/privkey.pem\"|" "$ENV_FILE"
      else
        echo "⚠️ File settings peyda nashod: $ENV_FILE"
      fi

      # Download and modify xray_config.json
      XRAY_FILE="/var/lib/marzban/xray_config.json"
      curl -fsSL https://raw.githubusercontent.com/mashkouk/files-marzban-configer/refs/heads/main/xray_config.json -o "$XRAY_FILE"

      if [[ -f "$XRAY_FILE" ]]; then
        sed -i "65s|\".*\"|\"/var/lib/marzban/certs/$DOMAIN/fullchain.pem\"|" "$XRAY_FILE"
        sed -i "66s|\".*\"|\"/var/lib/marzban/certs/$DOMAIN/privkey.pem\"|" "$XRAY_FILE"
      else
        echo "⚠️ File xray_config peyda nashod."
      fi

      echo "🔄 Restart Marzban..."
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

      echo "🔄 Restart Marzban..."
      marzban restart
      echo "✅ Warp ba movafaghiat nasb shod."

      read -p "Baraye bazgasht be menu Enter bezanid..."
      ;;
    4)
      echo "👋 Khorooj az barname. Movafagh bashid!"
      exit 0
      ;;
    *)
      echo "❌ Gozine namotabar. Lotfan 1 ta 4 entekhab konid."
      sleep 2
      ;;
  esac
done
