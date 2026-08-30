## 1.2.5.5

**Bambuddy 1.2.5.5 Hotfix**

**What this is**

A hotfix for one regression in 1.2.5.4: on some installs every camera stopped working at once. Nothing else in 1.2.5.4 is changed. If your cameras work, you are not affected and this is an optional update - but read "Are you affected?" below anyway, because the same misconfiguration carries a second, silent risk that has nothing to do with cameras.

Two supporting changes ship alongside the fix so the condition cannot stay hidden on anyone's machine: Bambuddy now says so at startup when it finds itself on the wrong event loop, and the update scripts repair a service file that predates the flag which prevents it.

**Are you affected?**

Symptoms: live view shows "Connection lost" on every RTSP printer at once - X1, X1C, X1E, X2D, H2C, H2D, H2DPRO, H2S, P2S - and Settings > Connection Diagnostic reports "capture_exception" at 0 ms while network reachability passes at 1 ms. Snapshots, timelapse frames and the finish photo fail with it. A1, A1 mini, P1P and P1S use a different camera protocol and were never affected.

That 0 ms is the tell: the failure happened before a socket was opened.

Bambuddy is developed, tested and shipped on Python's own asyncio event loop, and every launch path in this project pins it - the Docker image, install.sh, the systemd unit, the launchd plist, the Windows service and the SpoolBuddy installer. What broke are the installs running a service file Bambuddy's installer did not write:

- The Proxmox VE Helper-Scripts LXC composes its own service file with no loop pinned. That is the reported case.
- Native installs created before 2026-07-05, when the flag was added. Updating has never rewritten an existing service file, so those installs never received it no matter how many times they were updated.

Docker is unaffected - the image pins the flag itself. Windows is unaffected in every case, because the alternative loop is never installed there.

To check a native install:

    systemctl show bambuddy --property=ExecStart --value | grep -o -- '--loop [a-z]*'

No output means no loop is pinned. Updating to 1.2.5.5 through update.sh adds it for you.

**Why it matters beyond cameras**

The same condition is what #1896 was about: on that loop, a Virtual Printer FTP upload can be silently truncated, acked as successful, archived and forwarded to the printer as a corrupt file. There is a backstop for that - since 0.2.5b2 a received 3MF is validated as a complete ZIP before it is accepted - but a backstop is not a reason to keep running the loop that needs it. Losing every camera at once is loud. A truncated upload is not, and shows up much later as a print failing from a file that was already corrupt when it arrived.

That is why 1.2.5.5 does not stop at the camera fix.

**Docker**

    docker compose pull
    docker compose up -d

**Native install - recommended path**

    sudo BRANCH=main /opt/bambuddy/install/update.sh

This is the path that also repairs the service file. It backs the file up first and inserts nothing but the missing flag.

**Native install - manual path**

    sudo systemctl stop bambuddy
    cd /opt/bambuddy
    sudo -u bambuddy git fetch --prune --tags --force origin
    sudo -u bambuddy git checkout main
    sudo -u bambuddy git reset --hard origin/main
    sudo /opt/bambuddy/venv/bin/pip install -r requirements.txt
    cd frontend && sudo npm i
    sudo systemctl start bambuddy

The manual path does not touch your service file. If the check above printed nothing, add "--loop asyncio" to the uvicorn command in /etc/systemd/system/bambuddy.service, then run "sudo systemctl daemon-reload" before starting.

**Proxmox VE Helper-Scripts LXC**

The community script writes its own service file and will not gain the flag from a Bambuddy update. Update Bambuddy as usual - the camera fix applies either way and your cameras will work again. To also close the upload risk, edit /etc/systemd/system/bambuddy.service, append "--loop asyncio" to the ExecStart line, then:

    systemctl daemon-reload
    systemctl restart bambuddy

**Windows install**

Download bambuddy-1.2.5.5-windows-x64-setup.exe from this release page (or the unversioned bambuddy-windows-x64-setup.exe alias). Existing Windows installs upgrade in place via the in-app Install Update flow. Windows was not affected by this regression.

**Fixed**

- Every camera stopped working on 1.2.5.4 (#3001) - The RTSPS proxy introduced in 1.2.5.4 finished by attaching its set of live connection handlers to the server object. That is legal on asyncio's server, which accepts new attributes, and an outright error on the alternative loop's server, which does not - so on those installs the proxy raised before it opened a socket and took live view, snapshots, timelapse frames and the diagnostic with it. The handler set now lives beside the server rather than on it, which both loops accept, and is held weakly so a proxy that is abandoned without a clean shutdown retires its own entry instead of leaking one. External RTSPS cameras were never affected: they caught the error and fell back to a direct connection. Reported by @Jieper001, confirmed by @JmanB52D and @hikingthunder, who also posted the first working patch.

- Two external-camera shutdown paths could leave connection handlers running past the server that owned them - introduced with the shared teardown helper in 1.2.5.4 and missed at those two call sites.

**Changed**

- Bambuddy warns at startup when it is running on the wrong event loop - one line in the log naming the loop, what it risks, and the exact flag to add. A warning and not a refusal: by the time any Bambuddy code runs the loop has already been chosen, and a server that answers requests is better than one that will not start.

- update.sh and update_macos.sh repair a service file written before the flag existed - the systemd unit or the launchd plist, while the service is stopped, so it takes effect on the same restart. The file is copied to a timestamped backup first and nothing but the flag is inserted; a hand-edited port, extra hardening and everything else stay exactly as they were. Anything that is not a plain single-line uvicorn service is described rather than edited - a wrapper script, a command split across lines, a read-only file, or a service carrying systemd drop-ins. A loop you pinned deliberately is left alone.

**Notes for anyone who patched this by hand**

If you edited camera.py yourself from the issue thread, the update overwrites it with the shipped fix and nothing is left behind. The shipped version differs in one respect worth knowing: it keys the handler registry weakly by server rather than by object id, because object ids are recycled and a stale entry could otherwise be handed to an unrelated server later on.

