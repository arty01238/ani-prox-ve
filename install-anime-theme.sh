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
      echo "📛 Disabling Ceph enterprise repo..."
      sed -i 's|^deb .*enterprise.proxmox.com.*|# &|' /etc/apt/sources.list.d/ceph.list
      echo "✅ Ceph enterprise repo commented out."
    else
      echo "ℹ️ No Ceph enterprise repo line found to comment."
    fi
    if ! grep -q 'download.proxmox.com.*ceph' /etc/apt/sources.list.d/ceph.list; then
      echo "➕ Adding Ceph no-subscription repo..."
      echo "deb http://download.proxmox.com/debian/ceph-quincy bookworm no-subscription" >> /etc/apt/sources.list.d/ceph.list
      echo "✅ Ceph community repo added."
    else
      echo "ℹ️ Ceph community repo already present."
    fi
  else
    echo "❌ Ceph is not installed or no ceph.list file found — skipping."
  fi
else
  echo "⏩ Skipping Ceph repo fix."
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

  # --- Try pve-ui.js (standard x86_64 build) ---
  if [[ -f /usr/share/pve-manager/ext6/pve-ui.js ]]; then
    FILE="/usr/share/pve-manager/ext6/pve-ui.js"
    echo "🔧 Found pve-ui.js"
    cp -n "$FILE" "$FILE.bak"
    if grep -q "No valid subscription" "$FILE"; then
      sed -i '/No valid subscription/,+10d' "$FILE"
      echo "✅ Patched $FILE"
      NAG_PATCHED=true
    else
      echo "⚠️ No nag popup found in $FILE (already patched?)"
    fi
  fi

  # --- Try pvemanagerlib.js (seen on 8.4 ARM) ---
  if [[ -f /usr/share/pve-manager/js/pvemanagerlib.js && "$NAG_PATCHED" = false ]]; then
    FILE="/usr/share/pve-manager/js/pvemanagerlib.js"
    echo "🔧 Found pvemanagerlib.js"
    cp -n "$FILE" "$FILE.bak"
    if grep -q "No valid subscription" "$FILE"; then
      sed -i '/No valid subscription/,+10d' "$FILE"
      echo "✅ Patched $FILE"
      NAG_PATCHED=true
    else
      echo "⚠️ No nag popup found in $FILE (already patched?)"
    fi
  fi

  # --- Try index.html.tpl (fallback / ultra-minimal PiMox) ---
  if [[ -f /usr/share/pve-manager/index.html.tpl && "$NAG_PATCHED" = false ]]; then
    FILE="/usr/share/pve-manager/index.html.tpl"
    echo "🔧 Checking index.html.tpl..."
    cp -n "$FILE" "$FILE.bak"
    if grep -q "No valid subscription" "$FILE"; then
      sed -i '/No valid subscription/,+5d' "$FILE"
      echo "✅ Patched $FILE"
      NAG_PATCHED=true
    else
      echo "⚠️ No nag popup found in $FILE (already patched?)"
    fi
  fi

  if [[ "$NAG_PATCHED" = false ]]; then
    echo "❌ Could not find any known nag popup to patch. Your system may already be clean."
  fi
else
  echo "⏩ Skipping nag popup patch."
fi

echo ""

# ---- Theme Install Begins ----
THEME_REPO="https://github.com/arty01238/ani-prox-ve.git"
TMP_DIR="/tmp/ani-prox-ve"
THEME_CSS="$TMP_DIR/anime-theme.css"
PVE_CSS_ARM="/usr/share/pve-manager/css/ext6-pve.css"
PVE_TPL="/usr/share/pve-manager/index.html.tpl"
PVE_UI_JS="/usr/share/pve-manager/ext6/pve-ui.js"
NEEDED_CMDS=("git" "systemctl" "tee" "grep" "cat" "sed" "awk")

echo "🔍 Checking required packages..."
apt update -qq
for cmd in "${NEEDED_CMDS[@]}"; do
  if ! command -v "$cmd" &> /dev/null; then
    echo "📦 Installing missing dependency: $cmd"
    apt install -y "$cmd"
  fi
done

echo "📥 Downloading theme from GitHub..."
rm -rf "$TMP_DIR"
git clone --depth=1 "$THEME_REPO" "$TMP_DIR"

if [[ ! -f "$THEME_CSS" ]]; then
  echo "❌ anime-theme.css not found in the repo."
  exit 1
fi

if [[ -f "$PVE_CSS_ARM" ]]; then
  echo "🎨 Applying to ext6-pve.css (ARM detected)..."
  cp -n "$PVE_CSS_ARM" "$PVE_CSS_ARM.bak"
  if ! grep -q "/* Anime Theme Injection */" "$PVE_CSS_ARM"; then
    echo -e "\n/* Anime Theme Injection */" | tee -a "$PVE_CSS_ARM" > /dev/null
    cat "$THEME_CSS" | tee -a "$PVE_CSS_ARM" > /dev/null
  else
    echo "⚠️ CSS already themed."
  fi
fi

if [[ -f "$PVE_TPL" ]]; then
  echo "🎨 Injecting into index.html.tpl..."
  cp -n "$PVE_TPL" "$PVE_TPL.bak"
  if ! grep -q "/* Anime Theme Injection */" "$PVE_TPL"; then
    TEMP_STYLE="/tmp/ani-theme-style.tmp"
    {
      echo "<style> /* Anime Theme Injection */"
      cat "$THEME_CSS"
      echo "</style>"
    } > "$TEMP_STYLE"

    awk -v insert="$(cat "$TEMP_STYLE")" '
      /<head>/ && !done {
        print;
        print insert;
        done=1;
        next;
      }
      { print }
    ' "$PVE_TPL" > "${PVE_TPL}.patched"

    mv "${PVE_TPL}.patched" "$PVE_TPL"
    rm -f "$TEMP_STYLE"
  else
    echo "⚠️ index.html.tpl already themed."
  fi
fi

if [[ -f "$PVE_UI_JS" ]]; then
  echo "🎨 Injecting into pve-ui.js (x86_64)..."
  cp -n "$PVE_UI_JS" "$PVE_UI_JS.bak"
  if ! grep -q "/* Anime Theme Injection */" "$PVE_UI_JS"; then
    echo -e "\n/* Anime Theme Injection */" | tee -a "$PVE_UI_JS" > /dev/null
    cat "$THEME_CSS" | tee -a "$PVE_UI_JS" > /dev/null
  else
    echo "⚠️ pve-ui.js already themed."
  fi
fi

echo "🔁 Restarting pveproxy..."
systemctl restart pveproxy

echo "✅ Anime theme applied successfully!"
echo "🧼 Clear browser cache or use Incognito to see changes."
