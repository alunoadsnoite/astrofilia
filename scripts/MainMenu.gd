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

func _on_options_pressed() -> void:
	options_panel.visible = true
	play_panel.visible = false
	achievements_panel.visible = false

func _on_play_back_pressed() -> void:
	play_panel.visible = false

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
