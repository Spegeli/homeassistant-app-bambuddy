# Bambuddy (Beta) – Documentation

## Configuration Options

### Trusted Frame Origins

A list of URLs that are allowed to embed Bambuddy in an iframe. Required when using a **Webpage Card** or **Webpage Panel** inside the Home Assistant dashboard.

| Option | Type | Default |
|--------|------|---------|
| `trusted_frame_origins` | `list of str` | `["http://homeassistant.local:8123"]` |

**Format:** Each entry must be a full origin — protocol, hostname, and port (if non-standard). Do not include a trailing slash or path.

**Examples:**
```
http://homeassistant.local:8123
http://192.168.178.3:8123
https://my-ha-instance.example.com
```

Add every origin from which you access Home Assistant. If you access HA from multiple addresses (local IP, local hostname, external domain), add all of them.

> **Note:** iFrame embedding via an HTTPS origin into an HTTP Bambuddy instance (port 8000) will be blocked by the browser due to mixed content policy. This approach works reliably on LAN with HTTP only.

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
| 6000 | TCP | File transfer tunnel (TLS) |
| 322 | TCP | RTSP camera (X1 / H2 / P2) |
| 2024–2026 | TCP | Proprietary slicer ports (A1 / P1S) |
| 50000–50100 | TCP | FTP passive data transfers |

> **⚠️ Potential conflicts:** These ports are only bound when a Virtual Printer is active in BamBuddy. If another Home Assistant App or service already occupies one of these ports, the Virtual Printer will fail to start. The most common conflict is **port 8883** with the **Mosquitto MQTT Broker** Add-on. Check your running services before enabling a Virtual Printer.

---

## Data Persistence

All data (print archive, settings, logs) is stored persistently in the Home Assistant `/data` directory. Your data is safe across updates and restarts. When uninstalling, Home Assistant will ask whether to remove the app data as well — if you keep it, your data will still be there after a reinstall.

---

## Support

For issues related to the **Home Assistant App packaging**, open an issue at:
👉 [github.com/Spegeli/homeassistant-app-bambuddy](https://github.com/Spegeli/homeassistant-app-bambuddy)

For issues related to **BamBuddy itself**, please refer to the upstream project:
👉 [github.com/maziggy/bambuddy](https://github.com/maziggy/bambuddy)
