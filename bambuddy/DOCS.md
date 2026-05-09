# Bambuddy – Documentation

## Configuration Options

### Debug Mode

Enables verbose debug logging for Bambuddy. Useful when troubleshooting issues or reporting bugs.

| Option | Type | Default |
|--------|------|---------|
| `debug` | `bool` | `false` |

**When to enable:** Only enable debug mode when actively diagnosing a problem. Debug logging can produce a large amount of output and may impact performance.

---

## Data Persistence

All data (print archive, settings, logs) is stored persistently in the Home Assistant `/data` directory. Your data is safe across updates, restarts, and reinstalls.

---

## Support

For issues related to the **Home Assistant App packaging**, open an issue at:
👉 [github.com/Spegeli/homeassistant-app-bambuddy](https://github.com/Spegeli/homeassistant-app-bambuddy)

For issues related to **BamBuddy itself**, please refer to the upstream project:
👉 [github.com/maziggy/bambuddy](https://github.com/maziggy/bambuddy)
