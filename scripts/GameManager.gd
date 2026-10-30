extends Node

signal language_changed(lang: String)
signal mode_changed(singleplayer: bool)
signal mission_changed(index: int, mission: Dictionary)

const SAVE_PATH := "user://astrofilia_save.cfg"
const SAVE_VERSION := 1

var active_slot: int = -1
var pending_snapshot: Dictionary = {}

var player_name: String = "Astronauta"
var language: String = "pt"
var sfx_volume: float = 1.0
var music_volume: float = 1.0
var appearance: String = "default"
var singleplayer: bool = true
var role: String = "collector"
var achievements: Array[String] = []
var saved_games: Array[Dictionary] = []

var mission_list: Array[Dictionary] = []
var current_mission_index: int = 0
var current_mission_progress: int = 0
var missions_complete: bool = false

var translations := {
	"pt": {
		"play": "Jogar", "options": "Opções", "back": "Voltar",
		"singleplayer": "Um jogador", "multiplayer": "Multijogador",
		"new_game": "Novo jogo", "save_slot": "Jogo salvo", "empty_slot": "Vazio",
		"language": "Idioma", "appearance": "Aparência", "sound": "Efeitos sonoros",
		"music": "Música", "username": "Nome de usuário", "achievements": "Conquistas",
		"mission_final_mp": "Virem juntos para casa!",
		"mission_final_sp": "Volte para casa!",
	},
	"en": {
		"play": "Play", "options": "Options", "back": "Back",
		"singleplayer": "Singleplayer", "multiplayer": "Multiplayer",
		"new_game": "New game", "save_slot": "Saved game", "empty_slot": "Empty",
		"language": "Language", "appearance": "Appearance", "sound": "Sound effects",
		"music": "Music", "username": "Username", "achievements": "Achievements",
		"mission_final_mp": "Return home together!", "mission_final_sp": "Return home!",
	},
	"es": {
		"play": "Jugar", "options": "Opciones", "back": "Volver",
		"singleplayer": "Un jugador", "multiplayer": "Multijugador",
		"new_game": "Nuevo juego", "save_slot": "Juego guardado", "empty_slot": "Vacío",
		"language": "Idioma", "appearance": "Apariencia", "sound": "Efectos de sonido",
		"music": "Música", "username": "Nombre de usuario", "achievements": "Logros",
		"mission_final_mp": "¡Vuelvan a casa juntos!", "mission_final_sp": "¡Vuelve a casa!",
	},
}

func _ready() -> void:
	load_game()

func t(key: String) -> String:
	var dict: Dictionary = translations.get(language, translations["pt"])
	return dict.get(key, key)

func set_language(lang: String) -> void:
	language = lang
	language_changed.emit(lang)
	save_game()

func set_mode(single: bool) -> void:
	singleplayer = single
	mode_changed.emit(single)
	save_game()

func save_game() -> Error:
	var cfg := ConfigFile.new()
	cfg.set_value("player", "name", player_name)
	cfg.set_value("player", "language", language)
	cfg.set_value("player", "sfx_volume", sfx_volume)
	cfg.set_value("player", "music_volume", music_volume)
	cfg.set_value("player", "appearance", appearance)
	cfg.set_value("player", "singleplayer", singleplayer)
	cfg.set_value("player", "role", role)
	cfg.set_value("player", "achievements", achievements)
	cfg.set_value("saves", "games", saved_games)
	# Write a complete temporary file before replacing the previous save.
	var temporary_path := SAVE_PATH + ".tmp"
	var error := cfg.save(temporary_path)
	if error != OK:
		return error
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary_path), ProjectSettings.globalize_path(SAVE_PATH))

func load_game() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	player_name = cfg.get_value("player", "name", player_name)
	language = cfg.get_value("player", "language", language)
	sfx_volume = cfg.get_value("player", "sfx_volume", sfx_volume)
	music_volume = cfg.get_value("player", "music_volume", music_volume)
	appearance = cfg.get_value("player", "appearance", appearance)
	singleplayer = cfg.get_value("player", "singleplayer", singleplayer)
	role = cfg.get_value("player", "role", role)
	achievements = cfg.get_value("player", "achievements", achievements)
	saved_games = cfg.get_value("saves", "games", saved_games)

func add_achievement(id: String) -> void:
	if not achievements.has(id):
		achievements.append(id)
		save_game()

# --- Missões do tutorial ---
func build_mission_list() -> void:
	mission_list.clear()
	var collector: Array[Dictionary] = [
		{"owner": "collector", "action": "collect", "target": "mineral", "count": 1,
		 "text_pt": "1 Coletor: Pegue um mineral próximo à nave", "text_en": "1 Collector: Get a mineral near the ship", "text_es": "1 Colector: Obtén un mineral cerca de la nave"},
		{"owner": "collector", "action": "collect", "target": "fruit", "count": 1,
		 "text_pt": "2 Coletor: Pegue uma fruta", "text_en": "2 Collector: Get a fruit", "text_es": "2 Colector: Obtén una fruta"},
		{"owner": "collector", "action": "collect", "target": "animal", "count": 1,
		 "text_pt": "3 Coletor: Derrube um animal pequeno para comer", "text_en": "3 Collector: Defeat a small animal to eat", "text_es": "3 Colector: Derrota un animal pequeño para comer"},
		{"owner": "collector", "action": "collect", "target": "crystal", "count": 3,
		 "text_pt": "4 Coletor: Colete 3 minerais raros", "text_en": "4 Collector: Collect 3 rare minerals", "text_es": "4 Colector: Recolecta 3 minerales raros"},
		{"owner": "collector", "action": "collect", "target": "fruit", "count": 1,
		 "text_pt": "5 Coletor: Pegue mais uma fruta", "text_en": "5 Collector: Get another fruit", "text_es": "5 Colector: Obtén otra fruta"},
		{"owner": "collector", "action": "collect", "target": "stone", "count": 5,
		 "text_pt": "6 Coletor: Colete 5 pedras", "text_en": "6 Collector: Collect 5 stones", "text_es": "6 Colector: Recolecta 5 piedras"},
		{"owner": "collector", "action": "collect", "target": "crystal", "count": 1,
		 "text_pt": "7 Coletor: Encontre um cristal brilhante", "text_en": "7 Collector: Find a shiny crystal", "text_es": "7 Colector: Encuentra un cristal brillante"},
		{"owner": "collector", "action": "collect", "target": "crystal", "count": 1,
		 "text_pt": "8 Coletor: Pegue o último item raro", "text_en": "8 Collector: Get the last rare item", "text_es": "8 Colector: Obtén el último item raro"},
	]
	var biologist: Array[Dictionary] = [
		{"owner": "biologist", "action": "interact", "target": "animal", "count": 1,
		 "text_pt": "1 Biólogo: Faça o reconhecimento de uma criatura", "text_en": "1 Biologist: Recognize a creature", "text_es": "1 Biólogo: Reconoce una criatura"},
		{"owner": "biologist", "action": "interact", "target": "lake", "count": 1,
		 "text_pt": "2 Biólogo: Verifique se o lago está contaminado", "text_en": "2 Biologist: Check if the lake is contaminated", "text_es": "2 Biólogo: Verifica si el lago está contaminado"},
		{"owner": "biologist", "action": "interact", "target": "fruit", "count": 1,
		 "text_pt": "3 Biólogo: Verifique se a fruta é venenosa", "text_en": "3 Biologist: Check if the fruit is poisonous", "text_es": "3 Biólogo: Verifica si la fruta es venenosa"},
		{"owner": "biologist", "action": "interact", "target": "plant", "count": 1,
		 "text_pt": "4 Biólogo: Tire uma foto de uma planta", "text_en": "4 Biologist: Take a photo of a plant", "text_es": "4 Biólogo: Toma una foto de una planta"},
		{"owner": "biologist", "action": "interact", "target": "animal", "count": 1,
		 "text_pt": "5 Biólogo: Analise um animal com a câmera especial", "text_en": "5 Biologist: Analyze an animal with the special camera", "text_es": "5 Biólogo: Analiza un animal con la cámara especial"},
		{"owner": "biologist", "action": "interact", "target": "lake", "count": 1,
		 "text_pt": "6 Biólogo: Verifique a qualidade da água do rio", "text_en": "6 Biologist: Check the river water quality", "text_es": "6 Biólogo: Verifica la calidad del agua del río"},
		{"owner": "biologist", "action": "interact", "target": "animal", "count": 1,
		 "text_pt": "7 Biólogo: Fotografe um animal raro", "text_en": "7 Biologist: Photograph a rare animal", "text_es": "7 Biólogo: Fotografía un animal raro"},
		{"owner": "biologist", "action": "report", "target": "any", "count": 1,
		 "text_pt": "8 Biólogo: Faça o relatório final de campo", "text_en": "8 Biologist: Make the final field report", "text_es": "8 Biólogo: Haz el informe final de campo"},
	]

	if singleplayer:
		var maxn := maxi(collector.size(), biologist.size())
		for i in range(maxn):
			if i < biologist.size():
				mission_list.append(biologist[i])
			if i < collector.size():
				mission_list.append(collector[i])
	else:
		if role == "biologist":
			for m in biologist:
				mission_list.append(m)
		else:
			for m in collector:
				mission_list.append(m)
	current_mission_index = 0
	current_mission_progress = 0
	missions_complete = false

func get_current_mission() -> Dictionary:
	if current_mission_index < mission_list.size():
		return mission_list[current_mission_index]
	return {}

func get_mission_text(m: Dictionary) -> String:
	match language:
		"en": return m.get("text_en", "")
		"es": return m.get("text_es", "")
		_: return m.get("text_pt", "")

# Registra uma ação do jogador. Retorna true se a missão atual foi concluída.
func register_action(action: String, target: String) -> bool:
	if missions_complete:
		return false
	var m := get_current_mission()
	if m.is_empty():
		return false
	var ma: String = m.get("action", "")
	var mt: String = m.get("target", "")
	if action == "report" and ma == "report":
		# relatório final: qualquer interação conclui
		advance_mission()
		return true
	if action != ma:
		return false
	if mt != "any" and target != mt:
		# animais raros contam como animal para fotos
		if not (mt == "animal" and target == "rare_animal"):
			return false
	current_mission_progress += 1
	var need: int = m.get("count", 1)
	if current_mission_progress >= need:
		advance_mission()
		return true
	mission_changed.emit(current_mission_index, m)
	return false

func advance_mission() -> void:
	current_mission_progress = 0
	current_mission_index += 1
	if current_mission_index >= mission_list.size():
		missions_complete = true
	mission_changed.emit(current_mission_index, get_current_mission())

func mission_owner_allowed(owner: String) -> bool:
	return true


func first_empty_slot() -> int:
	for index in range(2):
		if index >= saved_games.size() or saved_games[index].is_empty():
			return index
	return -1

func begin_new_game(index: int, reset_missions: bool = true) -> Error:
	if index < 0 or index >= 2:
		return ERR_INVALID_PARAMETER
	var previous_games := saved_games.duplicate(true)
	var previous_slot := active_slot
	while saved_games.size() <= index:
		saved_games.append({})
	saved_games[index] = {"name": player_name, "created": Time.get_unix_time_from_system()}
	active_slot = index
	var error := save_game()
	if error != OK:
		saved_games.assign(previous_games)
		active_slot = previous_slot
		return error
	pending_snapshot.clear()
	if reset_missions:
		build_mission_list()
	return OK

func has_snapshot(index: int) -> bool:
	if index < 0 or index >= saved_games.size():
		return false
	var snapshot: Variant = saved_games[index].get("snapshot", {})
	return snapshot is Dictionary and snapshot.get("version", 0) == SAVE_VERSION

func prepare_continue(index: int) -> bool:
	if not has_snapshot(index):
		return false
	var snapshot: Dictionary = saved_games[index]["snapshot"].duplicate(true)
	singleplayer = snapshot.get("singleplayer", true)
	role = snapshot.get("role", "collector")
	player_name = saved_games[index].get("name", player_name)
	build_mission_list()
	current_mission_index = clampi(snapshot.get("mission_index", 0), 0, mission_list.size())
	missions_complete = current_mission_index == mission_list.size()
	var need: int = get_current_mission().get("count", 1)
	current_mission_progress = clampi(snapshot.get("mission_progress", 0), 0, need - 1)
	active_slot = index
	pending_snapshot = snapshot
	return true

func store_snapshot(snapshot: Dictionary) -> Error:
	if active_slot < 0 or active_slot >= saved_games.size():
		return ERR_DOES_NOT_EXIST
	var previous: Dictionary = saved_games[active_slot].duplicate(true)
	saved_games[active_slot]["snapshot"] = snapshot.duplicate(true)
	saved_games[active_slot]["updated"] = Time.get_unix_time_from_system()
	var error := save_game()
	if error != OK:
		saved_games[active_slot] = previous
	return error
