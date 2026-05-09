# Bambuddy (Beta) – Documentation

## Configuration Options

### Debug Mode

Enables verbose debug logging for Bambuddy. Useful when troubleshooting issues or reporting bugs.

| Option | Type | Default |
|--------|------|---------|
| `debug` | `bool` | `false` |

**When to enable:** Only enable debug mode when actively diagnosing a problem. Debug logging can produce a large amount of output and may impact performance.

---

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

## Data Persistence

All data (print archive, settings, logs) is stored persistently in the Home Assistant `/data` directory. Your data is safe across updates, restarts, and reinstalls.

---

## Support

For issues related to the **Home Assistant App packaging**, open an issue at:
👉 [github.com/Spegeli/homeassistant-app-bambuddy](https://github.com/Spegeli/homeassistant-app-bambuddy)

For issues related to **BamBuddy itself**, please refer to the upstream project:
👉 [github.com/maziggy/bambuddy](https://github.com/maziggy/bambuddy)
