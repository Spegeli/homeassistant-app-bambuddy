# Bambuddy (Beta) - Documentation

## Configuration Options

### Trusted Frame Origins

A list of URLs that are allowed to embed Bambuddy in an iframe. Required when using a **Webpage Card** or **Webpage Panel** inside the Home Assistant dashboard.

| Option | Type | Default |
|--------|------|---------|
| `trusted_frame_origins` | `list of str` | `["http://homeassistant.local:8123"]` |

**Format:** Each entry must be a full origin - protocol, hostname, and port (if non-standard). Do not include a trailing slash or path.

**Examples:**
```
http://homeassistant.local:8123
http://192.168.178.3:8123
https://my-ha-instance.example.com
```

Add every origin from which you access Home Assistant. If you access HA from multiple addresses (local IP, local hostname, external domain), add all of them.

> **Note:** iFrame embedding via an HTTPS origin into an HTTP Bambuddy instance (port 8000) will be blocked by the browser due to mixed content policy. This approach works reliably on LAN with HTTP only.

---

### Network Storage (External Folders)

BamBuddy's File Manager supports linking external folders (e.g. a NAS or USB drive) as external roots. In Home Assistant, this is done by adding network storage via HA and then enabling the corresponding mount in the add-on configuration.

| Option | Type | Default |
|--------|------|---------|
| `enable_share` | `bool` | `false` |
| `enable_media` | `bool` | `false` |

**When to use which:**
- **Share** (`enable_share`): For network storage added as **"Freigabe"** (Share) type in HA - accessible at `/share/[name]` in BamBuddy
- **Media** (`enable_media`): For network storage added as **"Medien"** (Media) type in HA - accessible at `/media/[name]` in BamBuddy

**Step-by-step setup:**

**1. Add network storage in Home Assistant**

Go to **Settings -> System -> Storage -> Add Network Storage**, enter your server (IP or hostname), share name, and choose the type:
- **Freigabe** -> use `enable_share`
- **Medien** -> use `enable_media`

**2. Enable the mount in BamBuddy**

In the add-on configuration, enable **Enable Share Storage** and/or **Enable Media Storage** depending on what you added in step 1. Save and restart the add-on.

**3. Link the folder in BamBuddy**

In BamBuddy, go to **File Manager -> Link External Folder** and enter the path:
- For Share storage: `/share/[your-storage-name]`
- For Media storage: `/media/[your-storage-name]`

> **Read-only:** The mount provides read/write access by default. To prevent BamBuddy from modifying files on the network storage, enable **Nur Lesen** (Read Only) in the "Link External Folder" dialog inside BamBuddy.

> **Note:** The toggles only control whether BamBuddy can see the storage - the actual network share must be set up and connected in HA first.

---

### Self-Signed CA Certificate

If your Home Assistant instance uses a self-signed certificate (or a certificate signed by a private CA), BamBuddy will deny the HTTPS connection by default. This option lets you provide your own CA certificate so that BamBuddy can trust it.

| Option | Type | Default |
|--------|------|---------|
| `use_system_trust_store` | `bool` | `false` |
| `certfile` | `str` | `custom_ca.crt` |

**Steps:**

1. Export your CA certificate as a `.crt` file (PEM format - the public CA certificate only, no private key).
2. Open the **File Editor** in Home Assistant and navigate to:
   `addon_configs` -> `[slug]_bambuddy_beta`
3. Upload or create the certificate file there (e.g., `custom_ca.crt`).
4. In the add-on configuration, enable **Use System Trust Store** and set **CA Certificate Filename** to the filename you used in step 3.
5. Restart the add-on.

> **Note:** Only the CA certificate (public part) is required - not `fullchain.pem` and not a private key file.

> **Note:** If the certificate file is not found at startup, BamBuddy will log a warning and start anyway - without the custom CA. Check the add-on log if HTTPS connections to your HA instance fail.

---

### Debug Mode

Enables verbose debug logging for Bambuddy. Useful when troubleshooting issues or reporting bugs.

| Option | Type | Default |
|--------|------|---------|
| `debug` | `bool` | `false` |

**When to enable:** Only enable debug mode when actively diagnosing a problem. Debug logging can produce a large amount of output and may impact performance.

---

## Virtual Printer

BamBuddy supports a Virtual Printer feature that emulates a Bambu Lab printer on your network, allowing slicers to send print jobs directly to BamBuddy.

When a Virtual Printer is created and started in BamBuddy, it will bind to the following ports on your Home Assistant host:

| Port(s) | Protocol | Purpose |
|---------|----------|---------|
| 3000, 3002 | TCP | Slicer handshake / bind detection |
| 8883 | TCP | MQTT (TLS) |
| 990 | TCP | FTPS file transfer control |
| 6000 | TCP | File transfer tunnel (TLS) / Chamber Image camera (P1 / A1 / A2) |
| 322 | TCP | RTSP camera (X1 / X2 / H2 / P2) |
| 2024-2026 | TCP | Proprietary slicer ports (A1 / P1S) |
| 50000-50029 | TCP | FTP passive data transfers |

> **Warning - Potential conflicts:** These ports are only bound when a Virtual Printer is active in BamBuddy. If another Home Assistant App or service already occupies one of these ports, the Virtual Printer will fail to start. The most common conflict is **port 8883** with the **Mosquitto MQTT Broker** Add-on. Check your running services before enabling a Virtual Printer.

### Certificate Installation (Required for Slicer Connection)

To allow your slicer (Bambu Studio / OrcaSlicer) to trust the Virtual Printer's TLS certificate, you must add BamBuddy's CA certificate to the slicer once.

**1. Locate the certificate in Home Assistant**

Open the **File Editor** and navigate to:
`addon_configs` -> `[slug]_bambuddy_beta` -> `data` -> `virtual_printer` -> `certs` -> `bbl_ca.crt`

Copy the entire contents of this file (from `-----BEGIN CERTIFICATE-----` to `-----END CERTIFICATE-----`).

**2. Add the certificate to your slicer**

| Platform | Path |
|----------|------|
| Windows | `C:\Program Files\Bambu Studio\resources\cert\printer.cer` |
| macOS | `/Applications/BambuStudio.app/Contents/Resources/cert/printer.cer` |

Open the file in a text editor and **append** the copied certificate contents at the very end - after the last `-----END CERTIFICATE-----`. Do not replace existing content.

**3. Fully restart the slicer**

Close the slicer completely and reopen it. The Virtual Printer connection should now succeed.

---

## Data Persistence

All data (print archive, settings, logs) is stored persistently in the `addon_configs` directory, which is accessible via the **File Editor** in Home Assistant. Your data is safe across updates and restarts. When uninstalling, Home Assistant will ask whether to remove the app data as well - if you keep it, your data will still be there after a reinstall.

---

## Support

For issues related to the **Home Assistant App packaging**, open an issue at:
https://github.com/Spegeli/homeassistant-app-bambuddy

For issues related to **BamBuddy itself**, please refer to the upstream project:
https://github.com/maziggy/bambuddy
