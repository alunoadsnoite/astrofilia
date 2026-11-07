extends SceneTree

# Integração online: entra na sala e roda Gameplay.tscn de verdade (headless).

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
	var err: Error = net.join("127.0.0.1", PORT, "Client", "biologist", "blue")
	check(err == OK, "cliente inicia a conexão")

	var deadline := Time.get_ticks_msec() + 15000
	while not net.in_session and Time.get_ticks_msec() < deadline:
		await create_timer(0.1).timeout
	check(net.in_session, "cliente entra na sala")

	var manager = root.get_node("GameManager")
	manager.start_online_session(net.local_name, net.local_role, net.local_appearance)
	scene = load("res://scenes/Gameplay.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.set_process(false)
	scene.player.set_physics_process(false)

	check(scene.world_seed == WORLD_SEED, "Gameplay do cliente usa a seed do host")
	check(manager.online and manager.role == "biologist", "cliente mantém a função escolhida")

	deadline = Time.get_ticks_msec() + 12000
	var host_avatar = null
	while Time.get_ticks_msec() < deadline:
		await pump(0.2)
		host_avatar = scene.net_players.get(1)
		if host_avatar != null and scene.net_targets.has(1):
			break
	check(host_avatar != null and is_instance_valid(host_avatar), "cliente cria o avatar remoto do host")
	if host_avatar != null and is_instance_valid(host_avatar):
		var tag = host_avatar.get_node_or_null("NameTag")
		check(tag != null and String(tag.text) == "Host", "avatar remoto mostra o nome do host")
		check(not host_avatar.is_in_group("player"), "avatar remoto não entra no grupo do jogador local")
		check(host_avatar.visible, "avatar do host fica visível no mesmo cenário")

	# O host posicionou o jogador em (12, 1, -8) e coletou o item 3.
	deadline = Time.get_ticks_msec() + 8000
	while Time.get_ticks_msec() < deadline:
		await pump(0.2)
		if scene.net_targets.has(1) and not scene.items_node.get_child(3).available:
			break
	check(scene.net_targets.has(1), "cliente recebe o estado do host")
	if scene.net_targets.has(1):
		var target: Dictionary = scene.net_targets[1]
		check((target["pos"] as Vector3).is_equal_approx(Vector3(12, 1, -8)), "posição do host chegou intacta")
		var distance: float = (host_avatar.global_position - Vector3(12, 1, -8)).length()
		check(distance < 1.0, "avatar remoto converge para a posição do host")
	check(not scene.items_node.get_child(3).available, "cliente vê o item coletado pelo host")

	# Devolve posição e coleta para o host validar.
	scene.player.global_position = Vector3(-10, 1, 6)
	scene._send_net_state()
	scene._on_item_collected("fruit", 5)
	await pump(1.5)

	net.leave()
	scene.queue_free()
	await create_timer(0.2).timeout
	check(not net.in_session, "cliente encerra a sessão")

	print("NET GAMEPLAY CLIENT COMPLETE: %d failures" % failures.size())
	quit(0 if failures.is_empty() else 1)
