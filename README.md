<p align="center">
  <img src="https://github.com/Spegeli/homeassistant-app-bambuddy/blob/main/logo.png?raw=true" alt="Bambuddy Logo" width="300">
</p>

# 🚀 Bambuddy – Home Assistant App

<p align="center">
  <a href="https://github.com/maziggy/bambuddy">Bambuddy</a>, delivered as a first-class Home Assistant App for easy installation and updates.
</p>
<p align="center">
  <strong>Self-hosted print archive and management system for Bambu Lab 3D printers</strong>
</p>
<p align="center">
  <img src="https://img.shields.io/badge/aarch64-yes-green.svg">
  <img src="https://img.shields.io/badge/amd64-yes-green.svg">
  <img src="https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/Spegeli/homeassistant-app-bambuddy/main/bambuddy/config.yaml&query=$.version&label=stable&color=blue">
  <img src="https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/Spegeli/homeassistant-app-bambuddy/main/bambuddy-beta/config.yaml&query=$.version&label=beta&color=orange">
  <img src="https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/Spegeli/homeassistant-app-bambuddy/main/bambuddy-daily/config.yaml&query=$.version&label=daily&color=purple">
</p>

---

## 📦 Installation

1. In Home Assistant, navigate to:
   **Settings → Apps → App Store**

2. Add the following repository:

   [![Install Add-on](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https://github.com/Spegeli/homeassistant-app-bambuddy)

   Or add it manually:
   `https://github.com/Spegeli/homeassistant-app-bambuddy`

3. Once the repository is added, you'll find **three versions** of BamBuddy available:

   | Version | Description |
   |---|---|
   | **BamBuddy** | ✅ Stable release — recommended for most users |
   | **BamBuddy (Beta)** | 🧪 Beta release — newer features, may contain bugs |
   | **BamBuddy (Daily)** | 🔬 Daily build — cutting-edge, least stable |

4. Install your preferred version and follow the configuration steps.

---

## 🔄 Automatic Updates
 
This App includes automatic update tracking for all three versions (Stable, Beta and Daily).
 
Updates are checked **every hour**. As soon as a new BamBuddy release is available, it will automatically appear in Home Assistant — ready to install with a single click, just like any other App update.
 
No manual intervention required. 🎉

---

## 💾 Data Persistence

All BamBuddy data (print archive, settings, logs) is stored persistently in the Home Assistant `/data` directory. Your data is **safe across updates, restarts, and reinstalls** — uninstalling and reinstalling the App will not cause any data loss.

---

## ⚠️ Known Limitations
 
### HA Ingress — Not Supported
 
HA Ingress is currently **not supported**.
 
**Why:** Bambuddy's frontend SPA makes API calls to an absolute path (`/api/v1/...`). HA Ingress serves the addon under a rotating per-session subpath (`/api/hassio_ingress/<token>/`), which means API calls never reach Bambuddy. This requires a fix in Bambuddy core.
 
---
 
### Embedding via Webpage Panel — LAN only
 
As a workaround, Bambuddy can be embedded inside the Home Assistant dashboard using a **Webpage Panel** or **Webpage Card**:
 
1. In Home Assistant go to **Settings → Dashboards** (or edit your dashboard)
2. Add a **Webpage Card** or **Webpage Panel**
3. Set the URL to:
   ```
   http://<your-ha-ip>:8000
   ```
   Example: `http://192.168.178.3:8000`
4. Under the addon configuration, add your HA URL to **Allowed Origin URLs**:
   ```
   http://<your-ha-ip>:8123
   http://homeassistant.local:8123
   ```
 
**Limitations of this approach:**
- Works on **LAN only** — not available when accessing HA remotely via HTTPS (Nabu Casa, custom domain, etc.)
- When accessing HA over HTTPS externally, browsers block HTTP iframes (mixed content policy)
 
Full Ingress support will be added once the upstream API path issue is resolved.

---

## ℹ️ Disclaimer
 
This is **not** an official release by the BamBuddy developer. This project simply packages [BamBuddy](https://github.com/maziggy/bambuddy) as a native Home Assistant App for easy installation and updates.
 
I am not affiliated with or the developer of BamBuddy itself — therefore I am unable to provide support for BamBuddy-related issues, bugs, or feature requests. For anything related to BamBuddy, please refer to the original project:
 
👉 **[github.com/maziggy/bambuddy](https://github.com/maziggy/bambuddy)**
 
Support provided here is limited to the **Home Assistant App packaging and its installation** only.
