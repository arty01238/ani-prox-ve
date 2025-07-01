#!/bin/bash

set -e

echo "🧹 Proxmox Anime Theme Uninstaller"

# Must be root
if [[ $EUID -ne 0 ]]; then
  echo "❌ Please run as root."
  exit 1
fi

# ---- Paths ----
PVE_CSS="/usr/share/pve-manager/css/ext6-pve.css"
PVE_TPL="/usr/share/pve-manager/index.html.tpl"
PVE_UI_JS="/usr/share/pve-manager/ext6/pve-ui.js"

# ---- Backups ----
PVE_CSS_BAK="${PVE_CSS}.bak"
PVE_TPL_BAK="${PVE_TPL}.bak"
PVE_UI_JS_BAK="${PVE_UI_JS}.bak"

# ---- Restore CSS ----
if [[ -f "$PVE_CSS_BAK" ]]; then
  echo "🎨 Restoring ext6-pve.css..."
  cp "$PVE_CSS_BAK" "$PVE_CSS"
else
  echo "⚠️ Backup for ext6-pve.css not found, skipping..."
fi

# ---- Restore index.html.tpl ----
if [[ -f "$PVE_TPL_BAK" ]]; then
  echo "🧾 Restoring index.html.tpl..."
  cp "$PVE_TPL_BAK" "$PVE_TPL"
else
  echo "⚠️ Backup for index.html.tpl not found, skipping..."
fi

# ---- Restore pve-ui.js ----
if [[ -f "$PVE_UI_JS_BAK" ]]; then
  echo "📦 Restoring pve-ui.js..."
  cp "$PVE_UI_JS_BAK" "$PVE_UI_JS"
else
  echo "⚠️ Backup for pve-ui.js not found, skipping..."
fi

# ---- Restart Web UI ----
echo "🔁 Restarting Proxmox web interface..."
systemctl restart pveproxy

echo "✅ Anime theme uninstalled. Original files restored."
