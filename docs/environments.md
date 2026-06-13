# Environments

Some tools don't follow the macOS system proxy — editors, package managers, and Docker often need their own proxy settings. **Environments** sets those up for you, pointing each tool at Macxelio's local HTTP proxy.

Open it with **⇧⌘E** or from the menu bar.

## How it works

Macxelio detects which tools are installed and lets you turn the proxy on or off for each one. When you enable a tool, it applies the proxy through that tool's own configuration — running its config command or editing its config file — and removes it cleanly when you disable it, leaving the rest of your config untouched.

## Supported tools

### General

| Tool      | Config                  |
| --------- | ----------------------- |
| Shell env | `~/.zshrc`              |
| git       | `~/.gitconfig`          |
| docker    | `~/.docker/config.json` |

### Editors

| Tool    | Config                                                  |
| ------- | ------------------------------------------------------- |
| Zed     | `~/.config/zed/settings.json`                           |
| VS Code | `~/Library/Application Support/Code/User/settings.json` |

### Package Managers

| Tool | Config                   |
| ---- | ------------------------ |
| npm  | `~/.npmrc`               |
| pip  | `~/.config/pip/pip.conf` |
| go   | `~/.config/go/env`       |

> **npm** also configures **pnpm** and **yarn** when they're installed. Tools that already honor `HTTP_PROXY` (cargo, gem, conda, …) are covered by **Shell env**.

> Changes apply to **new** sessions — open a fresh terminal, or restart your editor, after toggling.
