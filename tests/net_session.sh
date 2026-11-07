#!/usr/bin/env bash
# Sobe host e cliente Godot headless em localhost e valida a sessão ENet real.
set -u
cd "$(dirname "$0")/.."

HOST_LOG=/tmp/opencode/astrofilia_net_host.log
CLIENT_LOG=/tmp/opencode/astrofilia_net_client.log
HOST_DATA=/tmp/opencode/astrofilia_net_host_data
CLIENT_DATA=/tmp/opencode/astrofilia_net_client_data
mkdir -p "$HOST_DATA" "$CLIENT_DATA" /tmp/opencode
rm -f "$HOST_LOG" "$CLIENT_LOG"

XDG_DATA_HOME="$HOST_DATA" timeout 90 godot --headless --path . --script res://tests/net_host.gd > "$HOST_LOG" 2>&1 &
HOST_PID=$!

sleep 2
XDG_DATA_HOME="$CLIENT_DATA" timeout 60 godot --headless --path . --script res://tests/net_client.gd > "$CLIENT_LOG" 2>&1
CLIENT_STATUS=$?

wait "$HOST_PID"
HOST_STATUS=$?

tail -n 20 "$HOST_LOG"
tail -n 20 "$CLIENT_LOG"

if [ "$HOST_STATUS" -ne 0 ] || [ "$CLIENT_STATUS" -ne 0 ]; then
	echo "NET SESSION FAILED (host=$HOST_STATUS client=$CLIENT_STATUS)"
	exit 1
fi
echo "NET SESSION OK"
