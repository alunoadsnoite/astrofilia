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

# Capítulos (derivados do progresso das missões)
const CHAPTERS := {
	1: {
		"pt": ["CAPÍTULO 1", "A Chegada"],
		"en": ["CHAPTER 1", "The Arrival"],
		"es": ["CAPÍTULO 1", "La Llegada"],
	},
	2: {
		"pt": ["CAPÍTULO 2", "A Nave Destruída"],
		"en": ["CHAPTER 2", "The Wrecked Ship"],
		"es": ["CAPÍTULO 2", "La Nave Destruida"],
	},
	3: {
		"pt": ["CAPÍTULO 3", "Sobrevivência"],
		"en": ["CHAPTER 3", "Survival"],
		"es": ["CAPÍTULO 3", "Supervivencia"],
	},
	4: {
		"pt": ["CAPÍTULO 4", "Segredos do Planeta"],
		"en": ["CHAPTER 4", "Secrets of the Planet"],
		"es": ["CAPÍTULO 4", "Secretos del Planeta"],
	},
	5: {
		"pt": ["CAPÍTULO 5", "O Caminho de Casa"],
		"en": ["CHAPTER 5", "The Way Home"],
		"es": ["CAPÍTULO 5", "El Camino a Casa"],
	},
}

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
	current_mission_progress = 0
	current_mission_index += 1
	if current_mission_index >= mission_list.size():
		missions_complete = true
	mission_changed.emit(current_mission_index, get_current_mission())

func register_action(action: String, target: String) -> bool:
	if missions_complete:
		return false
	var mission: Dictionary = get_current_mission()
	if mission.is_empty():
		return false
	var needed_action: String = mission.get("action", "")
	var needed_target: String = mission.get("target", "any")
	if action != needed_action:
		return false
	if needed_target != "any" and target != needed_target:
		# animais raros também contam como animal para fotografias
		if not (needed_target == "animal" and target == "rare_animal"):
			return false
	current_mission_progress += 1
	var needed: int = mission.get("count", 1)
	if current_mission_progress >= needed:
		advance_mission()
		return true
	mission_changed.emit(current_mission_index, mission)
	return false

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

# --- Capítulos ---
# 16 missões no singleplayer: cap.1 no início, cap.2 em 25%, cap.3 em 50%,
# cap.4 em 75% e cap.5 ao concluir tudo. No multiplayer (8 missões) os mesmos
# marcos caem em 2, 4, 6 e 8 missões.
func chapter_for_index(index: int) -> int:
	var total := mission_list.size()
	if total <= 0:
		return 1
	if index >= total:
		return 5
	return clampi(1 + int(float(index) / float(total) * 4.0), 1, 4)

func get_chapter_data(chapter: int) -> Array:
	var entry: Dictionary = CHAPTERS.get(clampi(chapter, 1, 5), CHAPTERS[1])
	var lang := language
	if not entry.has(lang):
		lang = "pt"
	return entry[lang]

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
	var data: Dictionary = {
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
	var json: String = JSON.stringify(data)
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
	var json: String = fa.get_as_text()
	fa.close()
	var parsed: Variant = JSON.parse_string(json)
	if not (parsed is Dictionary):
		print("GameManager: save file could not be parsed")
		return
	var data: Dictionary = parsed
	var player_data: Dictionary = data.get("player", {}) as Dictionary
	if player_data is Dictionary:
		if player_data.get("name") is String:
			player_name = player_data["name"]
		if player_data.get("language") is String:
			language = player_data["language"]
		if player_data.get("sfx_volume") is float:
			sfx_volume = player_data["sfx_volume"]
		if player_data.get("music_volume") is float:
			music_volume = player_data["music_volume"]
		if player_data.get("appearance") is String:
			appearance = player_data["appearance"]
		if player_data.get("singleplayer") is bool:
			singleplayer = player_data["singleplayer"]
		if player_data.get("role") is String:
			role = player_data["role"]
		var achievements_raw: Variant = player_data.get("achievements", [])
		if achievements_raw is Array:
			achievements.clear()
			for a in achievements_raw:
				if a is String:
					achievements.append(a)
		if player_data.get("experience") is float or player_data.get("experience") is int:
			experience = int(player_data["experience"])
		if player_data.get("level") is float or player_data.get("level") is int:
			level = int(player_data["level"])
		if player_data.get("xp_to_next_level") is float or player_data.get("xp_to_next_level") is int:
			xp_to_next_level = int(player_data["xp_to_next_level"])
		if player_data.get("max_level") is float or player_data.get("max_level") is int:
			max_level = int(player_data["max_level"])
	var saves_data: Dictionary = data.get("saves", {}) as Dictionary
	if saves_data is Dictionary:
		var games_list: Array[Dictionary] = []
		var games_raw: Variant = saves_data.get("games", [])
		if games_raw is Array:
			for item in games_raw:
				if item is Dictionary:
					games_list.append(item)
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
	var snapshot: Dictionary = slot_data["snapshot"]
	var player: Dictionary = snapshot.get("player", {}) as Dictionary
	if player is Dictionary:
		if player.get("name") is String:
			player_name = player["name"]
		if player.get("language") is String:
			language = player["language"]
		if player.get("sfx_volume") is float:
			sfx_volume = player["sfx_volume"]
		if player.get("music_volume") is float:
			music_volume = player["music_volume"]
		if player.get("appearance") is String:
			appearance = player["appearance"]
		if player.get("singleplayer") is bool:
			singleplayer = player["singleplayer"]
		if player.get("role") is String:
			role = player["role"]
		var ach: Variant = player.get("achievements", [])
		if ach is Array:
			achievements.clear()
			for a in ach:
				if a is String:
					achievements.append(a)
		experience = int(player.get("experience", experience))
		level = int(player.get("level", level))
		xp_to_next_level = int(player.get("xp_to_next_level", xp_to_next_level))
		max_level = int(player.get("max_level", max_level))
	if snapshot.get("singleplayer") is bool:
		singleplayer = snapshot["singleplayer"]
	if snapshot.get("role") is String:
		role = snapshot["role"]
	active_slot = slot
	pending_snapshot = snapshot.duplicate(true)
	build_mission_list()
	var saved_index: int = int(snapshot.get("mission_index", 0))
	current_mission_progress = int(snapshot.get("mission_progress", 0))
	if saved_index >= mission_list.size():
		current_mission_index = mission_list.size()
		missions_complete = true
	else:
		current_mission_index = clampi(saved_index, 0, mission_list.size() - 1)
		missions_complete = false
	return true

func store_snapshot(snapshot: Dictionary) -> Error:
	if saved_games.is_empty():
		return Error.ERR_INVALID_PARAMETER
	var slot := active_slot
	if slot < 0 or slot >= saved_games.size():
		slot = saved_games.size() - 1
	var current: Dictionary = saved_games[slot]
	current["snapshot"] = snapshot.duplicate(true)
	return OK

