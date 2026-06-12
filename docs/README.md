# Macxelio

**Mac** + **X**ray + **I/O**

A native macOS menu bar proxy client, powered by Xray-core.

Built to be lean and efficient — not packed with features you'll never use. It lives in your menu bar, does its job, and stays out of the way. No accounts, no telemetry, no clutter.

## What it does

- **Menu bar control** — switch proxies, change mode, and turn the system proxy or DNS on and off without opening a window.
- **Proxy modes** — send everything through the proxy (Global), route only what matches your rules (Rule), or skip it entirely (Direct).
- **Whole-Mac coverage** — works across your system, not just the browser.
- **Protocols** — Shadowsocks, VLESS, VMess, Trojan, SOCKS, and HTTP.
- **Routing** — rules by Domain, IP, GeoIP, or GeoSite, plus custom hosts and DNS.
- **Environments** — inject proxy settings into dev tools and package managers.
- **Live status** — periodic latency checks with a clear status on the active proxy.
- **Connections** — see what's connected and how it's being routed.

## Where to start

- New here? Read [Getting Started](getting-started.md).
- Adding a server? See [Proxies](proxies.md).
- Deciding what goes through the proxy? See [Modes & Routing](routing.md).

## Download

[**Download the latest release**](https://github.com/dalirnet/macxelio/releases/latest), or [build from source](getting-started.md).

## Requirements

macOS 13.0 or later. Macxelio downloads the Xray-core it needs on first launch — there's nothing else to install.
