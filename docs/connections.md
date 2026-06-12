# Status & Connections

## Connection status

Macxelio checks the active proxy on a timer and shows a status on its avatar in the main window. The check interval starts short and backs off while the connection stays healthy, so a stable proxy is checked less often.

| Status        | Color  | Meaning                       |
| ------------- | ------ | ----------------------------- |
| **Connected** | Green  | Reachable, latency under 0.5s |
| **Slow**      | Yellow | Reachable, latency over 0.5s  |
| **Checking**  | Gray   | A check is in progress        |
| **Error**     | Red    | The proxy is unreachable      |
| **Idle**      | Gray   | No proxy selected             |

When connected, the avatar shows the measured latency, and a thin ring fills as a countdown to the next check.

The menu bar icon also reflects the status — solid when connected, dimmed otherwise.

## Connections

The **Connections** view (**⇧⌘C**) shows your most recent active connections in real time:

- **Host** — where the connection is going.
- **Inbound** — which local protocol it came in on.
- **Route** — how it was handled: through the **proxy**, **direct**, or **blocked**.

Totals for upload and download traffic are shown as well. The list refreshes every couple of seconds and keeps the most recent connections.
