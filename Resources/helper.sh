#!/bin/sh
DIR="__DIR__"
ROOT="__ROOT__"
BIN="$ROOT/xray"
ANCHOR="com.apple/macxelio"
export XRAY_LOCATION_ASSET="$DIR"

PF_STATE=""
PF_TOKEN=""
TUN_PID=""; TUN_STAMP=""; TUN_FAILED=""
DNS_PID=""; DNS_STAMP=""; DNS_FAILED=""

umask 022
/bin/echo '{"log":{"loglevel":"warning","access":"none"}}' > "$ROOT/tunnel-log.json"
/bin/echo '{"log":{"loglevel":"error"}}' > "$ROOT/dns-log.json"

stamp() { /sbin/md5 -q "$1" 2>/dev/null; }

event() {
    LOGFILE="$ROOT/helper.log"
    [ "$(/usr/bin/stat -f %z "$LOGFILE" 2>/dev/null || echo 0)" -gt 262144 ] && : > "$LOGFILE"
    echo "$(/bin/date '+%F %T') $*" >> "$LOGFILE"
}

rules() {
    QUIC=$1; WEBRTC=$2; ALLOW=$3
    PORTS="53, 67, 68, 123"
    if [ "$QUIC" = 1 ]; then
        echo 'block drop out quick proto udp from any to any port 443'
    else
        PORTS="$PORTS, 443"
    fi
    [ "$WEBRTC" = 1 ] || return
    echo 'table <local> const { 127.0.0.0/8, 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 169.254.0.0/16, 100.64.0.0/10, 224.0.0.0/4, 255.255.255.255, ::1, fe80::/10, fc00::/7, ff00::/8 }'
    echo 'pass out quick proto udp from any to <local>'
    if [ -n "$ALLOW" ]; then
        echo "table <direct> const { $ALLOW }"
        echo 'pass out quick proto udp from any to <direct>'
    fi
    echo "pass out quick proto udp from any to any port { $PORTS }"
    echo 'block drop out quick proto udp from any to any'
}

firewall() {
    WANT=$(/bin/cat "$DIR/firewall" 2>/dev/null)
    [ "$WANT" = "$PF_STATE" ] && return
    PF_STATE="$WANT"
    FLAGS=" $(printf '%s\n' "$WANT" | /usr/bin/head -n 1) "
    ALLOW=$(printf '%s\n' "$WANT" | /usr/bin/tail -n +2 \
        | /usr/bin/grep -E '^[0-9A-Fa-f:.]+(/[0-9]{1,3})?$' | /usr/bin/paste -sd, -)
    QUIC=0; WEBRTC=0
    case "$FLAGS" in *" quic "*) QUIC=1 ;; esac
    case "$FLAGS" in *" webrtc "*) WEBRTC=1 ;; esac
    /sbin/pfctl -a "$ANCHOR" -F all 2>/dev/null
    if [ "$QUIC$WEBRTC" != 00 ]; then
        [ -z "$PF_TOKEN" ] && PF_TOKEN=$(/sbin/pfctl -E 2>&1 | /usr/bin/sed -n 's/.*Token : *//p')
        rules "$QUIC" "$WEBRTC" "$ALLOW" | /sbin/pfctl -a "$ANCHOR" -f - 2>/dev/null
    elif [ -n "$PF_TOKEN" ]; then
        /sbin/pfctl -X "$PF_TOKEN" 2>/dev/null
        PF_TOKEN=""
    fi
}

supervise() {
    NAME=$1; MARK=$2; CFG=$3; EXTRA=$4; LOG=$5; RETRY=$6
    eval "PID=\$${NAME}_PID; STAMP=\$${NAME}_STAMP; FAILED=\$${NAME}_FAILED"
    if [ -f "$MARK" ]; then
        NOW="$(stamp "$CFG")$(/bin/cat "$MARK" 2>/dev/null)"
        if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
            if [ "$NOW" != "$STAMP" ]; then
                event "$NAME reload"
                kill "$PID" 2>/dev/null; wait "$PID" 2>/dev/null; PID=""
            fi
        elif [ -n "$PID" ]; then
            wait "$PID" 2>/dev/null
            event "$NAME exited with code $?"
            PID=""
            [ -z "$RETRY" ] && FAILED="$STAMP"
        fi
        if [ -z "$PID" ] && [ -f "$CFG" ] && [ "$NOW" != "$FAILED" ]; then
            "$BIN" run -c "$CFG" -c "$EXTRA" >"$LOG" 2>&1 &
            PID=$!; STAMP="$NOW"; FAILED=""
            event "$NAME start pid $PID"
        fi
    else
        if [ -n "$PID" ]; then
            event "$NAME stop"
            kill "$PID" 2>/dev/null; wait "$PID" 2>/dev/null; PID=""
        fi
        FAILED=""
    fi
    eval "${NAME}_PID=\$PID; ${NAME}_STAMP=\$STAMP; ${NAME}_FAILED=\$FAILED"
}

cleanup() {
    [ -n "$TUN_PID" ] && kill "$TUN_PID" 2>/dev/null
    [ -n "$DNS_PID" ] && kill "$DNS_PID" 2>/dev/null
    /sbin/pfctl -a "$ANCHOR" -F all 2>/dev/null
    [ -n "$PF_TOKEN" ] && /sbin/pfctl -X "$PF_TOKEN" 2>/dev/null
    exit 0
}
trap cleanup TERM INT

/sbin/pfctl -a "$ANCHOR" -F all 2>/dev/null
while true; do
    firewall
    supervise TUN "$DIR/tunnel.on" "$DIR/tunnel.json" "$ROOT/tunnel-log.json" "$ROOT/tunnel.log" ""
    supervise DNS "$DIR/dns.on" "$DIR/dns.json" "$ROOT/dns-log.json" /dev/null retry
    sleep 1
done
