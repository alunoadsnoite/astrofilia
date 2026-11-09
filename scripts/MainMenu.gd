extends Control

@onready var play_button: Button = $Center/VBox/PlayButton
@onready var options_button: Button = $Center/VBox/OptionsButton
@onready var play_panel: Panel = $PlayPanel
@onready var options_panel: Panel = $OptionsPanel
@onready var achievements_panel: Panel = $AchievementsPanel

@onready var new_game_button: Button = $PlayPanel/PlayVBox/NewGameButton
@onready var slot1_button: Button = $PlayPanel/PlayVBox/Slot1Button
@onready var slot2_button: Button = $PlayPanel/PlayVBox/Slot2Button
@onready var play_back_button: Button = $PlayPanel/PlayVBox/PlayBackButton
@onready var online_button: Button = $PlayPanel/PlayVBox/OnlineButton

@onready var online_panel: Panel = $OnlinePanel
@onready var online_title: Label = $OnlinePanel/OnlineVBox/OnlineTitle
@onready var online_name_label: Label = $OnlinePanel/OnlineVBox/OnlineNameLabel
@onready var online_name_edit: LineEdit = $OnlinePanel/OnlineVBox/OnlineNameEdit
@onready var online_address_label: Label = $OnlinePanel/OnlineVBox/OnlineAddressLabel
@onready var online_ip_edit: LineEdit = $OnlinePanel/OnlineVBox/OnlineAddressBox/OnlineIPEdit
@onready var online_port_edit: LineEdit = $OnlinePanel/OnlineVBox/OnlineAddressBox/OnlinePortEdit
@onready var online_role_label: Label = $OnlinePanel/OnlineVBox/OnlineRoleLabel
@onready var online_role_option: OptionButton = $OnlinePanel/OnlineVBox/OnlineRoleOption
@onready var online_scan_button: Button = $OnlinePanel/OnlineVBox/OnlineScanButton
@onready var online_rooms_option: OptionButton = $OnlinePanel/OnlineVBox/OnlineRoomsOption
@onready var online_hint: Label = $OnlinePanel/OnlineVBox/OnlineHint
@onready var online_host_button: Button = $OnlinePanel/OnlineVBox/OnlineHostButton
@onready var online_join_button: Button = $OnlinePanel/OnlineVBox/OnlineJoinButton
@onready var online_status: Label = $OnlinePanel/OnlineVBox/OnlineStatus
@onready var online_back_button: Button = $OnlinePanel/OnlineVBox/OnlineBackButton

@onready var username_edit: LineEdit = $OptionsPanel/OptionsVBox/UsernameEdit
@onready var language_option: OptionButton = $OptionsPanel/OptionsVBox/LanguageOption
@onready var appearance_option: OptionButton = $OptionsPanel/OptionsVBox/AppearanceOption
@onready var sfx_slider: HSlider = $OptionsPanel/OptionsVBox/SfxSlider
@onready var music_slider: HSlider = $OptionsPanel/OptionsVBox/MusicSlider
@onready var mode_option: OptionButton = $OptionsPanel/OptionsVBox/ModeOption
@onready var role_option: OptionButton = $OptionsPanel/OptionsVBox/RoleOption
@onready var achievements_button: Button = $OptionsPanel/OptionsVBox/AchievementsButton
@onready var options_back_button: Button = $OptionsPanel/OptionsVBox/OptionsBackButton
@onready var achievements_back_button: Button = $AchievementsPanel/AchievementsVBox/AchievementsBackButton
@onready var achievements_list: VBoxContainer = $AchievementsPanel/AchievementsVBox/AchievementsList

var selected_slot_index: int = -1
var choosing_new_slot := false
var overwrite_dialog: ConfirmationDialog
var connect_token: int = 0
var scan_token: int = 0
var discovered_rooms: Array = []

func _ready() -> void:
	GameManager.load_game()
	overwrite_dialog = ConfirmationDialog.new()
	overwrite_dialog.title = "Substituir partida"
	overwrite_dialog.confirmed.connect(func(): _start_game(true))
	add_child(overwrite_dialog)
	_refresh_texts()
	_refresh_slots()
	_setup_options()
	$Center/VBox/Title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
	$Center/VBox/Subtitle.add_theme_color_override("font_color", Color(0.7, 0.6, 1.0))
	play_button.pressed.connect(_on_play_pressed)
	options_button.pressed.connect(_on_options_pressed)
	new_game_button.pressed.connect(_on_new_game_pressed)
	slot1_button.pressed.connect(func(): _on_slot_pressed(0))
	slot2_button.pressed.connect(func(): _on_slot_pressed(1))
	play_back_button.pressed.connect(_on_play_back_pressed)
	online_button.pressed.connect(_on_online_pressed)
	online_host_button.pressed.connect(_on_online_host_pressed)
	online_join_button.pressed.connect(_on_online_join_pressed)
	online_back_button.pressed.connect(_on_online_back_pressed)
	online_scan_button.pressed.connect(_on_online_scan_pressed)
	online_rooms_option.item_selected.connect(_on_online_room_selected)
	Net.join_ok.connect(_on_net_join_ok)
	Net.join_failed.connect(_on_net_join_failed)
	Net.session_ended.connect(_on_net_session_ended)
	# Nunca herdar uma sessão antiga ao voltar ao menu.
	if Net.in_session or Net.connecting:
		Net.leave()
	GameManager.online = false
	achievements_button.pressed.connect(_on_achievements_pressed)
	options_back_button.pressed.connect(_on_options_back_pressed)
	achievements_back_button.pressed.connect(_on_achievements_back_pressed)
	username_edit.text_changed.connect(_on_username_changed)
	language_option.item_selected.connect(_on_language_selected)
	appearance_option.item_selected.connect(_on_appearance_selected)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	music_slider.value_changed.connect(_on_music_changed)
	mode_option.item_selected.connect(_on_mode_selected)
	role_option.item_selected.connect(_on_role_selected)
	for button in find_children("*", "Button", true, false):
		button.pressed.connect(func() -> void: Sfx.play("click"))

func _refresh_texts() -> void:
	play_button.text = GameManager.t("play")
	options_button.text = GameManager.t("options")
	new_game_button.text = GameManager.t("new_game")
	online_button.text = GameManager.t("online_play")
	online_title.text = GameManager.t("online_title")
	online_name_label.text = GameManager.t("online_name")
	online_address_label.text = GameManager.t("online_ip") + " / " + GameManager.t("online_port")
	online_role_label.text = GameManager.t("online_role")
	online_scan_button.text = GameManager.t("online_scan")
	online_host_button.text = GameManager.t("online_host")
	online_join_button.text = GameManager.t("online_join")
	online_hint.text = GameManager.t("online_hint")
	online_back_button.text = GameManager.t("back")
	play_back_button.text = GameManager.t("back")
	options_back_button.text = GameManager.t("back")
	achievements_back_button.text = GameManager.t("back")
	$Center/VBox/Subtitle.text = "Uma aventura espacial"
	$Center/VBox/Title.text = "ASTROFILIA"
	$PlayPanel/PlayVBox/PlayTitle.text = GameManager.t("play")
	$OptionsPanel/OptionsVBox/OptionsTitle.text = GameManager.t("options")
	$OptionsPanel/OptionsVBox/UsernameLabel.text = GameManager.t("username")
	$OptionsPanel/OptionsVBox/LanguageLabel.text = GameManager.t("language")
	$OptionsPanel/OptionsVBox/AppearanceLabel.text = GameManager.t("appearance")
	$OptionsPanel/OptionsVBox/SfxLabel.text = GameManager.t("sound")
	$OptionsPanel/OptionsVBox/MusicLabel.text = GameManager.t("music")
	$OptionsPanel/OptionsVBox/ModeLabel.text = GameManager.t("mode") if false else "Modo de jogo"
	$AchievementsPanel/AchievementsVBox/AchievementsTitle.text = GameManager.t("achievements")

func _refresh_slots() -> void:
	var slots := GameManager.saved_games
	var btns := [slot1_button, slot2_button]
	for i in range(2):
		if i < slots.size() and slots[i].size() > 0:
			btns[i].text = "%s %d: %s" % [GameManager.t("save_slot"), i + 1, slots[i].get("name", "Jogo")]
			btns[i].tooltip_text = "Continuar partida" if GameManager.has_snapshot(i) else "Partida antiga sem progresso: iniciar tutorial"
		else:
			btns[i].text = "%s %d (%s)" % [GameManager.t("save_slot"), i + 1, GameManager.t("empty_slot")]

func _setup_options() -> void:
	# Idiomas
	language_option.clear()
	language_option.add_item("Português", 0)
	language_option.add_item("English", 1)
	language_option.add_item("Español", 2)
	match GameManager.language:
		"en": language_option.selected = 1
		"es": language_option.selected = 2
		_: language_option.selected = 0

	# Aparências
	appearance_option.clear()
	for a in ["Padrão", "Traje Azul", "Traje Vermelho", "Traje Verde"]:
		appearance_option.add_item(a)
	appearance_option.selected = maxi(0, ["default", "blue", "red", "green"].find(GameManager.appearance))

	# Modo
	mode_option.clear()
	mode_option.add_item(GameManager.t("singleplayer"))
	mode_option.add_item(GameManager.t("multiplayer"))
	mode_option.selected = 0 if GameManager.singleplayer else 1

	role_option.clear()
	role_option.add_item("Coletor")
	role_option.add_item("Biólogo")
	role_option.selected = 0 if GameManager.role == "collector" else 1

	username_edit.text = GameManager.player_name
	sfx_slider.value = GameManager.sfx_volume
	music_slider.value = GameManager.music_volume

func _on_play_pressed() -> void:
	choosing_new_slot = false
	$PlayPanel/PlayVBox/PlayTitle.text = GameManager.t("play")
	play_panel.visible = true
	options_panel.visible = false
	achievements_panel.visible = false
	online_panel.visible = false
	online_status.text = ""
	_set_online_busy(false)

func _on_options_pressed() -> void:
	options_panel.visible = true
	play_panel.visible = false
	achievements_panel.visible = false

func _on_play_back_pressed() -> void:
	play_panel.visible = false

func _on_online_pressed() -> void:
	play_panel.visible = false
	options_panel.visible = false
	achievements_panel.visible = false
	online_panel.visible = true
	online_status.text = ""
	scan_token += 1
	discovered_rooms.clear()
	online_rooms_option.clear()
	online_rooms_option.visible = false
	online_name_edit.text = GameManager.player_name
	_setup_online_roles()
	online_ip_edit.text = "127.0.0.1" if online_ip_edit.text.strip_edges() == "" else online_ip_edit.text
	online_port_edit.text = str(Net.DEFAULT_PORT) if online_port_edit.text.strip_edges() == "" else online_port_edit.text
	_set_online_busy(false)
	online_name_edit.grab_focus()

func _setup_online_roles() -> void:
	online_role_option.clear()
	online_role_option.add_item("Coletor", 0)
	online_role_option.add_item("Biólogo", 1)
	online_role_option.selected = 0 if GameManager.role == "collector" else 1

func _on_online_scan_pressed() -> void:
	if Net.in_session or Net.connecting:
		return
	if not _read_online_fields():
		return
	scan_token += 1
	var token := scan_token
	_set_online_busy(true)
	online_rooms_option.visible = false
	online_status.text = GameManager.t("online_scanning")
	var rooms: Array = await Net.discover_rooms(2.5)
	if token != scan_token or not online_panel.visible:
		return
	_set_online_busy(false)
	discovered_rooms = rooms
	if rooms.is_empty():
		online_status.text = GameManager.t("online_no_rooms")
		return
	online_rooms_option.clear()
	for room in rooms:
		var label := "%s • %s:%d • %d/%d" % [
			String(room["name"]), String(room["ip"]), int(room["port"]),
			int(room["players"]), int(room["max"]),
		]
		online_rooms_option.add_item(label)
	online_rooms_option.selected = 0
	online_rooms_option.visible = true
	_apply_discovered_room(0)
	if rooms.size() == 1:
		online_status.text = GameManager.t("online_found") % String(rooms[0]["name"])
		await get_tree().create_timer(0.4).timeout
		if token != scan_token or not online_panel.visible:
			return
		if Net.connecting or Net.in_session:
			return
		_on_online_join_pressed()
	else:
		online_status.text = GameManager.t("online_rooms_hint")

func _apply_discovered_room(index: int) -> void:
	if index < 0 or index >= discovered_rooms.size():
		return
	var room: Dictionary = discovered_rooms[index]
	online_ip_edit.text = String(room["ip"])
	online_port_edit.text = str(int(room["port"]))

func _on_online_room_selected(index: int) -> void:
	_apply_discovered_room(index)
	if index >= 0 and index < discovered_rooms.size():
		var room: Dictionary = discovered_rooms[index]
		online_status.text = GameManager.t("online_found") % String(room["name"])

func _read_online_fields() -> bool:
	var name := online_name_edit.text.strip_edges()
	if name == "":
		name = "Astronauta"
		online_name_edit.text = name
	GameManager.player_name = name
	GameManager.role = "collector" if online_role_option.selected == 0 else "biologist"
	var port := int(online_port_edit.text.strip_edges())
	if port <= 0 or port > 65535:
		online_status.text = "Porta inválida. Use um valor entre 1 e 65535."
		return false
	return true

func _set_online_busy(busy: bool) -> void:
	online_host_button.disabled = busy
	online_join_button.disabled = busy
	online_scan_button.disabled = busy
	online_rooms_option.disabled = busy
	online_back_button.disabled = false
	online_name_edit.editable = not busy
	online_ip_edit.editable = not busy
	online_port_edit.editable = not busy
	online_role_option.disabled = busy

func _on_online_host_pressed() -> void:
	scan_token += 1
	if not _read_online_fields():
		return
	var port := int(online_port_edit.text.strip_edges())
	var seed_value: int = randi()
	var err := Net.host(port, seed_value, GameManager.player_name, GameManager.role, GameManager.appearance)
	if err != OK:
		online_status.text = "Não foi possível abrir a sala na porta %d. Tente outra porta." % port
		return
	_set_online_busy(true)
	online_status.text = GameManager.t("online_waiting")
	GameManager.start_online_session(GameManager.player_name, GameManager.role, GameManager.appearance)
	_enter_online_game()

func _on_online_join_pressed() -> void:
	scan_token += 1
	if not _read_online_fields():
		return
	var ip := online_ip_edit.text.strip_edges()
	if ip == "":
		online_status.text = "Informe o IP do host."
		return
	var port := int(online_port_edit.text.strip_edges())
	_set_online_busy(true)
	online_status.text = GameManager.t("online_connecting")
	var err := Net.join(ip, port, GameManager.player_name, GameManager.role, GameManager.appearance)
	if err != OK:
		_set_online_busy(false)
		online_status.text = "Não foi possível iniciar a conexão. Confira o IP e a porta."
		return
	_begin_connect_timeout()

func _begin_connect_timeout() -> void:
	connect_token += 1
	var token := connect_token
	await get_tree().create_timer(8.0).timeout
	if token != connect_token:
		return
	if Net.connecting:
		Net.cancel_connect()
		_set_online_busy(false)
		online_status.text = "Tempo esgotado. Confira o IP, a porta e se o host abriu a sala."

func _on_net_join_ok() -> void:
	connect_token += 1
	if not online_panel.visible:
		return
	GameManager.start_online_session(Net.local_name, Net.local_role, Net.local_appearance)
	_enter_online_game()

func _on_net_join_failed(reason: String) -> void:
	connect_token += 1
	_set_online_busy(false)
	online_status.text = reason

func _on_net_session_ended(reason: String) -> void:
	connect_token += 1
	_set_online_busy(false)
	online_status.text = reason

func _enter_online_game() -> void:
	GameManager.online = true
	GameManager.singleplayer = false
	GameManager.active_slot = -1
	GameManager.pending_snapshot.clear()
	GameManager.in_interior = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Gameplay.tscn")

func _on_online_back_pressed() -> void:
	connect_token += 1
	scan_token += 1
	discovered_rooms.clear()
	online_rooms_option.clear()
	online_rooms_option.visible = false
	if Net.in_session or Net.connecting:
		Net.cancel_connect()
	_set_online_busy(false)
	online_status.text = ""
	online_panel.visible = false
	play_panel.visible = true

func _on_options_back_pressed() -> void:
	options_panel.visible = false
	GameManager.save_game()

func _on_achievements_pressed() -> void:
	achievements_panel.visible = true
	_refresh_achievements()

func _on_achievements_back_pressed() -> void:
	achievements_panel.visible = false

func _refresh_achievements() -> void:
	for c in achievements_list.get_children():
		c.queue_free()
	if GameManager.achievements.is_empty():
		var l := Label.new()
		l.text = "Nenhuma conquista ainda."
		achievements_list.add_child(l)
	else:
		for a in GameManager.achievements:
			var l := Label.new()
			l.text = "🏆 " + a
			achievements_list.add_child(l)

func _on_new_game_pressed() -> void:
	selected_slot_index = GameManager.first_empty_slot()
	if selected_slot_index >= 0:
		_start_game(true)
	else:
		choosing_new_slot = true
		$PlayPanel/PlayVBox/PlayTitle.text = "Escolha o slot para o novo jogo"

func _on_slot_pressed(idx: int) -> void:
	selected_slot_index = idx
	if choosing_new_slot and idx < GameManager.saved_games.size() and not GameManager.saved_games[idx].is_empty():
		overwrite_dialog.dialog_text = "Substituir a partida de %s no slot %d?" % [GameManager.saved_games[idx].get("name", "Astronauta"), idx + 1]
		overwrite_dialog.popup_centered()
		return
	if idx < GameManager.saved_games.size() and GameManager.saved_games[idx].has("snapshot") and not GameManager.has_snapshot(idx):
		$PlayPanel/PlayVBox/PlayTitle.text = "Save incompatível. Escolha outro slot."
		return
	_start_game(not GameManager.has_snapshot(idx))

func _start_game(is_new: bool) -> void:
	if is_new:
		if GameManager.begin_new_game(selected_slot_index) != OK:
			$PlayPanel/PlayVBox/PlayTitle.text = "Não foi possível salvar. Tente novamente."
			return
		get_tree().change_scene_to_file("res://scenes/Cutscene.tscn")
	elif GameManager.prepare_continue(selected_slot_index):
		get_tree().change_scene_to_file("res://scenes/Gameplay.tscn")

func _on_username_changed(new_text: String) -> void:
	GameManager.player_name = new_text

func _on_language_selected(idx: int) -> void:
	match idx:
		0: GameManager.set_language("pt")
		1: GameManager.set_language("en")
		2: GameManager.set_language("es")
	_refresh_texts()
	_setup_options()

func _on_appearance_selected(idx: int) -> void:
	var opts := ["default", "blue", "red", "green"]
	if idx < opts.size():
		GameManager.appearance = opts[idx]

func _on_sfx_changed(v: float) -> void:
	GameManager.sfx_volume = v

func _on_music_changed(v: float) -> void:
	GameManager.music_volume = v

func _on_mode_selected(idx: int) -> void:
	GameManager.set_mode(idx == 0)

func _on_role_selected(idx: int) -> void:
	GameManager.role = "collector" if idx == 0 else "biologist"
	GameManager.save_game()
