#!/bin/sh
set -eu

REPO="guanzihao166/nezha-agent-hardened"
VERSION="v1.0.0-hardened"
TARGET_DIR="/opt/nezha/agent"
BINARY="$TARGET_DIR/nezha-agent"
CONFIG="$TARGET_DIR/config.yml"

: "${NZ_SERVER:?NZ_SERVER is required}"
: "${NZ_CLIENT_SECRET:?NZ_CLIENT_SECRET is required}"
NZ_TLS="${NZ_TLS:-false}"
NZ_UUID="${NZ_UUID:-}"

OS="$(uname -s)"
case "$OS" in
    Linux)
        ASSET="nezha-agent_linux_amd64"
        ;;
    Darwin)
        ASSET="nezha-agent_darwin_amd64"
        ;;
    *)
        echo "Unsupported OS: $OS" >&2
        exit 1
        ;;
esac

IS_ALPINE=false
if [ "$OS" = "Linux" ] && [ -f /etc/alpine-release ] && command -v rc-service >/dev/null 2>&1; then
    IS_ALPINE=true
fi

if [ "$IS_ALPINE" = "false" ] && command -v systemctl >/dev/null 2>&1; then
    systemctl stop 'nezha-agent*' 2>/dev/null || true
    systemctl disable 'nezha-agent*' 2>/dev/null || true
    rm -f /etc/systemd/system/nezha-agent.service \
        /etc/systemd/system/nezha-agent*.service \
        /lib/systemd/system/nezha-agent.service \
        /lib/systemd/system/nezha-agent*.service \
        /usr/lib/systemd/system/nezha-agent.service \
        /usr/lib/systemd/system/nezha-agent*.service
    systemctl daemon-reload
fi

if [ "$IS_ALPINE" = "true" ]; then
    if [ -x /etc/init.d/nezha-agent ]; then
        rc-service nezha-agent stop 2>/dev/null || true
        rc-update del nezha-agent 2>/dev/null || true
    fi
fi

if [ "$OS" = "Darwin" ] && [ -f /Library/LaunchDaemons/nezha-agent.plist ]; then
    launchctl bootout system/nezha-agent 2>/dev/null || launchctl unload /Library/LaunchDaemons/nezha-agent.plist 2>/dev/null || true
    rm -f /Library/LaunchDaemons/nezha-agent.plist
fi

stop_agent() {
    if command -v pgrep >/dev/null 2>&1 && pgrep -x nezha-agent >/dev/null 2>&1; then
        pkill -x nezha-agent 2>/dev/null || true
        sleep 2
        return
    fi
    if command -v pidof >/dev/null 2>&1; then
        pids="$(pidof nezha-agent 2>/dev/null || true)"
        if [ -n "$pids" ]; then
            # shellcheck disable=SC2086
            kill $pids 2>/dev/null || true
            sleep 2
        fi
    fi
}
stop_agent

rm -f "$BINARY"
mkdir -p "$TARGET_DIR"

fetch_asset() {
    if command -v curl >/dev/null 2>&1; then
        curl -fL "https://github.com/$REPO/releases/download/$VERSION/$ASSET" -o "$BINARY"
    elif command -v wget >/dev/null 2>&1; then
        wget -q -O "$BINARY" "https://github.com/$REPO/releases/download/$VERSION/$ASSET"
    else
        echo "curl or wget is required" >&2
        exit 1
    fi
}
fetch_asset
chmod 0755 "$BINARY"
cd "$TARGET_DIR"

write_config() {
    {
        echo "client_secret: \"$NZ_CLIENT_SECRET\""
        echo "debug: false"
        echo "disable_auto_update: false"
        echo "disable_command_execute: false"
        echo "disable_force_update: false"
        echo "disable_nat: false"
        echo "disable_send_query: false"
        echo "gpu: false"
        echo "insecure_tls: false"
        echo "ip_report_period: 1800"
        echo "report_delay: 3"
        echo "self_update_period: 0"
        echo "server: \"$NZ_SERVER\""
        echo "skip_connection_count: false"
        echo "skip_procs_count: false"
        echo "temperature: false"
        echo "tls: $NZ_TLS"
        echo "use_atomgit_to_upgrade: false"
        echo "use_gitee_to_upgrade: false"
        echo "use_ipv6_country_code: false"
        if [ -n "$NZ_UUID" ]; then
            echo "uuid: \"$NZ_UUID\""
        fi
    } > "$CONFIG"
    chmod 0600 "$CONFIG"
}

if [ "$IS_ALPINE" = "true" ]; then
    write_config

    cat > /etc/init.d/nezha-agent <<'EOF'
#!/sbin/openrc-run
name="nezha-agent"
description="Nezha Monitor Agent"
command="/opt/nezha/agent/nezha-agent"
command_args="-c /opt/nezha/agent/config.yml"
command_background="yes"
pidfile="/run/nezha-agent.pid"
depend() {
    need net
}
EOF
    chmod 0755 /etc/init.d/nezha-agent
    rc-update add nezha-agent default
    rc-service nezha-agent start

    echo "installed: $BINARY"
    echo "service: OpenRC /etc/init.d/nezha-agent"
else
    ENV_ARGS="NZ_SERVER=$NZ_SERVER NZ_TLS=$NZ_TLS NZ_CLIENT_SECRET=$NZ_CLIENT_SECRET"
    if [ -n "$NZ_UUID" ]; then
        ENV_ARGS="$ENV_ARGS NZ_UUID=$NZ_UUID"
    fi

    # shellcheck disable=SC2086
    env $ENV_ARGS ./nezha-agent service install
    ./nezha-agent service start

    echo "installed: $BINARY"
fi

if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$BINARY"
elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$BINARY"
else
    echo "SHA-256: unavailable"
fi
