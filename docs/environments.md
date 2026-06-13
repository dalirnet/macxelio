# Environments

Some tools don't follow the macOS system proxy — editors, package managers, and Docker often need their own proxy settings. **Environments** sets those up for you, pointing each tool at Macxelio's local HTTP proxy.

Open it with **⇧⌘E** or from the menu bar.

## How it works

Macxelio detects which tools are installed and lets you turn the proxy on or off for each one. When you enable a tool, it writes the proxy setting into that tool's config file; when you disable it, the setting is removed cleanly and the rest of your config is left untouched.

## Supported tools

### General

| Tool      | Config                  |
| --------- | ----------------------- |
| git       | `~/.gitconfig`          |
| docker    | `~/.docker/config.json` |
| Shell env | `~/.zshrc`              |

### Editors

| Tool    | Config                                                    |
| ------- | --------------------------------------------------------- |
| Zed     | `~/.config/zed/settings.json`                             |
| VS Code | `~/Library/Application Support/Code/User/settings.json`   |
| Cursor  | `~/Library/Application Support/Cursor/User/settings.json` |

### Package Managers

| Tool  | Config                   |
| ----- | ------------------------ |
| npm   | `~/.npmrc`               |
| pip   | `~/.config/pip/pip.conf` |
| conda | `~/.condarc`             |
| cargo | `~/.cargo/config.toml`   |
| gem   | `~/.gemrc`               |
| go    | `~/.config/go/env`       |

> Changes apply to **new** sessions — open a fresh terminal, or restart your editor, after toggling.
