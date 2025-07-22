#!/bin/bash

echo ""
echo "âœ… Dar hale nasb Warp..."

# Ù†ØµØ¨ Ø§Ø¨Ø²Ø§Ø±Ù‡Ø§ÛŒ Ù„Ø§Ø²Ù…
apt update -y
apt install wireguard-dkms wireguard-tools resolvconf cron curl -y

# ØªØ¹ÛŒÛŒÙ† Ù…Ø¹Ù…Ø§Ø±ÛŒ Ø³ÛŒØ³ØªÙ… (amd64 ÛŒØ§ arm64)
ARCH=$(dpkg --print-architecture)
if [[ "$ARCH" == "amd64" ]]; then
  ARCH_DL="linux_amd64"
elif [[ "$ARCH" == "arm64" ]]; then
  ARCH_DL="linux_arm64"
else
  echo "âŒ Ù…Ø¹Ù…Ø§Ø±ÛŒ Ù†Ø§Ø´Ù†Ø§Ø®ØªÙ‡: $ARCH"
  exit 1
fi

# Ø¯Ø±ÛŒØ§ÙØª Ø¢Ø®Ø±ÛŒÙ† Ù†Ø³Ø®Ù‡ wgcf Ø§Ø² GitHub
echo "ðŸ“¦ Dar hale daryaft akharin version wgcf az GitHub..."
LATEST_VERSION=$(curl -s https://api.github.com/repos/ViRb3/wgcf/releases/latest | grep '"tag_name"' | cut -d '"' -f4)

if [[ -z "$LATEST_VERSION" ]]; then
  echo "âŒ Natavanest version jadid ra peyda konad."
  exit 1
fi

# Ø¯Ø§Ù†Ù„ÙˆØ¯ Ø¨Ø§ÛŒÙ†Ø±ÛŒ wgcf
WGCF_BIN="wgcf_${LATEST_VERSION}_${ARCH_DL}"
DOWNLOAD_URL="https://github.com/ViRb3/wgcf/releases/download/${LATEST_VERSION}/${WGCF_BIN}"

echo "â¬‡ï¸ Downloading: $DOWNLOAD_URL"
curl -L -o /usr/bin/wgcf "$DOWNLOAD_URL"
chmod +x /usr/bin/wgcf

# Ø«Ø¨Øª Ùˆ ØªÙˆÙ„ÛŒØ¯ Ú©Ø§Ù†ÙÛŒÚ¯
wgcf register --accept-tos
wgcf generate

# ÙˆÛŒØ±Ø§ÛŒØ´ ÙØ§ÛŒÙ„ Ú©Ø§Ù†ÙÛŒÚ¯ Ùˆ Ø§Ù†ØªÙ‚Ø§Ù„ Ø¢Ù†
CONF_FILE="/root/wgcf-profile.conf"
if [[ -f "$CONF_FILE" ]]; then
  sed -i '/^MTU = 1280/a Table = off' "$CONF_FILE"
  echo "âœ… Table = off ezafe shod."
else
  echo "âš ï¸ File config peyda nashod."
fi

mv /root/wgcf-profile.conf /etc/wireguard/warp.conf

# Ø§Ø¬Ø±Ø§ÛŒ Ø³Ø±ÙˆÛŒØ³ WireGuard Ø¨Ø§ warp
systemctl enable --now wg-quick@warp

echo "âœ… Warp ba movafaghiat nasb shod."

# Ø¯Ø±ÛŒØ§ÙØª Ø²Ù…Ø§Ù† Ø¯Ù„Ø®ÙˆØ§Ù‡ Ø§Ø² Ú©Ø§Ø±Ø¨Ø± Ø¨Ø±Ø§ÛŒ Ø¨Ø±ÙˆØ²Ø±Ø³Ø§Ù†ÛŒ Ø®ÙˆØ¯Ú©Ø§Ø±
echo ""
read -p "ðŸ•’ Lotfan zaman baraye update (Ù…Ø«al: 0 3 * * * baraye saat 3 sobh har roz) vared konid: " cron_time

# Ø³Ø§Ø®Øª Ø§Ø³Ú©Ø±ÛŒÙ¾Øª Ø¨Ø±ÙˆØ²Ø±Ø³Ø§Ù†ÛŒ
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

# Ø§Ø¶Ø§ÙÙ‡ Ú©Ø±Ø¯Ù† Ú©Ø±ÙˆÙ†â€ŒØ¬Ø§Ø¨
(crontab -l 2>/dev/null; echo "$cron_time /usr/local/bin/update-warp-config.sh") | crontab -

echo "ðŸ› ï¸ Cron job baraye update config ba movafaghiat set shod."
echo "ðŸ“… Zaman entekhab shode: $cron_time"
echo "ðŸ“‚ Log har bar dar: /var/log/warp-update.log"

read -p "Baraye bazgasht be menu Enter bezanid..."