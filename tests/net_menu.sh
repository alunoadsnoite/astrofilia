#!/usr/bin/env bash
# Valida a descoberta automática do menu: host + cliente sem digitar IP.
set -u
cd "$(dirname "$0")/.."

HOST_LOG=/tmp/opencode/astrofilia_net_menu_host.log
CLIENT_LOG=/tmp/opencode/astrofilia_net_menu_client.log
HOST_DATA=/tmp/opencode/astrofilia_net_menu_host_data
CLIENT_DATA=/tmp/opencode/astrofilia_net_menu_client_data
mkdir -p "$HOST_DATA" "$CLIENT_DATA" /tmp/opencode
rm -f "$HOST_LOG" "$CLIENT_LOG"

XDG_DATA_HOME="$HOST_DATA" timeout 60 godot --headless --path . --script res://tests/net_host_simple.gd > "$HOST_LOG" 2>&1 &
HOST_PID=$!

sleep 2
XDG_DATA_HOME="$CLIENT_DATA" timeout 50 godot --headless --path . --script res://tests/net_menu_client.gd > "$CLIENT_LOG" 2>&1
CLIENT_STATUS=$?

wait "$HOST_PID"
HOST_STATUS=$?

tail -n 20 "$HOST_LOG"
tail -n 20 "$CLIENT_LOG"

if [ "$HOST_STATUS" -ne 0 ] || [ "$CLIENT_STATUS" -ne 0 ]; then
	echo "NET MENU FAILED (host=$HOST_STATUS client=$CLIENT_STATUS)"
	exit 1
fi
echo "NET MENU OK"
