# Getting Started

## Install

Macxelio runs on **macOS 13.0 or later**.

### Download

1. [**Download the latest release**](https://github.com/dalirnet/macxelio/releases/latest) (`Macxelio-x.y.z.zip`).
2. Unzip it and move **Macxelio.app** to your **Applications** folder.
3. The app isn't notarized, so right-click **Macxelio.app** → **Open** the first time, then confirm.

Macxelio launches straight into your menu bar — no Dock icon or window. If macOS still blocks the app, allow it under **System Settings → Privacy & Security**.

### Build from source

```bash
git clone https://github.com/dalirnet/macxelio.git
cd macxelio
make run
```

On first launch, Macxelio downloads the Xray-core binary it needs — there's nothing else to install.

## First launch

1. The app appears as a **flame icon in your menu bar**.
2. Open the main window from the menu bar item, or click the app.
3. Add a proxy (see [Proxies](proxies.md)) and select it.
4. Pick a [mode](routing.md) and, optionally, turn on the [system proxy](system.md).

## The menu bar

Click the flame icon to get quick controls without opening a window:

| Item             | What it does                                                    |
| ---------------- | --------------------------------------------------------------- |
| Active proxy     | Shows the selected proxy and its latency; click to open the app |
| **Proxy Mode**   | Switch between Global, Rule, and Direct                         |
| **System Proxy** | Turn the macOS system proxy on or off                           |
| **System DNS**   | Turn system-wide DNS on or off                                  |
| Pages            | Jump straight to Rules, Hosts, Environments, or Connections     |
| **Quit**         | Quit Macxelio                                                   |

Each item shows its current state at a glance — a filled, half, or outline circle for the mode, and filled/outline for the system toggles.

## Keyboard shortcuts

| Shortcut | Action       |
| -------- | ------------ |
| ⇧⌘R      | Rules        |
| ⇧⌘H      | Hosts        |
| ⇧⌘E      | Environments |
| ⇧⌘C      | Connections  |
| ⌘,       | Settings     |
| ⌘?       | Help         |
| ⌘Q       | Quit         |
