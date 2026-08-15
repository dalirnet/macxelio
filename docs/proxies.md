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

## Import a share link

Paste a share link into the field at the top of the proxy form and the rest of the form fills itself — protocol, address, port, credentials, and transport security. The link is not stored; edit anything you like before saving.

Supported: `vless://`, `vmess://`, `trojan://`, `ss://`, `socks://`, `http://`. Links that use a non-TCP transport (WebSocket, gRPC, HTTP/2) or an unsupported Shadowsocks method are rejected with a message instead of importing partially.

## Transport security

VLESS, VMess, and Trojan can run over plain TCP, **TLS**, or **REALITY**.

| Field          | Applies to     | Share-link name |
| -------------- | -------------- | --------------- |
| **SNI**        | TLS, REALITY   | `sni`           |
| **Fingerprint**| TLS, REALITY   | `fp`            |
| **Flow**       | VLESS          | `flow`          |
| **Public Key** | REALITY        | `pbk`           |
| **Short ID**   | REALITY        | `sid`           |
| **SpiderX**    | REALITY        | `spx`           |

Leave **SNI** empty to use the server address. **Public Key** is required for REALITY; **Short ID** and **SpiderX** are optional and must match the server.

## Add a proxy

1. Open the main window and click the **+** button.
2. Choose the protocol.
3. Fill in the server **address** and **port**.
4. Enter the credentials for that protocol (UUID, password, method, etc.).
5. For VLESS, VMess, or Trojan, pick the **Security** under Transport and fill in its fields.
6. Save.

Your proxies are stored locally and listed in the main window.

## Select a proxy

Click a proxy in the list to make it active. Macxelio applies it immediately and starts checking its connection. The active proxy shows a status avatar — see [Status & Connections](connections.md).

Only one proxy is active at a time.

## Restart

If something looks stuck, use the **restart** button on the active proxy to restart the Xray core and re-check connectivity.
