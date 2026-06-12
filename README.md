# Macxelio

**Mac** + **X**ray + **I/O**

A native macOS menu bar proxy client, powered by Xray-core.

[![Latest Release](https://img.shields.io/github/v/release/dalirnet/macxelio?label=download)](https://github.com/dalirnet/macxelio/releases/latest)
![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)
![macOS 13+](https://img.shields.io/badge/macOS-13%2B-black.svg)
![Swift](https://img.shields.io/badge/Swift-native-orange.svg)

Built to be lean and efficient — not packed with features you'll never use. It lives in your menu bar, does its job, and stays out of the way. No accounts, no telemetry, no clutter.

## Why

I relied on ClashX for years — it was the proxy client I opened every day on my Mac. Then, in late 2023, [ClashX and the wider Clash ecosystem were taken down from GitHub](https://github.com/net4people/bbs/issues/303). Its last release was v1.17.0, and it was never updated again. Because it was built on the older v2ray-core, it never supported newer Xray-core protocols like VLESS and REALITY.

I kept using it anyway — for years, even outdated — because nothing else felt right. The alternatives weren't truly native to macOS, or weren't as simple to live with day to day.

Eventually I built my own. Macxelio isn't trying to be the most powerful client out there — it's trying to be the most efficient one: fast, simple, lightweight, and native to the Mac. Just the things I need, done well.

## Features

- **Menu bar control** — switch proxies, change mode, and turn the system proxy or DNS on and off without opening a window. Every item shows its current state at a glance.
- **Proxy modes** — send everything through the proxy (Global), route only what matches your rules (Rule), or skip it entirely (Direct).
- **Whole-Mac coverage** — works across your system, not just the browser, by setting the macOS proxy and DNS for you.
- **Protocols** — Shadowsocks, VLESS, VMess, Trojan, SOCKS, and HTTP.
- **Routing rules** — decide what goes where by Domain, IP, GeoIP, or GeoSite, with Proxy / Direct / Block actions.
- **Hosts & DNS** — custom host mappings and DNS servers, with optional system-wide DNS.
- **Dev environments** — set up proxy settings for your tools too (npm, pip, cargo, git, docker, shell, and more).
- **Live status** — checks your connection on a timer and shows a clear status on the active proxy.
- **Connections** — see what's connected and how it's being routed.

## Requirements

Macxelio runs on macOS 13.0 or later. It downloads the Xray-core it needs on first launch — there's nothing else to install.

## Download

[**Download the latest release**](https://github.com/dalirnet/macxelio/releases/latest), unzip it, and move **Macxelio.app** to your Applications folder.

The app isn't notarized, so the first time you open it: right-click **Macxelio.app** → **Open**, then confirm. If macOS still blocks it, allow it under **System Settings → Privacy & Security**.

## Build from source

```bash
make run      # build and launch
make release  # universal release build
```

## License

MIT
