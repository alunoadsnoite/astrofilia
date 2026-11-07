extends SceneTree

# Valida o painel online do menu sem abrir sockets.

var failures: Array[String] = []

func check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
	print(("PASS " if condition else "FAIL ") + description)

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var manager = root.get_node("GameManager")
	manager.load_game()
	var menu = load("res://scenes/MainMenu.tscn").instantiate()
	root.add_child(menu)
	await process_frame

	var online_button = menu.get_node_or_null("PlayPanel/PlayVBox/OnlineButton")
	var panel = menu.get_node_or_null("OnlinePanel")
	check(online_button != null, "menu tem o botão de jogar online")
	check(panel != null and not panel.visible, "painel online começa oculto")

	menu._on_online_pressed()
	check(panel.visible, "botão online abre o painel")
	check(not menu.play_panel.visible, "painel de jogar fecha ao abrir o online")
	var ip: String = menu.online_ip_edit.text
	var port: String = menu.online_port_edit.text
	check(ip != "" and port == "7911", "IP e porta padrão preenchidos")
	check(menu.online_role_option.item_count == 2, "funções Coletor e Biólogo disponíveis")

	menu.online_name_edit.text = "  "
	check(menu._read_online_fields(), "nome vazio é aceito com padrão")
	check(menu.online_name_edit.text == "Astronauta", "nome vazio vira Astronauta")

	menu.online_port_edit.text = "abc"
	check(not menu._read_online_fields(), "porta inválida é recusada")

	menu.online_port_edit.text = "7911"
	menu.online_role_option.selected = 1
	check(menu._read_online_fields(), "campos válidos são aceitos")
	check(manager.role == "biologist", "função escolhida é aplicada ao jogador")

	menu._on_online_back_pressed()
	check(not panel.visible and menu.play_panel.visible, "voltar fecha o painel online")

	menu.queue_free()
	await process_frame
	print("MENU ONLINE COMPLETE: %d failures" % failures.size())
	quit(0 if failures.is_empty() else 1)
