import Foundation

enum QUICBlock {
    static let label = "com.macxelio.quic"
    static let plistPath = "/Library/LaunchDaemons/com.macxelio.quic.plist"
    static let markerPath = Tools.dir.appendingPathComponent("quic.block")
    static let anchor = "com.apple/macxelio"

    static func isInstalled() -> Bool {
        FileManager.default.fileExists(atPath: plistPath)
    }

    static func isActive() -> Bool {
        FileManager.default.fileExists(atPath: markerPath.path)
    }

    static func apply(_ enabled: Bool) {
        guard enabled else {
            try? FileManager.default.removeItem(at: markerPath)
            return
        }
        guard !isActive() else { return }
        DispatchQueue.global().async {
            guard install() else { return }
            try? Data().write(to: markerPath)
        }
    }

    @discardableResult
    private static func install() -> Bool {
        guard !isInstalled() else { return true }

        let tmpPlist = "/tmp/\(label).plist"
        try? plistContent().write(toFile: tmpPlist, atomically: true, encoding: .utf8)

        return Shell.runAsRoot(
            """
            cp '\(tmpPlist)' '\(plistPath)'
            chown root:wheel '\(plistPath)'
            chmod 644 '\(plistPath)'
            launchctl bootout system/\(label) 2>/dev/null
            launchctl bootstrap system '\(plistPath)'
            """)
    }

    private static func plistContent() -> String {
        let supervisor =
            "MARK=\"\(markerPath.path)\"; ANCHOR=\(anchor); STATE=off; TOKEN=\"\"; "
            + "/sbin/pfctl -a \"$ANCHOR\" -F rules 2&gt;/dev/null; "
            + "while true; do "
            + "if [ -f \"$MARK\" ]; then "
            + "if [ \"$STATE\" != on ]; then "
            + "TOKEN=$(/sbin/pfctl -E 2&gt;&amp;1 | /usr/bin/sed -n 's/.*Token : *//p'); "
            + "/bin/echo 'block drop out quick proto udp from any to any port 443' "
            + "| /sbin/pfctl -a \"$ANCHOR\" -f - 2&gt;/dev/null; "
            + "STATE=on; fi; "
            + "else "
            + "if [ \"$STATE\" != off ]; then "
            + "/sbin/pfctl -a \"$ANCHOR\" -F rules 2&gt;/dev/null; "
            + "[ -n \"$TOKEN\" ] &amp;&amp; /sbin/pfctl -X \"$TOKEN\" 2&gt;/dev/null; "
            + "TOKEN=\"\"; STATE=off; fi; fi; "
            + "sleep 1; done"

        return """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>Label</key><string>\(label)</string>
                <key>ProgramArguments</key>
                <array>
                    <string>/bin/sh</string>
                    <string>-c</string>
                    <string>\(supervisor)</string>
                </array>
                <key>RunAtLoad</key><true/>
                <key>KeepAlive</key><true/>
            </dict>
            </plist>
            """
    }
}
