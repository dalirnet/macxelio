# Settings

Open settings with **⌘,** or from the menu bar.

## Proxy Server

- **Test Server** — the endpoint used for connectivity checks. Pick the one that best reflects what you care about reaching.
- **Allow LAN** — let other devices on your local network use Macxelio's proxy.
- **HTTP Port** — the local port for the HTTP/HTTPS proxy (default `3128`).
- **SOCKS Port** — the local port for the SOCKS proxy (default `1080`).

Changing a port restarts the local proxy automatically; if [System Proxy](system.md) is on, it's re-applied to the new port.

## DNS Server

- **Primary DNS** — your main DNS server (for example `8.8.8.8`).
- **Secondary DNS** — a fallback DNS server (for example `1.1.1.1`).

These are used when [System DNS](system.md) is enabled.

## Config folder

Use the folder button in Settings to open Macxelio's config folder, where your proxies, rules, hosts, and settings are stored as JSON. Handy for backups or inspecting the generated Xray config.
