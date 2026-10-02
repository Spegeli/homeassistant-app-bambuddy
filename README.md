<p align="center">
  <img src="https://github.com/Spegeli/homeassistant-app-bambuddy/blob/main/logo.png?raw=true" alt="BamBuddy Logo" width="300">
</p>

<h1 align="center">BamBuddy – Home Assistant App</h1>

<p align="center">
  <a href="https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https://github.com/Spegeli/homeassistant-app-bambuddy"><img src="https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg" alt="Add Repository to Home Assistant"></a>
</p>
<p align="center">
  <img src="https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/Spegeli/homeassistant-app-bambuddy/main/bambuddy/config.yaml&query=$.version&label=stable&color=blue">
  <img src="https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/Spegeli/homeassistant-app-bambuddy/main/bambuddy-daily/config.yaml&query=$.version&label=daily&color=purple">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT%20%2B%20AGPL--3.0-yellow" alt="License: MIT + AGPL-3.0"></a>
</p>
<p align="center">
  <a href="https://github.com/maziggy/bambuddy">BamBuddy</a>, delivered as a first-class Home Assistant App for easy installation and updates.
</p>
<p align="center">
  <strong>Your printers. No cloud. Your rules.</strong><br>
  Self-hosted command center for Bambu Lab &mdash; from one A1 to an entire print farm.
</p>

---

## 📋 Requirements

- Home Assistant OS – apps need the Supervisor, which Home Assistant Container does not have
- Supervised installations still work, but Home Assistant ended support for them with 2025.12
- Supported architecture: aarch64 or amd64

---

## 📦 Installation

### Via button (Recommended)

[![Add Repository to Home Assistant](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https://github.com/Spegeli/homeassistant-app-bambuddy)

**One-Click Install:** Click the button above to add the repository directly to Home Assistant!

### Manually

1. In Home Assistant, go to **Settings → Apps → App Store**.
2. Click the three dots `⋮` in the top right corner and choose **Repositories**.
3. Paste the repository URL and click **Add**:
   ```text
   https://github.com/Spegeli/homeassistant-app-bambuddy
   ```

---

Once the repository is added, you'll find **two versions** of BamBuddy available:

| Version | Description |
|---|---|
| **BamBuddy** | ✅ Stable release — recommended for most users |
| **BamBuddy (Daily)** | 🔬 Daily build — cutting-edge, least stable |

Install your preferred version and follow the configuration steps.

---

## 🔄 Automatic Updates
 
This App includes automatic update tracking for both versions (Stable and Daily).
 
Updates are checked **every hour**. As soon as a new BamBuddy release is available, it will automatically appear in Home Assistant — ready to install with a single click, just like any other App update.
 
No manual intervention required. 🎉

---

## 💾 Data Persistence

All data (print archive, settings, logs) is stored persistently in the app's configuration folder (`addon_configs` → `[slug]_bambuddy` or `[slug]_bambuddy_daily`), which is accessible via the **File Editor** in Home Assistant. Your data is safe across updates and restarts.

**Uninstalling:** Home Assistant warns that the app's *private data folder* will be permanently deleted. BamBuddy stores its own data (database, print archive, logs) in the configuration folder instead, so this warning does not affect it. What decides is the switch **"Also delete the app's configuration folder (if used)"**:

- **Off** (default): your BamBuddy data stays and is used again after a reinstall.
- **On**: all BamBuddy data is permanently deleted.

The app options from the **Configuration** tab are reset to their defaults on uninstall.

---

## ⚠️ Known Limitations
 
### HA Ingress — Not Supported
 
HA Ingress is currently **not supported** and is not planned. BamBuddy's SPA architecture relies on a stable origin for API calls, routing, PWA scope, and service workers — all of which are incompatible with HA Ingress's rotating per-session subpaths. This would require extensive rewrites to BamBuddy core.
 
### Virtual Printer — Potential Port Conflicts

When using BamBuddy's Virtual Printer feature, several ports will be bound directly on the Home Assistant host. This may conflict with other installed Apps or services (most notably the **Mosquitto MQTT Broker** on port 8883).

For a full list of affected ports and details, see the **Documentation** tab of the respective App.

---

## ⚖️ Disclaimer

- **Not an official BamBuddy release.** This app is an independent community project that packages [BamBuddy](https://github.com/maziggy/bambuddy) for Home Assistant. It is not affiliated with BamBuddy's developer or with Bambu Lab.
- **Support.** Help here covers the app packaging and its installation only — report those problems in this repository's [issue tracker](https://github.com/Spegeli/homeassistant-app-bambuddy/issues). Bugs and feature requests for BamBuddy itself go to the [BamBuddy project](https://github.com/maziggy/bambuddy/issues).
- **Trademarks.** Bambu Lab, BamBuddy, their logos and other product names belong to their respective owners. They appear here only to name the software this app packages and the printers it works with.
- **Use at your own risk.** The app is provided as is, without warranty — the packaging under the MIT License, BamBuddy under the AGPL-3.0 (see [License](#-license)).

---

## 📜 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details. It covers the app packaging: the Dockerfiles, `config.yaml`, the run scripts, the workflows, the documentation and the translations.

The container images also contain **BamBuddy**, a separate work by maziggy, redistributed unmodified under the **GNU Affero General Public License v3.0** (AGPL-3.0-only). Its source code is available at [github.com/maziggy/bambuddy](https://github.com/maziggy/bambuddy).

The MIT License does not cover BamBuddy's name and logo (`logo.png` and `icon.png`), which remain their owner's (see [Disclaimer](#%EF%B8%8F-disclaimer)).
