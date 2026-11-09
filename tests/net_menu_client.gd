extends SceneTree

# Valida o fluxo fácil do menu: procurar sala no Wi-Fi e conectar sem digitar IP.

const PORT := 7933
const SEED := 555777

var failures: Array[String] = []

func check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
	print(("PASS " if condition else "FAIL ") + description)

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var net = root.get_node("Net")
	var manager = root.get_node("GameManager")
	manager.load_game()
	var menu = load("res://scenes/MainMenu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await process_frame

	menu._on_online_pressed()
	menu.online_name_edit.text = "Visitante"
	menu.online_role_option.selected = 1
	menu._on_online_scan_pressed()

	var saw_port := [false]
	var deadline := Time.get_ticks_msec() + 12000
	while not net.in_session and Time.get_ticks_msec() < deadline:
		if is_instance_valid(menu):
			if menu.online_port_edit.text == str(PORT):
				saw_port[0] = true
		await create_timer(0.1).timeout
	check(saw_port[0], "descoberta preenche a porta da sala encontrada")
	check(net.in_session, "menu conecta sozinho ao encontrar uma sala")

	deadline = Time.get_ticks_msec() + 8000
	while (current_scene == null or current_scene.scene_file_path != "res://scenes/Gameplay.tscn") and Time.get_ticks_msec() < deadline:
		await create_timer(0.1).timeout
	var scene = current_scene
	check(scene != null and scene.scene_file_path == "res://scenes/Gameplay.tscn", "menu abre o Gameplay depois de conectar")
	if scene != null and scene.scene_file_path == "res://scenes/Gameplay.tscn":
		scene.set_process(false)
		scene.player.set_physics_process(false)
		check(scene.world_seed == SEED, "Gameplay usa a seed da sala encontrada")
		check(manager.online, "sessão online fica ativa")
		check(manager.role == "biologist", "função escolhida é mantida")
		check(scene.net_players.size() >= 1, "avatar do host é criado")
		scene.queue_free()

	net.leave()
	await create_timer(0.3).timeout
	print("MENU SCAN COMPLETE: %d failures" % failures.size())
	quit(0 if failures.is_empty() else 1)
