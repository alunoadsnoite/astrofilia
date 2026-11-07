#!/usr/bin/env bash
# Integração online completa: dois processos rodando Gameplay.tscn em localhost.
set -u
cd "$(dirname "$0")/.."

HOST_LOG=/tmp/opencode/astrofilia_net_game_host.log
CLIENT_LOG=/tmp/opencode/astrofilia_net_game_client.log
HOST_DATA=/tmp/opencode/astrofilia_net_game_host_data
CLIENT_DATA=/tmp/opencode/astrofilia_net_game_client_data
mkdir -p "$HOST_DATA" "$CLIENT_DATA" /tmp/opencode
rm -f "$HOST_LOG" "$CLIENT_LOG"

XDG_DATA_HOME="$HOST_DATA" timeout 90 godot --headless --path . --script res://tests/net_gameplay_host.gd > "$HOST_LOG" 2>&1 &
HOST_PID=$!

sleep 2
XDG_DATA_HOME="$CLIENT_DATA" timeout 75 godot --headless --path . --script res://tests/net_gameplay_client.gd > "$CLIENT_LOG" 2>&1
CLIENT_STATUS=$?

wait "$HOST_PID"
HOST_STATUS=$?

tail -n 30 "$HOST_LOG"
tail -n 30 "$CLIENT_LOG"

if [ "$HOST_STATUS" -ne 0 ] || [ "$CLIENT_STATUS" -ne 0 ]; then
	echo "NET GAMEPLAY FAILED (host=$HOST_STATUS client=$CLIENT_STATUS)"
	exit 1
fi
echo "NET GAMEPLAY OK"
