#!/bin/bash

echo ""
echo "✅ Dar hale nasb Warp..."

apt update -y
apt install wireguard-dkms wireguard-tools resolvconf cron curl -y

ARCH=$(dpkg --print-architecture)
if [[ "$ARCH" == "amd64" ]]; then
  ARCH_DL="linux_amd64"
elif [[ "$ARCH" == "arm64" ]]; then
  ARCH_DL="linux_arm64"
else
  echo "❌ معماری ناشناخته: $ARCH"
  exit 1
fi

echo "📦 Dar hale daryaft akharin version wgcf az GitHub..."
LATEST_VERSION=$(curl -s https://api.github.com/repos/ViRb3/wgcf/releases/latest | grep '"tag_name"' | cut -d '"' -f4)

if [[ -z "$LATEST_VERSION" ]]; then
  echo "❌ Natavanest version jadid ra peyda konad."
  exit 1
fi

WGCF_BIN="wgcf_${LATEST_VERSION}_${ARCH_DL}"
DOWNLOAD_URL="https://github.com/ViRb3/wgcf/releases/download/${LATEST_VERSION}/${WGCF_BIN}"

echo "⬇️ Downloading: $DOWNLOAD_URL"
curl -L -o /usr/bin/wgcf "$DOWNLOAD_URL"
chmod +x /usr/bin/wgcf

wgcf register --accept-tos
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

echo "✅ Warp ba movafaghiat nasb shod."

read -p "🕒 Lotfan zaman baraye update (مثal: 0 3 * * * baraye saat 3 sobh har roz) vared konid: " cron_time

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
(crontab -l 2>/dev/null; echo "$cron_time /usr/local/bin/update-warp-config.sh") | crontab -

echo "🛠️ Cron job baraye update config ba movafaghiat set shod."
echo "📅 Zaman entekhab shode: $cron_time"
echo "📂 Log har bar dar: /var/log/warp-update.log"

read -p "Baraye bazgasht be menu Enter bezanid..."
