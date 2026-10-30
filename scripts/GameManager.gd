extends Node

signal language_changed(lang: String)
signal mode_changed(singleplayer: bool)
signal mission_changed(index: int, mission: Dictionary)

const SAVE_PATH := "user://astrofilia_save.json"
const SAVE_VERSION := 2

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

# Level/XP system
var experience: int = 0
var level: int = 1
var xp_to_next_level: int = 100
var max_level: int = 50

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

func get_current_mission() -> Dictionary:
	if current_mission_index >= 0 and current_mission_index < mission_list.size():
		return mission_list[current_mission_index]
	return {}

func get_mission_text(mission: Dictionary) -> String:
	var lang := language
	if lang not in translations:
		lang = "pt"
	var t: Dictionary = translations[lang] as Dictionary
	var pt: String = mission.get("text_pt", mission.get("text_en", "")) as String
	var en: String = mission.get("text_en", "") as String
	if lang == "pt":
		return pt
	elif lang == "en":
		return en
	else:
		return mission.get("text_es", pt) as String

func advance_mission() -> void:
	current_mission_index += 1
	current_mission_progress = 0
	if current_mission_index >= mission_list.size():
		current_mission_index = 0
		missions_complete = true
	else:
		missions_complete = false

func register_action(action: String, target: String) -> bool:
	# Register a completed action
	return true

func add_achievement(achievement: String) -> void:
	if not achievements.has(achievement):
		achievements.append(achievement)

func first_empty_slot() -> int:
	# Return the first empty slot index
	for i in range(saved_games.size()):
		if saved_games[i].is_empty():
			return i
	return -1

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

func gain_experience(points: int) -> void:
	experience += points
	while experience >= xp_to_next_level and level < max_level:
		experience -= xp_to_next_level
		level += 1
		xp_to_next_level = int(xp_to_next_level * 1.5) + 20
		check_level_achievements()
	if level >= max_level:
		xp_to_next_level = 999999
	# At max level, keep remaining XP (just prevent overflow)

func check_level_achievements() -> void:
	var level_achievements := {
		2: "Nível 2 desbloqueado",
		3: "Nível 3 desbloqueado",
		5: "Nível 5 desbloqueado",
		10: "Nível 10 desbloqueado",
		20: "Nível 20 desbloqueado",
		30: "Nível 30 desbloqueado",
		40: "Nível 40 desbloqueado",
		50: "Nível 50 — LEGENDÁRIO!",
	}
	if level in level_achievements and not achievements.has(level_achievements[level]):
		achievements.append(level_achievements[level])

func build_mission_list() -> void:
	mission_list.clear()
	var collector: Array[Dictionary] = [
		{"owner": "collector", "action": "collect", "target": "mineral", "count": 1,
		 "text_pt": "1 Coletor: Pegue um mineral próximo à nave", "text_en": "1 Collector: Get a mineral near the ship", "text_es": "1 Colector: Obtén un mineral cerca de la nave"},
		{"owner": "collector", "action": "collect", "target": "fruit", "count": 1,
		 "text_pt": "2 Coletor: Pegue uma fruta", "text_en": "2 Collector: Get a fruit", "text_es": "2 Colector: Obtén una fruta"},
		{"owner": "collector", "action": "collect", "target": "animal", "count": 1,
		 "text_pt": "3 Coletor: Colete um animal pequeno para comer", "text_en": "3 Collector: Get a small animal to eat", "text_es": "3 Colector: Recolecta un animal pequeño para comer"},
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

func save_game() -> Error:
	var data := {
		"version": SAVE_VERSION,
		"player": {
			"name": player_name,
			"language": language,
			"sfx_volume": sfx_volume,
			"music_volume": music_volume,
			"appearance": appearance,
			"singleplayer": singleplayer,
			"role": role,
			"achievements": achievements,
			"experience": experience,
			"level": level,
			"xp_to_next_level": xp_to_next_level,
			"max_level": max_level,
		},
		"saves": {
			"games": saved_games,
		},
	}
	var json := JSON.stringify(data)
	var fa := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if fa == null:
		print("GameManager: cannot open " + SAVE_PATH)
		return Error.ERR_CANT_CREATE
	fa.store_string(json)
	fa.close()
	return OK

func load_game() -> void:
	var fa: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if fa == null:
		return
	var json: String = fa.get_as_string()
	fa.close()
	var parsed: Variant = JSON.parse_string(json)
	if parsed is Error:
		print("GameManager: parse error")
		return
	if parsed is Dictionary:
		var player_data: Dictionary = parsed.get("player", {}) as Dictionary
		if player_data is Dictionary:
			if player_data.has("name") and player_data.get("name") is String:
				player_name = player_data.get("name")
			if player_data.has("language") and player_data.get("language") is String:
				language = player_data.get("language")
			if player_data.has("sfx_volume") and player_data.get("sfx_volume") is float:
				sfx_volume = player_data.get("sfx_volume")
			if player_data.has("music_volume") and player_data.get("music_volume") is float:
				music_volume = player_data.get("music_volume")
			if player_data.has("appearance") and player_data.get("appearance") is String:
				appearance = player_data.get("appearance")
			if player_data.has("singleplayer") and player_data.get("singleplayer") is bool:
				singleplayer = player_data.get("singleplayer")
			if player_data.has("role") and player_data.get("role") is String:
				role = player_data.get("role")
			if player_data.has("achievements") and player_data.get("achievements") is Array:
				achievements = player_data.get("achievements")
			if player_data.has("experience") and player_data.get("experience") is int:
				experience = player_data.get("experience")
			if player_data.has("level") and player_data.get("level") is int:
				level = player_data.get("level")
			if player_data.has("xp_to_next_level") and player_data.get("xp_to_next_level") is int:
				xp_to_next_level = player_data.get("xp_to_next_level")
			if player_data.has("max_level") and player_data.get("max_level") is int:
				max_level = player_data.get("max_level")
			var saves_data: Dictionary = parsed.get("saves", {}) as Dictionary
			if saves_data is Dictionary:
				var games_list: Array = saves_data.get("games", []) as Array
				if games_list is Array:
					saved_games = games_list

func begin_new_game(slot: int, create_new: bool = true) -> Error:
	var target := slot
	if create_new:
		if slot < 0:
			return Error.ERR_INVALID_PARAMETER
		# Expand the array to accommodate the slot
		while target >= saved_games.size():
			saved_games.push_back({})
		target = slot
	else:
		if slot < 0 or slot >= saved_games.size():
			return Error.ERR_INVALID_PARAMETER
	GameManager.active_slot = target
	var slot_data := {
		"name": player_name,
		"created": Time.get_ticks_msec(),
		"snapshot": {
			"player": {
				"name": player_name,
				"language": language,
				"sfx_volume": sfx_volume,
				"music_volume": music_volume,
				"appearance": appearance,
				"singleplayer": singleplayer,
				"role": role,
				"achievements": achievements,
				"experience": experience,
				"level": level,
				"xp_to_next_level": xp_to_next_level,
				"max_level": max_level,
			},
			"survival": {
				"health": 100.0,
				"hunger": 100.0,
				"thirst": 100.0,
				"score": 0,
			},
			"gameplay": {
				"mission_index": 0,
				"mission_progress": 0,
				"time_of_day": 0.5,
				"weather": "clear",
				"weather_timer": 0.0,
				"world_seed": randi(),
			},
		},
	}
	saved_games[target] = slot_data
	return OK

func has_snapshot(slot: int) -> bool:
	if slot < 0 or slot >= saved_games.size():
		return false
	var slot_data := saved_games[slot]
	if not (slot_data is Dictionary):
		return false
	return slot_data.has("snapshot") and slot_data.get("snapshot") is Dictionary

func prepare_continue(slot: int) -> bool:
	if slot < 0 or slot >= saved_games.size():
		return false
	var slot_data := saved_games[slot]
	if not (slot_data is Dictionary):
		return false
	if not slot_data.has("snapshot") or not (slot_data.get("snapshot") is Dictionary):
		return false
	var snapshot := slot_data.get("snapshot") as Dictionary
	var player := snapshot.get("player", {}) as Dictionary
	if player is Dictionary:
		player_name = player.get("name", player_name)
		language = player.get("language", language)
		sfx_volume = player.get("sfx_volume", sfx_volume)
		music_volume = player.get("music_volume", music_volume)
		appearance = player.get("appearance", appearance)
		singleplayer = player.get("singleplayer", singleplayer)
		role = player.get("role", role)
		achievements = player.get("achievements", achievements)
		experience = player.get("experience", 0)
		level = player.get("level", 1)
		xp_to_next_level = player.get("xp_to_next_level", 100)
		max_level = player.get("max_level", 50)
	return true

func store_snapshot(snapshot: Dictionary) -> Error:
	if saved_games.is_empty():
		return Error.ERR_INVALID_PARAMETER
	var current := saved_games[saved_games.size() - 1]
	if not (current is Dictionary):
		return Error.ERR_INVALID_PARAMETER
	current["snapshot"] = snapshot.duplicate(true)
	return OK

