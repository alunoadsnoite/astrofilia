extends SceneTree

# Integração online: abre a sala e roda Gameplay.tscn de verdade (headless).
# Valida avatar remoto, seed compartilhado, posição e coleta de itens.

const PORT := 7932
const WORLD_SEED := 777123

var failures: Array[String] = []
var net: Node
var scene: Node

func check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
	print(("PASS " if condition else "FAIL ") + description)

func _initialize() -> void:
	call_deferred("run_checks")

func pump(seconds: float) -> void:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < deadline:
		scene._update_network(0.1)
		await create_timer(0.1).timeout

func run_checks() -> void:
	net = root.get_node("Net")
	var manager = root.get_node("GameManager")
	var err: Error = net.host(PORT, WORLD_SEED, "Host", "collector", "default")
	check(err == OK, "host abre a sala")
	manager.start_online_session("Host", "collector", "default")
	check(manager.online, "GameManager entra em modo online sem slot")

	scene = load("res://scenes/Gameplay.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.set_process(false)
	scene.player.set_physics_process(false)
	check(scene.world_seed == WORLD_SEED, "Gameplay do host usa a seed da sala")
	check(scene.get_node_or_null("RemotePlayers") != null, "host cria o nó de avatares remotos")
	check(scene.net_label != null, "HUD online aparece no host")

	var deadline := Time.get_ticks_msec() + 15000
	while net.player_count() < 2 and Time.get_ticks_msec() < deadline:
		await create_timer(0.1).timeout
	check(net.player_count() == 2, "cliente entra na sala do host")

	var client_id := -1
	for id in net.peers.keys():
		if int(id) != 1:
			client_id = int(id)
	check(client_id > 1, "host identifica o cliente")

	deadline = Time.get_ticks_msec() + 12000
	while (not scene.net_players.has(client_id) or not scene.net_targets.has(client_id)) and Time.get_ticks_msec() < deadline:
		await pump(0.2)
	check(scene.net_players.has(client_id), "host cria o avatar remoto do cliente")
	check(scene.net_targets.has(client_id), "cliente carregou o Gameplay e enviou o primeiro estado")
	var avatar = scene.net_players.get(client_id)
	if avatar != null and is_instance_valid(avatar):
		var tag = avatar.get_node_or_null("NameTag")
		check(tag != null and String(tag.text) == "Client", "avatar remoto mostra o nome do cliente")
		check(not avatar.is_in_group("player"), "avatar remoto não disputa o grupo do jogador local")

	scene.player.global_position = Vector3(12, 1, -8)
	scene._send_net_state()
	scene._on_item_collected("crystal", 3)

	# Aguarda o cliente terminar as verificações e sair por conta própria.
	# Guarda o último estado antes da desconexão limpar net_targets.
	var last_target: Dictionary = {}
	deadline = Time.get_ticks_msec() + 15000
	while net.player_count() >= 2 and Time.get_ticks_msec() < deadline:
		if scene.net_targets.has(client_id):
			last_target = (scene.net_targets[client_id] as Dictionary).duplicate()
		await pump(0.2)

	check(net.player_count() < 2, "cliente encerra a sessão de forma limpa")
	check(not last_target.is_empty(), "host recebeu o estado do cliente")
	if not last_target.is_empty():
		check((last_target["pos"] as Vector3).is_equal_approx(Vector3(-10, 1, 6)), "posição do cliente chegou intacta")
	var client_item = scene.items_node.get_child(5)
	check(not client_item.available, "coleta do cliente aparece no mundo do host")

	await create_timer(0.3).timeout
	net.leave()
	scene.queue_free()
	await create_timer(0.2).timeout
	check(not net.in_session, "host encerra a sala")

	print("NET GAMEPLAY HOST COMPLETE: %d failures" % failures.size())
	quit(0 if failures.is_empty() else 1)
