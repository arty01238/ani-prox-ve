# Proxmox VE Custom Theme: ChibiDreams VE
![image](https://github.com/user-attachments/assets/cc971b45-0e9e-41aa-bfb3-c267865ba063)

This guide explains how to install the "ChibiDreams VE" custom theme on your Proxmox VE server. This method applies the theme server-side, meaning it will be visible to anyone accessing this Proxmox VE instance via a web browser.

**Theme Version:** 1.0 (Based on PVE 8.x CSS structure)
**Theme CSS File:** `chibidreams-theme.css` (You need to create this file with the CSS content provided separately)

## Table of Contents

1.  [Important Considerations](#important-considerations)
    *   [Persistence Across Updates](#persistence-across-updates)
    *   [Backup Your Work](#backup-your-work)
2.  [Prerequisites](#prerequisites)
3.  [Installation Steps](#installation-steps)
    *   [Step 1: Create the Custom CSS File](#step-1-create-the-custom-css-file)
    *   [Step 2: Backup the Original Template File](#step-2-backup-the-original-template-file)
    *   [Step 3: Modify the Proxmox VE HTML Template](#step-3-modify-the-proxmox-ve-html-template)
    *   [Step 4: Clear Browser Cache](#step-4-clear-browser-cache)
4.  [Maintenance After Proxmox VE Updates](#maintenance-after-proxmox-ve-updates)
5.  [Troubleshooting](#troubleshooting)
6.  [Uninstallation](#uninstallation)

---

## 1. Important Considerations

### Persistence Across Updates

*   **Custom CSS File (`chibidreams-theme.css`):** Storing this file in a custom directory (e.g., `/usr/share/pve-manager/css/custom/`) generally helps it survive Proxmox VE package updates. However, it's not guaranteed against major system restructures.
*   **HTML Template Modification (`index.html.tpl`):** The modification made to Proxmox VE's core HTML template file (`index.html.tpl`) **WILL LIKELY BE OVERWRITTEN** when the `pve-manager` package (or related toolkit packages) is updated. This means you will need to re-apply this modification after such updates.

### Backup Your Work

*   **Always keep a backup of your `chibidreams-theme.css` file in a safe, off-server location.**
*   **Backup the original `index.html.tpl` file before modifying it.**

---

## 2. Prerequisites

*   SSH access to your Proxmox VE server with root privileges (or a user with `sudo` rights).
*   A text editor available on the server (e.g., `nano`, `vim`).
*   The complete CSS code for the `chibidreams-theme.css` file.

---

## 3. Installation Steps

### Step 1: Create the Custom CSS File

1.  Connect to your Proxmox VE server via SSH.
2.  Create a dedicated directory for your custom theme CSS if it doesn't exist. This helps organize your custom files.
    ```bash
    sudo mkdir -p /usr/share/pve-manager/css/custom/
    ```
3.  Create and open your custom CSS file for editing.
    ```bash
    sudo nano /usr/share/pve-manager/css/custom/chibidreams-theme.css
    ```
4.  Paste the entire CSS code for your "ChibiDreams VE" theme into this file.
5.  Save the file and exit the editor (for `nano`: `Ctrl+X`, then `Y`, then `Enter`).

### Step 2: Backup the Original Template File

Before modifying any core Proxmox VE files, it's crucial to create a backup. The primary file we'll modify is `index.html.tpl`.

```bash
sudo cp /usr/share/pve-manager/root/index.html.tpl /usr/share/pve-manager/root/index.html.tpl.bak
```
This creates a backup named `index.html.tpl.bak` in the same directory.

### Step 3: Modify the Proxmox VE HTML Template

We need to tell Proxmox VE to load our custom CSS file. We do this by adding a `<link>` tag to its main HTML template.

1.  Open the `index.html.tpl` file for editing:
    ```bash
    sudo nano /usr/share/pve-manager/root/index.html.tpl
    ```
2.  Locate the `<head>` section of the HTML. You'll see other `<link rel="stylesheet" ...>` tags.
3.  Add the following line just before the closing `</head>` tag or near the other CSS links:
    ```html
    <link rel="stylesheet" type="text/css" href="/pve2/css/custom/chibidreams-theme.css?ver=<%= ($pveversion || '') %>">
    ```
    *   **Explanation of the line:**
        *   `href="/pve2/css/custom/chibidreams-theme.css"`: This is the web-accessible path to your custom CSS file. Proxmox VE's web server typically serves content from `/usr/share/pve-manager/` under the `/pve2/` path.
        *   `?ver=<%= ($pveversion || '') %>`: This is a template directive used by Proxmox VE to append the current PVE version to the URL. It acts as a cache-busting mechanism, ensuring browsers fetch the new CSS if the version changes (or if you manually clear cache).

4.  Your `<head>` section might look something like this (simplified example) after the change:
    ```html
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
        <title><%= ($title || 'Proxmox Virtual Environment') %></title>
        <link rel="icon" sizes="any" type="image/svg+xml" href="/pve2/images/logo/pve-favicon.svg">
        <link rel="stylesheet" type="text/css" href="/pve2/css/ext6.css">
        <!-- ... other existing CSS links ... -->
        <link rel="stylesheet" type="text/css" href="/pve2/css/custom/chibidreams-theme.css?ver=<%= ($pveversion || '') %>"> <!-- YOUR ADDED LINE -->
    </head>
    ```
5.  Save the file and exit the editor (for `nano`: `Ctrl+X`, then `Y`, then `Enter`).

### Step 4: Clear Browser Cache

Your web browser likely has cached the old Proxmox VE interface. To see the changes:
*   **Hard Refresh:** Press `Ctrl+Shift+R` (Windows/Linux) or `Cmd+Shift+R` (Mac) in your browser while on the Proxmox VE page.
*   **Clear Cache Manually:** If a hard refresh isn't enough, go into your browser's settings and clear its cache and cookies for the Proxmox VE domain.

You should now see your "ChibiDreams VE" theme applied.

---

## 4. Maintenance After Proxmox VE Updates

As mentioned, when Proxmox VE updates core packages like `pve-manager`, the `index.html.tpl` file is likely to be overwritten with the new default version, removing your custom `<link>` tag.

**After any significant Proxmox VE update, you will likely need to:**

1.  **Check your theme:** Access the Proxmox VE interface. If the theme is gone, proceed to step 2.
2.  **Re-apply the modification to `index.html.tpl`:**
    *   You can manually re-edit the file as described in [Step 3](#step-3-modify-the-proxmox-ve-html-template).
    *   **Always backup the new `index.html.tpl` provided by the update before re-modifying it.** Compare it with your previous backup (`index.html.tpl.bak`) to see if there are other important changes in the template you need to be aware of, though usually, just re-adding your `<link>` tag is sufficient.
3.  **Clear browser cache again.**

Your custom CSS file (`/usr/share/pve-manager/css/custom/chibidreams-theme.css`) should typically remain untouched, but it's wise to verify its presence too.

---

## 5. Troubleshooting

*   **Theme not applying:**
    *   Double-check the path in the `<link>` tag in `index.html.tpl`.
    *   Ensure `chibidreams-theme.css` exists at `/usr/share/pve-manager/css/custom/chibidreams-theme.css` and has the correct CSS content.
    *   Check file permissions (though default `mkdir` and `nano` with `sudo` should be fine).
    *   Clear browser cache *very thoroughly*.
    *   Use your browser's developer tools (Network tab) to see if `chibidreams-theme.css` is being requested and if it's loading correctly (Status 200 OK). Check for typos in the filename or path.
*   **Parts of the theme not working:**
    *   The CSS selectors in your theme might be too specific or no longer match the HTML structure of your current PVE version. This is common with complex web UIs. You may need to update your CSS selectors using your browser's developer tools to inspect the elements.

---

## 6. Uninstallation

To remove the custom theme:

1.  **Remove the custom CSS link from the template:**
    *   Edit `/usr/share/pve-manager/root/index.html.tpl`.
    *   Delete the line you added:
        ```html
        <link rel="stylesheet" type="text/css" href="/pve2/css/custom/chibidreams-theme.css?ver=<%= ($pveversion || '') %>">
        ```
    *   Alternatively, restore your backup:
        ```bash
        sudo cp /usr/share/pve-manager/root/index.html.tpl.bak /usr/share/pve-manager/root/index.html.tpl
        ```
2.  **(Optional) Delete your custom CSS file and directory:**
    ```bash
    sudo rm /usr/share/pve-manager/css/custom/chibidreams-theme.css
    sudo rmdir /usr/share/pve-manager/css/custom/ # Only if the directory is empty and you created it
    ```
3.  **Clear browser cache thoroughly.**

This will revert Proxmox VE to its default appearance.

## More screenshots

![image](https://github.com/user-attachments/assets/896ca96d-d8dd-4948-9cc3-7be2696a272d)
![image](https://github.com/user-attachments/assets/b8bd578d-05d2-4d1d-aecf-907e4f1623c6)
![image](https://github.com/user-attachments/assets/307d6503-4eeb-4593-b68b-bdc616e2adf6)
![image](https://github.com/user-attachments/assets/21fafe39-ec85-4fe5-81be-8dc98ca28ef2)
![image](https://github.com/user-attachments/assets/384f7d21-8837-474c-9c96-08dddbcbe786)


