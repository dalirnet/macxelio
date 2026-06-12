# Modes & Routing

Routing decides what traffic goes through the proxy and what doesn't.

## Modes

Set the mode from the menu bar (**Proxy Mode**) or the main window.

| Mode       | Indicator      | Behavior                           |
| ---------- | -------------- | ---------------------------------- |
| **Global** | Filled circle  | Send everything through the proxy  |
| **Rule**   | Half circle    | Route only what matches your rules |
| **Direct** | Outline circle | Skip the proxy entirely            |

Use **Global** when you want all traffic proxied, **Direct** to temporarily bypass the proxy, and **Rule** for fine-grained control.

## Rules

Rules apply in **Rule** mode. Each rule matches traffic and decides where it goes.

Open rules with **⇧⌘R** or from the menu bar.

**Match by:**

| Type        | Example                  |
| ----------- | ------------------------ |
| **Domain**  | `example.com`            |
| **IP**      | `10.0.0.0/8`             |
| **GeoIP**   | `cn`, `private`          |
| **GeoSite** | `google`, `category-ads` |

**Action for each rule:**

- **Proxy** — send the matched traffic through the proxy.
- **Direct** — let it connect directly, bypassing the proxy.
- **Block** — drop it entirely.

Rules are evaluated in order, so put more specific rules first.

## Hosts

Hosts let you map a domain to a specific address — handy for overriding DNS or pinning an internal service.

Open hosts with **⇧⌘H**. Add an entry as `domain → address` (for example, `home.lan → 192.168.1.10`).

Host mappings are also applied when [System DNS](system.md) is enabled.
