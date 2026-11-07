## 1.3.1b1-daily.20261107

> [!NOTE]
> This is a **daily beta build** (2026-11-07). It contains the latest fixes and improvements but may have undiscovered issues.
>
> **Docker users:** Update by pulling the new image:
> ```
> docker pull ghcr.io/maziggy/bambuddy:daily
# or
docker pull maziggy/bambuddy:daily
> ```
>
> **Tip:** Use [Watchtower](https://watchtower.nickfedor.com) (image `nickfedor/watchtower`) to automatically update when new daily builds are pushed.

---

### Added
- **Cam Wall tiles show temperatures and finish time, and can pause, stop and switch the light (#3479, sponsor vote Q4 2026)** — With the **Full** status overlay, every connected tile shows its nozzle (both on a dual-nozzle printer), bed and chamber temperatures, and a printing tile adds its finish time beside the time left. Hovering over a tile shows **Pause/Resume** and **Stop**, with the same confirmations as the printer card, and a **chamber light** switch; **Tile controls: Always** in the wall settings keeps them on screen, and a touch screen always shows them. The controls need the `printers:control` permission; a user without it, an offline printer and a Cam Wall token (kiosk) wall get none.
### Changed
- **"Any model" jobs go to the printer with the fewest print hours (#3480, sponsor vote Q4 2026)** — When several printers of a model can take a job, the queue used to pick the first one in its list, so on a farm the same printer got most of the work. It now picks the one with the fewest print hours (the Maintenance counter, including baseline hours entered there), so jobs and wear spread across the farm. Preferred colours still come first, and the queue powers on the least used printer too when it has to switch one on with an Auto Power On plug.
### Fixed
- **The log says which auto-archive switch skipped a print (#3477, reported by Fuzzylog2x)** — Since 1.3.0 the global **Auto-archive prints** switch (Settings > General > Archive Settings) takes effect for prints started outside Bambuddy. Before, it was saved and never read, so an install upgraded with it off stopped archiving, and the statistics stopped updating. The log only said "auto_archive: False", the same as for a printer's own switch. It now names the global switch or the printer, whichever turned archiving off.
- **A camera window no longer opens a dozen streams to the printer at once (#3431, reported by buffdriver)** — When the floating camera window was open while the page loaded (after a refresh, for example), Bambuddy opened about twenty camera streams for it. Only one was shown. The browser kept the rest open until the tab was closed, and they filled its six connections to the server. The page started each stream while still preparing to draw the window. It prepared the window several times before showing it, and every attempt left a stream behind. Streams now start only once the window is on the page. The camera page, the camera wall and the stream overlay start their streams the same way.
- **A printer whose file service hangs during a print is no longer asked again and again until it refuses every upload (#3474, reported by F9mm)** — When the card could not be read at print start, the timelapse baseline was read again every two minutes for the whole print, and each round walked the card twice: up to eight new FTPS connections, each hanging for 30 s against a hung printer. An H2S kept a session for every one of them, then answered every connection with "421 There are too many connections", and no queued job could reach it until the printer was restarted. The card is now read once per round. It is read again only while the print records a timelapse, the wait doubles after each failed round (up to 30 minutes), and it stops after five. A connection or listing that times out now pauses the background timelapse scans of that printer for five minutes. Opening files and sending prints are not held up by this. A printer that answers "421 too many connections" now gets its own message in the queue, saying it may need a restart, instead of "Bambuddy will retry automatically". Wiki updated.
### Security
