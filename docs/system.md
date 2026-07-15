# System Proxy & DNS

By default, Macxelio runs a local proxy that apps can opt into. The **system** toggles make it apply to your whole Mac.

## System Proxy

When enabled, Macxelio points macOS's **HTTP**, **HTTPS**, and **SOCKS** proxy at itself, so every app on your Mac routes through the active proxy — not just your browser.

Toggle it from the menu bar (**System Proxy**) or in the menu's submenu. The indicator is filled when on, outline when off.

Macxelio cleans up the system proxy settings when you turn it off or quit.

## System DNS

When enabled, Macxelio runs a local DNS resolver and points your Mac at it, so the DNS servers you configure — and any host mappings — are used system-wide.

Toggle it from the menu bar (**System DNS**). Configure the servers in [Settings](settings.md):

- **Primary DNS** — a plain IP (for example `8.8.8.8`) or a DoH URL (for example `https://1.1.1.1/dns-query`)
- **Secondary DNS** — a fallback server, in the same form

Plain IP and encrypted **DNS-over-HTTPS (DoH)** servers are both supported. Any [host mappings](routing.md) you've defined are applied alongside your DNS servers.

### Administrator password

Each time you turn System DNS **on or off**, macOS asks for your **administrator password**.

To apply DNS system-wide, Macxelio runs a small DNS resolver as a system service — a launch daemon at `/Library/LaunchDaemons/com.macxelio.dns.plist`. It **installs** that service when you enable System DNS and **removes** it when you disable. Installing or removing a system service requires admin rights, so you're prompted every time — that's the only thing the password is used for.

- The prompt is macOS's standard authorization dialog — Macxelio never sees or stores your password.
- Turning System DNS off removes the helper and restores your DNS.

## Local ports

Macxelio listens locally on these ports by default — you can change them in [Settings](settings.md):

| Port   | Purpose     |
| ------ | ----------- |
| `3128` | HTTP proxy  |
| `1080` | SOCKS proxy |
