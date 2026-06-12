# Proxies

A proxy is a server Macxelio routes your traffic through. You can add as many as you like and switch between them in a click.

## Supported protocols

| Protocol        | Needs                          |
| --------------- | ------------------------------ |
| **Shadowsocks** | Password, encryption method    |
| **VLESS**       | UUID                           |
| **VMess**       | UUID                           |
| **Trojan**      | Password                       |
| **SOCKS**       | Optional username and password |
| **HTTP**        | Optional username and password |

## Add a proxy

1. Open the main window and click the **+** button.
2. Choose the protocol.
3. Fill in the server **address** and **port**.
4. Enter the credentials for that protocol (UUID, password, method, etc.).
5. Save.

Your proxies are stored locally and listed in the main window.

## Select a proxy

Click a proxy in the list to make it active. Macxelio applies it immediately and starts checking its connection. The active proxy shows a status avatar — see [Status & Connections](connections.md).

Only one proxy is active at a time.

## Restart

If something looks stuck, use the **restart** button on the active proxy to restart the Xray core and re-check connectivity.
