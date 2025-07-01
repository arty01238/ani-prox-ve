#!/bin/bash

set -e

echo "🧹 Proxmox Anime Theme Uninstaller (Interactive Rollback Tool)"

# ---- Safety Check ----
if [[ $EUID -ne 0 ]]; then
  echo "❌ Please run this script as root."
  exit 1
fi

# ---- Paths ----
PVE_CSS="/usr/share/pve-manager/css/ext6-pve.css"
PVE_TPL="/usr/share/pve-manager/index.html.tpl"
PVE_UI_JS="/usr/share/pve-manager/ext6/pve-ui.js"
PVE_MGR_LIB="/usr/share/pve-manager/js/pvemanagerlib.js"
PROXMOX_LIB="/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js"

# ---- Backups ----
PVE_CSS_BAK="${PVE_CSS}.bak"
PVE_TPL_BAK="${PVE_TPL}.bak"
PVE_UI_JS_BAK="${PVE_UI_JS}.bak"
PVE_MGR_LIB_BAK="${PVE_MGR_LIB}.bak"
PROXMOX_LIB_BAK="${PROXMOX_LIB}.bak"

# ---- Restore Choices ----

echo ""

read -p "🎨 Revert the Anime Theme from ext6-pve.css? [y/N]: " undo_css
if [[ "$undo_css" =~ ^[Yy]$ ]]; then
  if [[ -f "$PVE_CSS_BAK" ]]; then
    cp "$PVE_CSS_BAK" "$PVE_CSS"
    echo "✅ Restored original CSS (ext6-pve.css)"
  else
    echo "⚠️ Backup for ext6-pve.css not found, skipping"
  fi
fi

read -p "🧾 Revert changes to login HTML (index.html.tpl)? [y/N]: " undo_html
if [[ "$undo_html" =~ ^[Yy]$ ]]; then
  if [[ -f "$PVE_TPL_BAK" ]]; then
    cp "$PVE_TPL_BAK" "$PVE_TPL"
    echo "✅ Restored original index.html.tpl"
  else
    echo "⚠️ Backup for index.html.tpl not found, skipping"
  fi
fi

read -p "📦 Revert injected theme from JavaScript (pve-ui.js)? [y/N]: " undo_js
if [[ "$undo_js" =~ ^[Yy]$ ]]; then
  if [[ -f "$PVE_UI_JS_BAK" ]]; then
    cp "$PVE_UI_JS_BAK" "$PVE_UI_JS"
    echo "✅ Restored original pve-ui.js"
  else
    echo "⚠️ Backup for pve-ui.js not found, skipping"
  fi
fi

read -p "🧠 Revert patch to pvemanagerlib.js (nag workaround)? [y/N]: " undo_mgr
if [[ "$undo_mgr" =~ ^[Yy]$ ]]; then
  if [[ -f "$PVE_MGR_LIB_BAK" ]]; then
    cp "$PVE_MGR_LIB_BAK" "$PVE_MGR_LIB"
    echo "✅ Restored original pvemanagerlib.js"
  else
    echo "⚠️ Backup for pvemanagerlib.js not found, skipping"
  fi
fi

read -p "🚫 Revert the no-subscription nag fix (proxmoxlib.js + apt.conf)? [y/N]: " undo_nag
if [[ "$undo_nag" =~ ^[Yy]$ ]]; then
  if [[ -f "$PROXMOX_LIB_BAK" ]]; then
    cp "$PROXMOX_LIB_BAK" "$PROXMOX_LIB"
    echo "✅ Restored original proxmoxlib.js"
  else
    echo "⚠️ Backup for proxmoxlib.js not found, skipping"
  fi

  if [[ -f /etc/apt/apt.conf.d/no-nag-script ]]; then
    rm -f /etc/apt/apt.conf.d/no-nag-script
    echo "🗑️  Removed no-nag apt.conf script"
  fi

  echo "📦 Reinstalling proxmox-widget-toolkit to restore JS patch..."
  apt --reinstall install proxmox-widget-toolkit -y >/dev/null
  echo "✅ proxmox-widget-toolkit restored"
fi

echo ""

# ---- Restart Web UI ----
read -p "🔁 Restart Proxmox Web Interface to apply changes? [Y/n]: " restart
if [[ ! "$restart" =~ ^[Nn]$ ]]; then
  systemctl restart pveproxy
  echo "🔁 Web interface restarted"
else
  echo "⏩ Skipped restart. Restart manually if needed."
fi

echo "🧼 Uninstallation complete. Clear your browser cache to fully refresh the UI."
