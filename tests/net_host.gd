extends SceneTree

# Teste de rede real: abre uma sala ENet e espera um cliente em localhost.
# Rode junto com tests/net_client.gd; tests/net_session.sh orquestra os dois.

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
	var seen_remote: Dictionary = {}
	var seen_item: Dictionary = {}
	var seen_snake := [false]
	var seen_hit := [-1]

	net.remote_state.connect(func(id: int, pos: Vector3, _rot: float, _loc: int, _speed: float) -> void:
		seen_remote[id] = pos
	)
	net.item_state.connect(func(index: int, available: bool, _cooldown: float) -> void:
		seen_item[index] = available
	)
	net.snake_state.connect(func(states: Array) -> void:
		if not states.is_empty() and not (states[0] as Dictionary).is_empty():
			seen_snake[0] = true
	)
	net.snake_hit_requested.connect(func(_index: int, _damage: float, attacker_id: int) -> void:
		seen_hit[0] = attacker_id
	)

	var err: Error = net.host(PORT, WORLD_SEED, "Host", "collector", "default")
	check(err == OK, "host abre a sala ENet")
	check(net.in_session and net.is_host, "host fica em sessão como autoridade")
	check(net.address_hint() != "", "host informa um endereço para compartilhar")
	check(net.is_discovery_active(), "host anuncia a sala na rede Wi-Fi")

	var deadline := Time.get_ticks_msec() + 15000
	while net.player_count() < 2 and Time.get_ticks_msec() < deadline:
		await create_timer(0.1).timeout
	check(net.player_count() == 2, "cliente registrado (2 jogadores na sala)")
	var client_id := -1
	for id in net.peers.keys():
		if int(id) != 1:
			client_id = int(id)
	check(client_id > 1, "host identifica o id do cliente")
	if client_id > 1:
		check(String(net.peers.get(client_id, {}).get("name", "")) == "Client", "host vê o nome do cliente")

	# Dá tempo do cliente concluir o handshake antes dos canais de jogo.
	await create_timer(1.0).timeout

	# Host -> cliente: estado, item e cobras. Repete os canais não confiáveis.
	for i in range(10):
		net.send_state(Vector3(3, 4, 5), 0.5, 0, 2.0)
		net.broadcast_snakes([{
			"pos": Vector3(1, 0, 2),
			"rot": 0.2,
			"active": true,
			"health": 30.0,
			"visible": true,
		}])
		await create_timer(0.05).timeout
	net.broadcast_item(7, false, 12.0)
	check(seen_item.get(7, true) == false, "host aplica o item localmente")
	# Deixa o pacote confiável ser descarregado antes de encerrar o teste.
	await create_timer(0.5).timeout

	# Cliente -> host: posição, coleta e pedido de dano em cobra.
	deadline = Time.get_ticks_msec() + 12000
	while (not seen_remote.has(client_id) or not seen_item.has(9) or seen_hit[0] < 0) and Time.get_ticks_msec() < deadline:
		await create_timer(0.1).timeout
	check(seen_remote.has(client_id), "host recebe a posição do cliente")
	if seen_remote.has(client_id):
		check((seen_remote[client_id] as Vector3).is_equal_approx(Vector3(1, 2, 3)), "posição do cliente chega intacta")
	check(seen_item.get(9, true) == false, "host recebe a coleta do cliente")
	check(seen_hit[0] == client_id, "host recebe o pedido de dano em cobra do cliente")
	check(seen_snake[0], "host emite o estado autoritativo das cobras")

	await create_timer(0.3).timeout
	net.leave()
	await create_timer(0.2).timeout
	check(not net.in_session, "host encerra a sessão")

	print("NET HOST COMPLETE: %d failures" % failures.size())
	quit(0 if failures.is_empty() else 1)
