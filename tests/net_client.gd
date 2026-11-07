extends SceneTree

# Teste de rede real: entra na sala aberta por tests/net_host.gd em localhost.

const PORT := 7931
const WORLD_SEED := 424242

var failures: Array[String] = []
var net: Node

func check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
	print(("PASS " if condition else "FAIL ") + description)

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	net = root.get_node("Net")
	var flags := {"host_position": false, "item_7": false, "item_9": false, "snake_ok": false}

	net.remote_state.connect(func(id: int, pos: Vector3, _rot: float, _loc: int, _speed: float) -> void:
		if id == 1 and pos.is_equal_approx(Vector3(3, 4, 5)):
			flags["host_position"] = true
	)
	net.item_state.connect(func(index: int, available: bool, _cooldown: float) -> void:
		if index == 7 and not available:
			flags["item_7"] = true
		if index == 9 and not available:
			flags["item_9"] = true
	)
	net.snake_state.connect(func(states: Array) -> void:
		if not states.is_empty():
			var state: Dictionary = states[0]
			if not state.is_empty() and is_equal_approx(float(state.get("health", 0.0)), 30.0):
				flags["snake_ok"] = true
	)

	var err: Error = net.join("127.0.0.1", PORT, "Client", "biologist", "blue")
	check(err == OK, "cliente inicia a conexão ENet")

	var deadline := Time.get_ticks_msec() + 15000
	while not net.in_session and Time.get_ticks_msec() < deadline:
		await create_timer(0.1).timeout
	check(net.in_session, "cliente entra na sessão")
	check(not net.is_host, "cliente não é a autoridade")
	check(net.address_hint() == "", "cliente não anuncia endereço de host")
	check(net.world_seed == WORLD_SEED, "cliente recebe a seed do mundo do host")
	check(net.player_count() == 2, "cliente vê os dois jogadores")
	check(String(net.peers.get(1, {}).get("name", "")) == "Host", "cliente vê o nome do host")

	# Envia posição algumas vezes porque o canal é não confiável.
	for i in range(10):
		net.send_state(Vector3(1, 2, 3), 0.25, 0, 1.5)
		await create_timer(0.05).timeout
	net.broadcast_item(9, false, 12.0)
	net.request_snake_hit(0, 12.0)

	deadline = Time.get_ticks_msec() + 12000
	while (not flags["host_position"] or not flags["item_7"] or not flags["snake_ok"]) and Time.get_ticks_msec() < deadline:
		await create_timer(0.1).timeout
	check(flags["host_position"], "cliente recebe a posição do host")
	check(flags["item_7"], "cliente recebe o item coletado pelo host")
	check(flags["snake_ok"], "cliente recebe o estado da cobra do host")

	# O host reenvia a coleta do cliente; isso prova a ida e volta pela sala.
	deadline = Time.get_ticks_msec() + 5000
	while not flags["item_9"] and Time.get_ticks_msec() < deadline:
		await create_timer(0.1).timeout
	check(flags["item_9"], "coleta do cliente volta pelo host")

	net.leave()
	await create_timer(0.2).timeout
	check(not net.in_session, "cliente encerra a sessão")

	print("NET CLIENT COMPLETE: %d failures" % failures.size())
	quit(0 if failures.is_empty() else 1)
