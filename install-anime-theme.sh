#!/bin/bash

set -e

echo "🌸 Proxmox Anime Theme Installer (ARM + x86_64 compatible) with Optional No-Subscription Setup!"

# ---- Safety Check ----
if [[ $EUID -ne 0 ]]; then
  echo "❌ Please run this script as root."
  exit 1
fi

# ---- Proxmox Prep Options (No-Subscription Setup + Disable Nag) ----
read -p "🛠️  Do you want to disable the enterprise repo and enable the community no-subscription repo? [y/N]: " disable_enterprise

if [[ "$disable_enterprise" =~ ^[Yy]$ ]]; then
  echo "📦 Disabling Proxmox enterprise repo..."
  if [[ -f /etc/apt/sources.list.d/pve-enterprise.list ]]; then
    sed -i 's/^/#/' /etc/apt/sources.list.d/pve-enterprise.list
    echo "✅ Commented out enterprise repo"
  else
    echo "ℹ️ Enterprise repo file not found, skipping"
  fi

  echo "📦 Enabling no-subscription repo..."
  echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" > /etc/apt/sources.list.d/pve-no-subscription.list

  echo "📦 Ensuring Debian security repo is present..."
  if ! grep -q 'security.debian.org' /etc/apt/sources.list; then
    echo "deb http://security.debian.org/debian-security bookworm-security main contrib" >> /etc/apt/sources.list
    echo "✅ Added Debian security repo"
  fi
fi

# ---- Optional Ceph Fix ----
read -p "🐙 Do you want to fix Ceph to use the community repo instead of the enterprise one? [y/N]: " fix_ceph
if [[ "$fix_ceph" =~ ^[Yy]$ ]]; then
  echo "🧠 Checking for Ceph repository..."
  if [[ -f /etc/apt/sources.list.d/ceph.list ]]; then
    echo "📦 Processing /etc/apt/sources.list.d/ceph.list..."
    if grep -q 'enterprise.proxmox.com' /etc/apt/sources.list.d/ceph.list; then
      sed -i 's|^deb .*enterprise.proxmox.com.*|# &|' /etc/apt/sources.list.d/ceph.list
      echo "deb http://download.proxmox.com/debian/ceph-quincy bookworm no-subscription" >> /etc/apt/sources.list.d/ceph.list
      echo "✅ Ceph community repo added."
    fi
  fi
fi

# ---- Optional Upgrade ----
read -p "🔁 Do you want to upgrade all packages now? [y/N]: " do_upgrade
if [[ "$do_upgrade" =~ ^[Yy]$ ]]; then
  apt update && apt dist-upgrade -y
else
  echo "⏩ Skipping package upgrade"
fi

read -p "❌ Do you want to disable the 'No Valid Subscription' popup now? [y/N]: " disable_nag
if [[ "$disable_nag" =~ ^[Yy]$ ]]; then
  echo "🧠 Searching for the correct file to patch..."

  NAG_PATCHED=false
  FILES_TO_CHECK=(
    "/usr/share/pve-manager/ext6/pve-ui.js"
    "/usr/share/pve-manager/js/pvemanagerlib.js"
    "/usr/share/pve-manager/index.html.tpl"
  )

  for FILE in "${FILES_TO_CHECK[@]}"; do
    if [[ -f "$FILE" && "$NAG_PATCHED" = false ]]; then
      echo "🔧 Checking $FILE..."
      cp -n "$FILE" "$FILE.bak"

      # Safely disable the nag popup
      if grep -q "No valid subscription" "$FILE"; then
        sed -i 's/.*No valid subscription.*/\/\/ No valid subscription popup removed by anime theme installer/' "$FILE"
        echo "✅ Patched $FILE"
        NAG_PATCHED=true
      else
        echo "⚠️ No nag popup found in $FILE (already patched?)"
      fi
    fi
  done

  if [[ "$NAG_PATCHED" = false ]]; then
    echo "❌ Could not find any known nag popup to patch. Your system may already be clean."
  fi
else
  echo "⏩ Skipping nag popup patch."
fi

# ---- Theme Install Begins ----
THEME_REPO="https://github.com/arty01238/ani-prox-ve.git"
TMP_DIR="/tmp/ani-prox-ve"
THEME_CSS="$TMP_DIR/anime-theme.css"
PVE_CSS="/usr/share/pve-manager/css/ext6-pve.css"
PVE_TPL="/usr/share/pve-manager/index.html.tpl"
PVE_UI="/usr/share/pve-manager/ext6/pve-ui.js"
NEEDED_CMDS=(git curl tee sed awk)

echo "🔍 Checking required packages..."
apt update -qq
for cmd in "${NEEDED_CMDS[@]}"; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "📦 Installing $cmd..."
    apt install -y "$cmd"
  fi
done

echo "📅 Downloading theme from GitHub..."
rm -rf "$TMP_DIR"
git clone --depth=1 "$THEME_REPO" "$TMP_DIR"

if [[ ! -f "$THEME_CSS" ]]; then
  echo "❌ anime-theme.css not found in the repo."
  exit 1
fi

if [[ -f "$PVE_CSS" ]]; then
  echo "🎨 Applying theme to CSS..."
  cp -n "$PVE_CSS" "$PVE_CSS.bak"
  if ! grep -q "/* Anime Theme Injection */" "$PVE_CSS"; then
    echo -e "\n/* Anime Theme Injection */" >> "$PVE_CSS"
    cat "$THEME_CSS" >> "$PVE_CSS"
    echo "✅ CSS themed"
  fi
fi

if [[ -f "$PVE_TPL" ]]; then
  echo "🎨 Injecting theme into index.html.tpl..."
  cp -n "$PVE_TPL" "$PVE_TPL.bak"
  if ! grep -q "/* Anime Theme Injection */" "$PVE_TPL"; then
    STYLE="<style> /* Anime Theme Injection */ $(cat "$THEME_CSS") </style>"
    awk -v insert="$STYLE" '/<head>/ && !x { print; print insert; x=1; next } 1' "$PVE_TPL" > "${PVE_TPL}.patched"
    mv "${PVE_TPL}.patched" "$PVE_TPL"
    echo "✅ HTML patched"
  fi
fi

if [[ -f "$PVE_UI" ]]; then
  echo "🎨 Injecting theme into pve-ui.js..."
  cp -n "$PVE_UI" "$PVE_UI.bak"
  if ! grep -q "/* Anime Theme Injection */" "$PVE_UI"; then
    echo -e "\n/* Anime Theme Injection */" >> "$PVE_UI"
    cat "$THEME_CSS" >> "$PVE_UI"
    echo "✅ JS themed"
  fi
fi

systemctl restart pveproxy

echo "✅ Anime theme applied successfully!"
echo "🪜 Clear browser cache or use Incognito to see changes."
