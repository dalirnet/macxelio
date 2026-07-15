# FAQ

## Do I need to install Xray separately?

No. Macxelio downloads the Xray-core binary it needs on first launch.

## Why is there no app in the Dock?

Macxelio is a menu bar app. It lives in the menu bar and only shows a Dock icon while its window is open.

## I enabled the proxy for git / npm, but it's still not using it.

Tool and shell configs apply to **new** sessions. Open a fresh terminal after changing [Environments](environments.md).

## The active proxy shows "Error". What now?

The proxy is unreachable. Check the server address, port, and credentials in [Proxies](proxies.md), confirm the server is up, then use the restart button to re-check.

## Why does System DNS ask for my password every time?

Turning System DNS on **installs** a small DNS resolver as a system service, and turning it off **removes** it. Both require administrator rights, so macOS prompts each time you enable or disable it. It's macOS's standard authorization dialog — Macxelio never sees or stores your password. See [System Proxy & DNS](system.md).

## Can I use an encrypted (DoH) DNS server?

Yes. In [Settings](settings.md), enter a DNS-over-HTTPS URL such as `https://1.1.1.1/dns-query` as your Primary or Secondary DNS, then enable [System DNS](system.md). Plain IPs and DoH URLs can be mixed. IP-based DoH URLs work as-is; hostname-based ones are bootstrapped automatically.

## Some apps still bypass the proxy.

The system proxy covers apps that honor macOS proxy settings. Tools that don't (many CLIs and Docker) need [Environments](environments.md) instead.

## How do I route only some traffic?

Use **Rule** mode and add rules. See [Modes & Routing](routing.md).

## Where is my data stored?

Locally, as JSON in Macxelio's config folder — open it from [Settings](settings.md). No accounts, no telemetry.

## Which macOS versions are supported?

macOS 13.0 or later.
