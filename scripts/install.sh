#!/bin/sh
set -eu

REPO="guanzihao166/nezha-agent-hardened"
VERSION="v1.0.0-hardened"
TARGET_DIR="/opt/nezha/agent"
BINARY="$TARGET_DIR/nezha-agent"

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

if command -v systemctl >/dev/null 2>&1; then
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

if [ "$OS" = "Darwin" ] && [ -f /Library/LaunchDaemons/nezha-agent.plist ]; then
    launchctl bootout system/nezha-agent 2>/dev/null || launchctl unload /Library/LaunchDaemons/nezha-agent.plist 2>/dev/null || true
    rm -f /Library/LaunchDaemons/nezha-agent.plist
fi

if command -v pgrep >/dev/null 2>&1 && pgrep -x nezha-agent >/dev/null 2>&1; then
    pkill -x nezha-agent || true
    sleep 2
fi

rm -f "$BINARY"
mkdir -p "$TARGET_DIR"
curl -fL "https://github.com/$REPO/releases/download/$VERSION/$ASSET" -o "$BINARY"
chmod 0755 "$BINARY"
cd "$TARGET_DIR"

ENV_ARGS="NZ_SERVER=$NZ_SERVER NZ_TLS=$NZ_TLS NZ_CLIENT_SECRET=$NZ_CLIENT_SECRET"
if [ -n "$NZ_UUID" ]; then
    ENV_ARGS="$ENV_ARGS NZ_UUID=$NZ_UUID"
fi

# shellcheck disable=SC2086
env $ENV_ARGS ./nezha-agent service install
./nezha-agent service start

echo "installed: $BINARY"
if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$BINARY"
else
    shasum -a 256 "$BINARY"
fi
