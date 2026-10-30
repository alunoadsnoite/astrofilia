extends Node

# Estado global do jogo Astrofilia
signal language_changed(lang: String)
signal mode_changed(singleplayer: bool)
signal mission_completed(mission: Dictionary)
signal mission_advanced(index: int)

const SAVE_PATH := "user://astrofilia_save.cfg"

var player_name: String = "Astronauta"
var language: String = "pt"  # pt, en, es
var sfx_volume: float = 1.0
var music_volume: float = 1.0
var appearance: String = "default"
var singleplayer: bool = true
var role: String = "collector"  # collector or biologist (multiplayer)
var achievements: Array[String] = []
var saved_games: Array[Dictionary] = []  # max 2

# Missões do tutorial
var mission_list: Array[Dictionary] = []
var current_mission_index: int = 0
var missions_complete: bool = false

# Progresso dos objetivos
var progresso: Dictionary = {
	"mineral": 0,
	"fruta": 0,
	"animal_pequeno": 0,
	"mineral_raro": 0,
	"pedra": 0,
	"cristal": 0,
	"item_raro": 0,
	"criatura": 0,
	"lago": 0,
	"fruta_verificada": 0,
	"planta_foto": 0,
	"animal_foto": 0,
	"rio": 0,
	"animal_raro": 0,
	"relatorio": 0
}

var translations := {
	"pt": {
		"play": "Jogar",
		"options": "Opções",
		"back": "Voltar",
		"singleplayer": "Um jogador",
		"multiplayer": "Multijogador",
		"new_game": "Novo jogo",
		"save_slot": "Jogo salvo",
		"empty_slot": "Vazio",
		"language": "Idioma",
		"appearance": "Aparência",
		"sound": "Efeitos sonoros",
		"music": "Música",
		"username": "Nome de usuário",
		"achievements": "Conquistas",
		"mission_final_mp": "Virem juntos para casa!",
		"mission_final_sp": "Volte para casa!",
	},
	"en": {
		"play": "Play",
		"options": "Options",
		"back": "Back",
		"singleplayer": "Singleplayer",
		"multiplayer": "Multiplayer",
		"new_game": "New game",
		"save_slot": "Saved game",
		"empty_slot": "Empty",
		"language": "Language",
		"appearance": "Appearance",
		"sound": "Sound effects",
		"music": "Music",
		"username": "Username",
		"achievements": "Achievements",
		"mission_final_mp": "Return home together!",
		"mission_final_sp": "Return home!",
	},
	"es": {
		"play": "Jugar",
		"options": "Opciones",
		"back": "Volver",
		"singleplayer": "Un jugador",
		"multiplayer": "Multijugador",
		"new_game": "Nuevo juego",
		"save_slot": "Juego guardado",
		"empty_slot": "Vacío",
		"language": "Idioma",
		"appearance": "Apariencia",
		"sound": "Efectos de sonido",
		"music": "Música",
		"username": "Nombre de usuario",
		"achievements": "Logros",
		"mission_final_mp": "¡Vuelvan a casa juntos!",
		"mission_final_sp": "¡Vuelve a casa!",
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

func save_game() -> void:
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
	cfg.save(SAVE_PATH)

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
		{"owner": "collector", "objetivo": "mineral", "meta": 1, "text_pt": "1 Coletor: Pegue um mineral próximo à nave", "text_en": "1 Collector: Get a mineral near the ship", "text_es": "1 Colector: Obtén un mineral cerca de la nave"},
		{"owner": "collector", "objetivo": "fruta", "meta": 1, "text_pt": "2 Coletor: Pegue uma fruta", "text_en": "2 Collector: Get a fruit", "text_es": "2 Colector: Obtén una fruta"},
		{"owner": "collector", "objetivo": "animal_pequeno", "meta": 1, "text_pt": "3 Coletor: Derrube um animal pequeno para comer", "text_en": "3 Collector: Defeat a small animal to eat", "text_es": "3 Colector: Derrota un animal pequeño para comer"},
		{"owner": "collector", "objetivo": "mineral_raro", "meta": 3, "text_pt": "4 Coletor: Colete 3 minerais raros", "text_en": "4 Collector: Collect 3 rare minerals", "text_es": "4 Colector: Recolecta 3 minerales raros"},
		{"owner": "collector", "objetivo": "fruta", "meta": 1, "text_pt": "5 Coletor: Pegue mais uma fruta", "text_en": "5 Collector: Get another fruit", "text_es": "5 Colector: Obtén otra fruta"},
		{"owner": "collector", "objetivo": "pedra", "meta": 5, "text_pt": "6 Coletor: Colete 5 pedras", "text_en": "6 Collector: Collect 5 stones", "text_es": "6 Colector: Recolecta 5 piedras"},
		{"owner": "collector", "objetivo": "cristal", "meta": 1, "text_pt": "7 Coletor: Encontre um cristal brilhante", "text_en": "7 Collector: Find a shiny crystal", "text_es": "7 Colector: Encuentra un cristal brillante"},
		{"owner": "collector", "objetivo": "item_raro", "meta": 1, "text_pt": "8 Coletor: Pegue o último item raro", "text_en": "8 Collector: Get the last rare item", "text_es": "8 Colector: Obtén el último item raro"},
	]
	var biologist: Array[Dictionary] = [
		{"owner": "biologist", "objetivo": "criatura", "meta": 1, "text_pt": "1 Biólogo: Faça o reconhecimento de uma criatura", "text_en": "1 Biologist: Recognize a creature", "text_es": "1 Biólogo: Reconoce una criatura"},
		{"owner": "biologist", "objetivo": "lago", "meta": 1, "text_pt": "2 Biólogo: Verifique se o lago está contaminado", "text_en": "2 Biologist: Check if the lake is contaminated", "text_es": "2 Biólogo: Verifica si el lago está contaminado"},
		{"owner": "biologist", "objetivo": "fruta_verificada", "meta": 1, "text_pt": "3 Biólogo: Verifique se a fruta é venenosa", "text_en": "3 Biologist: Check if the fruit is poisonous", "text_es": "3 Biólogo: Verifica si la fruta es venenosa"},
		{"owner": "biologist", "objetivo": "planta_foto", "meta": 1, "text_pt": "4 Biólogo: Tire uma foto de uma planta", "text_en": "4 Biologist: Take a photo of a plant", "text_es": "4 Biólogo: Toma una foto de una planta"},
		{"owner": "biologist", "objetivo": "animal_foto", "meta": 1, "text_pt": "5 Biólogo: Analise um animal com a câmera especial", "text_en": "5 Biologist: Analyze an animal with the special camera", "text_es": "5 Biólogo: Analiza un animal con la cámara especial"},
		{"owner": "biologist", "objetivo": "rio", "meta": 1, "text_pt": "6 Biólogo: Verifique a qualidade da água do rio", "text_en": "6 Biologist: Check the river water quality", "text_es": "6 Biólogo: Verifica la calidad del agua del río"},
		{"owner": "biologist", "objetivo": "animal_raro", "meta": 1, "text_pt": "7 Biólogo: Fotografe um animal raro", "text_en": "7 Biologist: Photograph a rare animal", "text_es": "7 Biólogo: Fotografía un animal raro"},
		{"owner": "biologist", "objetivo": "relatorio", "meta": 1, "text_pt": "8 Biólogo: Faça o relatório final de campo", "text_en": "8 Biologist: Make the final field report", "text_es": "8 Biólogo: Haz el informe final de campo"},
	]

	if singleplayer:
		# Alternar: biólogo, coletor, biólogo, coletor...
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
	missions_complete = false
	# Reset progresso
	for key in progresso:
		progresso[key] = 0

func get_current_mission() -> Dictionary:
	if current_mission_index < mission_list.size():
		return mission_list[current_mission_index]
	return {}

func get_mission_text(m: Dictionary) -> String:
	match language:
		"en": return m.get("text_en", "")
		"es": return m.get("text_es", "")
		_: return m.get("text_pt", "")

func get_mission_text_with_progress(m: Dictionary) -> String:
	var base: String = get_mission_text(m)
	var obj: String = str(m.get("objetivo", ""))
	var meta: int = int(m.get("meta", 1))
	var atual: int = int(progresso.get(obj, 0))
	if meta > 1:
		return base + " (%d/%d)" % [atual, meta]
	return base

func registrar_progresso(tipo: String, quantidade: int = 1) -> void:
	var m := get_current_mission()
	if m.is_empty():
		return
	var obj: String = str(m.get("objetivo", ""))
	if obj != tipo:
		return  # Progresso não é para a missão atual

	progresso[tipo] = int(progresso.get(tipo, 0)) + quantidade
	var atual: int = int(progresso[tipo])
	var meta: int = int(m.get("meta", 1))
	
	if atual >= meta:
		# Missão concluída!
		mission_completed.emit(m)
		advance_mission()
	else:
		# Atualiza progresso (sem avançar)
		mission_advanced.emit(current_mission_index)

func advance_mission() -> void:
	current_mission_index += 1
	if current_mission_index >= mission_list.size():
		missions_complete = true
	mission_advanced.emit(current_mission_index)

func mission_owner_allowed(owner: String) -> bool:
	return true

func reset_progress() -> void:
	for key in progresso:
		progresso[key] = 0
	current_mission_index = 0
	missions_complete = false
