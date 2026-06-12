# Environments

Some tools don't follow the macOS system proxy — package managers, command-line tools, and Docker often need their own proxy settings. **Environments** sets those up for you, pointing each tool at Macxelio's local HTTP proxy.

Open it with **⇧⌘E** or from the menu bar.

## How it works

Macxelio detects which tools are installed and lets you turn the proxy on or off for each one. When you enable a tool, it writes the proxy settings into that tool's config file; when you disable it, the settings are removed cleanly.

## Supported tools

### Package Managers

| Tool              | Config                   |
| ----------------- | ------------------------ |
| npm / pnpm / yarn | `~/.npmrc`               |
| pip               | `~/.config/pip/pip.conf` |
| conda             | `~/.condarc`             |
| cargo             | `~/.cargo/config.toml`   |
| gem               | `~/.gemrc`               |

### Version Control

| Tool | Config         |
| ---- | -------------- |
| git  | `~/.gitconfig` |

### Downloaders

| Tool | Config      |
| ---- | ----------- |
| curl | `~/.curlrc` |
| wget | `~/.wgetrc` |

### Containers

| Tool   | Config                  |
| ------ | ----------------------- |
| docker | `~/.docker/config.json` |

### Shell

| Tool      | Config     |
| --------- | ---------- |
| Shell env | `~/.zshrc` |

> Changes to shell and tool configs apply to **new** terminal sessions. Open a fresh terminal after toggling.
