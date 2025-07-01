#!/bin/bash

set -e

echo "🌸 Proxmox Anime Theme Installer (ARM + x86_64 compatible) with Optional No Subscription Script!"

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

  echo "🔄 Updating package lists..."
  apt update -y

  read -p "🔁 Do you want to upgrade all packages now? [y/N]: " do_upgrade
  if [[ "$do_upgrade" =~ ^[Yy]$ ]]; then
    apt dist-upgrade -y
  else
    echo "⏩ Skipping package upgrade"
  fi

  read -p "❌ Do you want to disable the 'No Valid Subscription' popup now? [y/N]: " disable_nag
  if [[ "$disable_nag" =~ ^[Yy]$ ]]; then
    JS_PATH=""
    if [[ -f /usr/share/pve-manager/js/pvemanagerlib.js ]]; then
      JS_PATH="/usr/share/pve-manager/js/pvemanagerlib.js"
    elif [[ -f /usr/share/pve-manager/ext6/pvemanagerlib.js ]]; then
      JS_PATH="/usr/share/pve-manager/ext6/pvemanagerlib.js"
    fi

    if [[ -n "$JS_PATH" ]]; then
      echo "🧠 Disabling nag screen in $JS_PATH..."
      cp -n "$JS_PATH" "$JS_PATH.bak"

      if grep -q 'data.status !== "Active"' "$JS_PATH"; then
        sed -i.bak '/data.status !== "Active"/ s/^/\/\/ /' "$JS_PATH"
        echo "✅ Nag screen disabled."
      else
        echo "⚠️ Nag screen patch already applied or not found."
      fi
    else
      echo "❌ Could not find pvemanagerlib.js to patch."
    fi
  else
    echo "⏩ Skipping nag popup patch."
  fi

  echo "✅ Proxmox is now set to no-subscription mode with optional patches."
else
  echo "⏩ Skipping no-subscription setup and nag patch."
fi

echo ""

# ---- Config ----
THEME_REPO="https://github.com/arty01238/ani-prox-ve.git"
TMP_DIR="/tmp/ani-prox-ve"
THEME_CSS="$TMP_DIR/anime-theme.css"

PVE_CSS_ARM="/usr/share/pve-manager/css/ext6-pve.css"
PVE_TPL="/usr/share/pve-manager/index.html.tpl"
PVE_UI_JS="/usr/share/pve-manager/ext6/pve-ui.js"

NEEDED_CMDS=("git" "systemctl" "tee" "grep" "cat" "sed" "sudo")

# ---- Install missing dependencies ----
echo "🔍 Checking required packages..."
apt update -qq
for cmd in "${NEEDED_CMDS[@]}"; do
  if ! command -v "$cmd" &> /dev/null; then
    echo "📦 Installing missing dependency: $cmd"
    apt install -y "$cmd"
  fi
done

# ---- Clone the theme repo ----
echo "📥 Downloading theme from GitHub..."
rm -rf "$TMP_DIR"
git clone --depth=1 "$THEME_REPO" "$TMP_DIR"

if [[ ! -f "$THEME_CSS" ]]; then
  echo "❌ anime-theme.css not found in the repo."
  exit 1
fi

# ---- Apply to ext6-pve.css (ARM installs) ----
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

# ---- Apply to index.html.tpl (used by Pi installs and x86_64 login) ----
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

# ---- Apply to pve-ui.js (x86_64 installs with ext6) ----
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

# ---- Restart Proxmox Web UI ----
echo "🔁 Restarting pveproxy..."
systemctl restart pveproxy

# ---- Done ----
echo "✅ Anime theme applied successfully!"
echo "🧼 Clear browser cache or use Incognito to see changes."
