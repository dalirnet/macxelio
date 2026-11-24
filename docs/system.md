# System Tunnel, Proxy & DNS

By default, Macxelio runs a local proxy that apps can opt into. The **system** toggles make it apply to your whole Mac:

- **System Tunnel** — route all traffic through the proxy, including UDP
- **System Proxy** — route web traffic through the proxy
- **System DNS** — use your DNS servers system-wide

## System Tunnel

System Tunnel routes **all** traffic on your Mac — TCP and UDP, from every app — through a virtual network interface (`utun99`), and sends it through the active proxy according to the [mode](routing.md). WebRTC, video calls, games, and apps that ignore proxy settings all work through the proxy, and websites only ever see the proxy's IP.

- Toggle it from the menu bar (**System Tunnel**).
- While System Tunnel is on, System Proxy is off and [System DNS](#system-dns) is on, and both are greyed out in the menu. When you turn System Tunnel off, System Proxy turns on automatically and System DNS goes back to your own setting.
- DNS queries go through the proxy, so lookups don't leak to your router or ISP.
- Local network traffic (printers, AirDrop, LAN devices) stays direct.
- System Tunnel is idle in **Direct** mode or with no proxy selected.
- System Tunnel needs Xray 26.6.27 or newer. If yours is older, Macxelio offers to update it when you turn System Tunnel on.
- UDP needs a proxy that supports it — VLESS, VMess, Trojan, or Shadowsocks. SOCKS and HTTP proxies carry TCP only.

If the proxy stops, the tunnel is removed and your Mac goes back to its normal connection.

## System Proxy

When enabled, Macxelio points macOS's **HTTP**, **HTTPS**, and **SOCKS** proxy at itself, so apps that follow macOS proxy settings route through the active proxy — not just your browser.

Toggle it from the menu bar (**System Proxy**) or in the menu's submenu. The indicator is filled when on, outline when off.

Macxelio cleans up the system proxy settings when you turn it off or quit.

### WebRTC & UDP

macOS proxy settings only cover **TCP**. Browsers send UDP — WebRTC (video calls, STUN) and HTTP/3 (QUIC) — straight out, which skips the proxy and can reveal your real IP to any website.

While System Proxy is on, two guards in [Settings](settings.md) block direct UDP so nothing escapes:

- **WebRTC Guard** (on by default) — blocks all outbound UDP except local network, DNS, DHCP, and time sync. WebRTC can't reveal your IP; calls fall back to relays over TCP, or may fail.
- **QUIC Guard** (on by default) — blocks HTTP/3 (UDP 443), so browsers fall back to HTTP/2 through the proxy. Turning it off lets QUIC go out directly, even with WebRTC Guard on.

For full WebRTC support, use **System Tunnel** instead. Nothing is blocked in **Direct** mode. In **Rule** mode, UDP to the IPs and CIDRs of your **Direct** IP rules is still allowed.

## System DNS

When enabled, Macxelio runs a local DNS resolver and points your Mac at it, so the DNS servers you configure — and any host mappings — are used system-wide.

Toggle it from the menu bar (**System DNS**). It's always on while System Tunnel is active. Configure the servers in [Settings](settings.md):

- **Primary DNS** — a plain IP (for example `8.8.8.8`) or a DoH URL (for example `https://1.1.1.1/dns-query`)
- **Secondary DNS** — a fallback server, in the same form

Plain IP and encrypted **DNS-over-HTTPS (DoH)** servers are both supported. Any [host mappings](routing.md) you've defined are applied alongside your DNS servers.

## Administrator password

System Tunnel, System DNS, and the UDP block run inside a small system helper — a launch daemon at `/Library/LaunchDaemons/com.macxelio.helper.plist`. macOS asks for your **administrator password** once, to install it; after that, turning these features on and off never prompts again. It's asked again only when an update changes the helper or Xray.

The helper runs its own root-owned copy of Xray from `/Library/PrivilegedHelperTools/com.macxelio`, so other apps can't swap the program it runs as root.

- The prompt is macOS's standard authorization dialog — Macxelio never sees or stores your password.
- If Touch ID for `sudo` is enabled (`pam_tid.so` in `/etc/pam.d/sudo_local`), Macxelio asks for your fingerprint instead, and falls back to the password dialog if you cancel.
- Everything is turned off and your network settings are restored when you quit Macxelio.

## Local ports

Macxelio listens locally on these ports by default — you can change them in [Settings](settings.md):

| Port   | Purpose     |
| ------ | ----------- |
| `3128` | HTTP proxy  |
| `1080` | SOCKS proxy |
