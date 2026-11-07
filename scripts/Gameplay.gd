extends Node3D

@onready var player: CharacterBody3D = $Player
@onready var camera: Camera3D = $Camera3D
@onready var items_node: Node3D = $Items
@onready var mission_label: Label = $CanvasLayer/HUD/MissionLabel
@onready var score_label: Label = $CanvasLayer/HUD/ScoreLabel
@onready var health_bar: ProgressBar = $CanvasLayer/HUD/Bars/HealthBar
@onready var hunger_bar: ProgressBar = $CanvasLayer/HUD/Bars/HungerBar
@onready var thirst_bar: ProgressBar = $CanvasLayer/HUD/Bars/ThirstBar
@onready var health_label: Label = $CanvasLayer/HUD/Bars/HealthLabel
@onready var hunger_label: Label = $CanvasLayer/HUD/Bars/HungerLabel
@onready var thirst_label: Label = $CanvasLayer/HUD/Bars/ThirstLabel
@onready var inventory_label: Label = $CanvasLayer/HUD/InventoryLabel
@onready var level_label: Label = $CanvasLayer/HUD/LevelLabel
@onready var xp_label: Label = $CanvasLayer/HUD/XpLabel
@onready var xp_bar: ProgressBar = $CanvasLayer/HUD/XpBar
@onready var time_label: Label = $CanvasLayer/HUD/TimeLabel
@onready var chapter_banner: Control = $CanvasLayer/HUD/ChapterBanner
@onready var chapter_title: Label = $CanvasLayer/HUD/ChapterBanner/ChapterCenter/ChapterPanel/ChapterVBox/ChapterTitle
@onready var chapter_subtitle: Label = $CanvasLayer/HUD/ChapterBanner/ChapterCenter/ChapterPanel/ChapterVBox/ChapterSubtitle
@onready var popup_container: VBoxContainer = $CanvasLayer/HUD/PopupContainer
@onready var pause_panel: Panel = $CanvasLayer/PausePanel
@onready var gameover_panel: Panel = $CanvasLayer/GameOverPanel
@onready var sun: DirectionalLight3D = $Sun
@onready var touch_controls: Control = $CanvasLayer/TouchControls
@onready var joystick: Control = $CanvasLayer/TouchControls/Joystick
@onready var joystick_base: Control = $CanvasLayer/TouchControls/Joystick/Base
@onready var joystick_knob: Control = $CanvasLayer/TouchControls/Joystick/Base/Knob
@onready var jump_button: Button = $CanvasLayer/TouchControls/JumpButton
@onready var interact_button: Button = $CanvasLayer/TouchControls/InteractButton
@onready var pause_button: Button = $CanvasLayer/HUD/PauseButton
@onready var ending_overlay: ColorRect = $CanvasLayer/EndingOverlay
@onready var ending_panel: Panel = $CanvasLayer/EndingPanel
@onready var ending_title: Label = $CanvasLayer/EndingPanel/EndingMargin/EndingVBox/EndingTitle
@onready var ending_subtitle: Label = $CanvasLayer/EndingPanel/EndingMargin/EndingVBox/EndingSubtitle
@onready var ending_stats: Label = $CanvasLayer/EndingPanel/EndingMargin/EndingVBox/EndingStats
@onready var ending_continue_button: Button = $CanvasLayer/EndingPanel/EndingMargin/EndingVBox/EndingContinueButton
@onready var ending_menu_button: Button = $CanvasLayer/EndingPanel/EndingMargin/EndingVBox/EndingMenuButton

var item_scene := preload("res://scenes/Item.tscn")

# Stats
var health: float = 100.0
var hunger: float = 100.0
var thirst: float = 100.0
var score: int = 0
var inventory: Dictionary = {"mineral": 0, "fruit": 0, "plant": 0, "crystal": 0, "stone": 0}

# Ciclo de dia e noite
var time_of_day: float = 0.3  # 0..1
var day_speed: float = 0.003
var day_count: int = 1

# Weather
var weather: String = "clear"  # clear, rain, sandstorm, snow
var weather_timer: float = 0.0

# Touch
var touch_dir: Vector2 = Vector2.ZERO
var touch_fingers: Dictionary = {}

var paused: bool = false
var game_over: bool = false
var world_seed: int = 0
var scenery_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var save_error_shown: bool = false

# Progressão / capítulos
var _last_chapter: int = 0
var _chapter_tween: Tween

# Avisos de sobrevivência
var hunger_warning_cooldown: float = 0.0
var thirst_warning_cooldown: float = 0.0

# Clima e céu
var weather_root: Node3D
var rain_fx: CPUParticles3D
var snow_fx: CPUParticles3D
var sand_fx: CPUParticles3D
var dust_fx: CPUParticles3D
var stars_instance: MultiMeshInstance3D
var moon_light: DirectionalLight3D

# Nave, plataforma de pouso e bloqueio do lago.
var ship_position: Vector3 = Vector3(-24, 0, 5)
# A área jogável termina junto ao cenário do planeta. Paredes invisíveis e
# uma recuperação de gravidade impedem que o astronauta caia no vazio.
const WORLD_LIMIT := 43.5
const VOID_Y := -3.0
var boundary_body: StaticBody3D
var last_safe_position: Vector3 = Vector3(0, 1.0, 0)
# Interior da nave: robô de missões e beliche.
var robot_root: Node3D
var bed_root: Node3D
var robot_position: Vector3
var bed_position: Vector3
var robot_panel: Panel
var robot_body_label: Label
var robot_talked: bool = false
var sleep_overlay: ColorRect
var damage_overlay: ColorRect
var damage_cooldown: float = 0.0
var ship_root: Node3D
var ship_roof: MeshInstance3D
var ship_body: StaticBody3D
var ship_door_position: Vector3
var ship_inside: bool = false
var ship_entered: bool = false
var ending_started: bool = false
var lake_blocker: StaticBody3D
var lake_collider: CollisionShape3D
var sky_features: Node3D

# Otimização: o mesmo projeto mantém os gráficos no desktop e reduz o custo
# no Android (sombras, densidade de cenário, partículas e resolução 3D).
var low_end: bool = OS.has_feature("mobile")
const INTERIOR_SPAWN := Vector3(0, 1.05, 1.6)
const INTERIOR_EXIT := Vector3(0, 1.05, 3.9)
const INTERIOR_CONSOLE := Vector3(0, 1.2, -4.55)
var interior_root: Node3D
var interior_lights: Array[Light3D] = []
var console_position: Vector3 = Vector3(0, 1.2, -4.55)
var exit_hatch_position: Vector3 = INTERIOR_EXIT
var exterior_return: Vector3 = Vector3(-24, 1.0, 9.5)
var exterior_cooldowns: Array = []
var exterior_day: int = 1
var transitioning: bool = false
var enter_guard: float = 0.0

# Cobras noturnas da floresta.
var snake_root: Node3D
var snakes: Array[Node3D] = []
var snake_scene := preload("res://scripts/Snake.gd")

# Joystick analógico de 360 graus.
var joystick_index: int = -1
var joystick_vector: Vector2 = Vector2.ZERO
const JOYSTICK_DEADZONE := 0.12

func _ready() -> void:
	add_to_group("hud")
	if GameManager.mission_list.is_empty():
		GameManager.build_mission_list()
	var incoming: Dictionary = GameManager.pending_snapshot
	GameManager.in_interior = GameManager.in_interior or bool(incoming.get("in_interior", false))
	world_seed = int(incoming.get("world_seed", randi()))
	scenery_rng.seed = world_seed
	exterior_return = _vec3_from(incoming.get("interior_return", [ship_position.x, 1.0, ship_position.z + 5.0]))
	exterior_cooldowns = incoming.get("exterior_cooldowns", incoming.get("resource_cooldowns", []))
	exterior_day = maxi(1, int(incoming.get("day", 1)))
	_setup_visuals()
	if GameManager.in_interior:
		_build_interior_world()
		if incoming.is_empty():
			player.global_position = INTERIOR_SPAWN
	else:
		_spawn_items()
		_create_biomes()
		_create_boundary()
		_add_lighting()
		_create_weather_fx()
		_create_lake()
		_create_sky_features()
		_create_ship()
		_create_snakes()
		_create_landmarks()
	_setup_extra_ui()
	_setup_touch()
	_restore_snapshot(incoming)
	GameManager.pending_snapshot.clear()
	if not GameManager.in_interior and weather_timer <= 0.0:
		weather_timer = randf_range(20.0, 40.0)
	_update_day_night()
	_update_mission()
	_update_bars()
	_update_inventory()
	_update_level_ui()
	_update_weather_fx(0.0)
	_update_time_label()
	_check_chapter()
	if low_end:
		# Depois de montar o mundo, garante que nenhum cenário projete sombra.
		_disable_mobile_shadows()
	# Auto-save timer
	var timer := Timer.new()
	timer.wait_time = 10.0
	timer.autostart = true
	timer.timeout.connect(_autosave)
	add_child(timer)
	# Buttons
	$CanvasLayer/PausePanel/PauseVBox/SaveButton.pressed.connect(_manual_save)
	pause_button.pressed.connect(_toggle_pause)
	$CanvasLayer/PausePanel/PauseVBox/ResumeButton.pressed.connect(_toggle_pause)
	$CanvasLayer/PausePanel/PauseVBox/QuitButton.pressed.connect(_quit_to_menu)
	$CanvasLayer/GameOverPanel/GameOverVBox/RestartButton.pressed.connect(_restart)
	jump_button.pressed.connect(_on_jump_pressed)
	interact_button.pressed.connect(_on_interact_pressed)
	ending_continue_button.pressed.connect(_close_ending)
	ending_menu_button.pressed.connect(_ending_to_menu)
	_refresh_ending_texts()
	get_tree().auto_accept_quit = false
	if GameManager.active_slot >= 0:
		_autosave()

func _disable_mobile_shadows() -> void:
	for node in find_children("*", "MeshInstance3D", true, false):
		if is_instance_valid(player) and player.is_ancestor_of(node):
			continue
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _is_interior() -> bool:
	return GameManager.in_interior

func _vec3_from(value: Variant, fallback: Vector3 = Vector3.ZERO) -> Vector3:
	if value is Array and value.size() == 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	elif value is Vector3:
		return value
	return fallback

func _process(delta: float) -> void:
	if paused or game_over:
		return
	enter_guard = maxf(0.0, enter_guard - delta)
	# Ciclo de dia e noite (conta os dias ao atravessar a meia-noite).
	var previous_time := time_of_day
	time_of_day = fmod(time_of_day + day_speed * delta, 1.0)
	if time_of_day < previous_time:
		day_count += 1
	damage_cooldown = maxf(0.0, damage_cooldown - delta)
	_update_day_night()
	_update_time_label()
	# Fome e sede (o clima acelera ou alivia a sede)
	var thirst_rate := 0.35
	match weather:
		"sandstorm": thirst_rate = 0.55
		"rain": thirst_rate = 0.28
		"snow": thirst_rate = 0.30
	hunger = maxf(0.0, hunger - 0.22 * delta)
	thirst = maxf(0.0, thirst - thirst_rate * delta)
	hunger_warning_cooldown = maxf(0.0, hunger_warning_cooldown - delta)
	thirst_warning_cooldown = maxf(0.0, thirst_warning_cooldown - delta)
	if hunger <= 25.0 and hunger_warning_cooldown <= 0.0:
		hunger_warning_cooldown = 30.0
		_show_popup("🍖 Fome baixa! Coma uma fruta ou um animal.")
	if thirst <= 25.0 and thirst_warning_cooldown <= 0.0:
		thirst_warning_cooldown = 30.0
		_show_popup("💧 Sede baixa! Beba água no lago.")
	if hunger <= 0.0:
		health = maxf(0.0, health - 3.0 * delta)
	if thirst <= 0.0:
		health = maxf(0.0, health - 3.0 * delta)
	_update_bars()
	if health <= 0:
		_trigger_game_over()
	# Weather timer
	if not _is_interior():
		weather_timer -= delta
		if weather_timer <= 0:
			_change_weather()
	# Camera follow (o interior usa um enquadramento mais próximo).
	if player:
		var cam_offset := Vector3(0, 6.4, 8.4) if _is_interior() else Vector3(0, 12, 14)
		var target := player.global_position + cam_offset
		camera.global_position = camera.global_position.lerp(target, 1.0 - exp(-8.0 * delta))
		camera.look_at(player.global_position, Vector3.UP)
	if not _is_interior():
		_update_ship_interior(delta)
		_update_planet_bounds()
		_update_weather_fx(delta)
		_update_snakes(delta)
		_check_ship_entry()
	if is_instance_valid(robot_root):
		var clock := Time.get_ticks_msec() * 0.001
		robot_root.rotation.y = sin(clock * 0.9) * 0.12
		robot_root.position.y = 0.1 + sin(clock * 1.6) * 0.015
	_update_mission()
	_check_chapter()
	_update_hint()
	# Controles de toque -> jogador
	if player:
		player.external_move = touch_dir

func _update_day_night() -> void:
	var angle := time_of_day * TAU
	var daylight := clampf(-cos(angle), 0.0, 1.0)
	var night := 1.0 - daylight
	if _is_interior():
		# O interior tem iluminação própria; o ciclo apenas a suaviza à noite.
		sun.visible = false
		var inside_env: Environment = $WorldEnvironment.environment
		inside_env.background_mode = Environment.BG_COLOR
		inside_env.background_color = Color("05070d")
		inside_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		inside_env.ambient_light_color = Color("93a9c9").lerp(Color("d6e6ef"), daylight)
		inside_env.ambient_light_energy = lerpf(0.38, 0.56, daylight)
		inside_env.fog_enabled = false
		if not low_end:
			inside_env.glow_enabled = true
		for light in interior_lights:
			if is_instance_valid(light):
				var base_energy: float = float(light.get_meta("base_energy", light.light_energy))
				light.light_energy = base_energy * lerpf(0.72, 1.0, daylight)
		if is_instance_valid(stars_instance):
			stars_instance.visible = false
		if is_instance_valid(moon_light):
			moon_light.visible = false
		return
	sun.visible = true
	# O sol percorre o céu para gerar sombras que mudam ao longo do dia.
	sun.rotation = Vector3(-deg_to_rad(18.0 + daylight * 68.0), deg_to_rad(35.0), 0.0)
	sun.light_energy = lerpf(0.04, 1.3, daylight)
	sun.light_color = Color("b9c9ff").lerp(Color("fff0d5"), daylight)
	if is_instance_valid(moon_light):
		moon_light.light_energy = lerpf(0.0, 0.45, night)
		moon_light.visible = night > 0.02
	var env: Environment = $WorldEnvironment.environment
	env.ambient_light_energy = lerpf(0.28, 0.72, daylight)
	env.ambient_light_color = Color("818bb5").lerp(Color("dbe9f0"), daylight)
	env.fog_light_color = Color("1d2338").lerp(Color("a1c5cc"), daylight)
	match weather:
		"rain":
			env.fog_light_color = env.fog_light_color.lerp(Color("8794a3"), 0.5)
		"snow":
			env.fog_light_color = env.fog_light_color.lerp(Color("dbe8f2"), 0.5)
		"sandstorm":
			env.fog_light_color = env.fog_light_color.lerp(Color("c8a06a"), 0.7)
	var fog_density := 0.002
	match weather:
		"rain":
			fog_density = 0.009
		"snow":
			fog_density = 0.012
		"sandstorm":
			fog_density = 0.018
	env.fog_density = fog_density * lerpf(0.7, 1.5, night)
	var sky_material := env.sky.sky_material as ProceduralSkyMaterial
	sky_material.sky_top_color = Color("10152e").lerp(Color("24749c"), daylight)
	sky_material.sky_horizon_color = Color("423a62").lerp(Color("b4d8d9"), daylight)
	if is_instance_valid(stars_instance):
		stars_instance.visible = night > 0.12
		stars_instance.transparency = clampf(1.0 - night * 1.4, 0.0, 1.0)

func _change_weather() -> void:
	weather_timer = randf_range(15.0, 30.0)
	var r := randf()
	if r < 0.4:
		weather = "clear"
	elif r < 0.65:
		weather = "rain"
	elif r < 0.82:
		weather = "sandstorm"
	else:
		weather = "snow"
	_update_weather_fx(0.0)
	_update_time_label()

func _update_mission() -> void:
	var m: Dictionary = GameManager.get_current_mission()
	if m.is_empty():
		if GameManager.missions_complete:
			mission_label.text = GameManager.t("mission_final_sp") if GameManager.singleplayer else GameManager.t("mission_final_mp")
		else:
			mission_label.text = ""
	else:
		var text: String = GameManager.get_mission_text(m)
		var need: int = m.get("count", 1)
		if need > 1:
			text += "  (%d/%d)" % [GameManager.current_mission_progress, need]
		mission_label.text = text

func set_score(s: int) -> void:
	score = s
	score_label.text = "Pontos: %d" % score
	_check_achievements()

func _update_bars() -> void:
	health_bar.value = health
	hunger_bar.value = hunger
	thirst_bar.value = thirst
	if is_instance_valid(health_label):
		health_label.text = "❤ Vida %d%%" % int(round(health))
		health_label.modulate = Color(1, 0.55, 0.55) if health <= 25.0 else Color.WHITE
	if is_instance_valid(hunger_label):
		hunger_label.text = "🍖 Fome %d%%" % int(round(hunger))
		hunger_label.modulate = Color(1, 0.68, 0.4) if hunger <= 25.0 else Color.WHITE
	if is_instance_valid(thirst_label):
		thirst_label.text = "💧 Sede %d%%" % int(round(thirst))
		thirst_label.modulate = Color(0.6, 0.85, 1) if thirst <= 25.0 else Color.WHITE

func _update_level_ui() -> void:
	if not is_instance_valid(level_label) or not is_instance_valid(xp_label):
		return
	level_label.text = "NV %d" % GameManager.level
	if GameManager.level >= GameManager.max_level:
		xp_label.text = "EXP MAX"
		if is_instance_valid(xp_bar):
			xp_bar.max_value = 1.0
			xp_bar.value = 1.0
		return
	var needed := maxi(1, GameManager.xp_to_next_level)
	xp_label.text = "EXP %d/%d" % [GameManager.experience, needed]
	if is_instance_valid(xp_bar):
		xp_bar.max_value = float(needed)
		xp_bar.value = float(clampi(GameManager.experience, 0, needed))

func _gain_xp(points: int) -> void:
	var previous_level: int = GameManager.level
	GameManager.gain_experience(points)
	_update_level_ui()
	if GameManager.level > previous_level:
		# Subir de nível recupera um pouco de vida, fome e sede.
		health = minf(100.0, health + 12.0)
		hunger = minf(100.0, hunger + 10.0)
		thirst = minf(100.0, thirst + 10.0)
		_update_bars()
		Sfx.play("level")
		_show_level_up(GameManager.level)

func _update_inventory() -> void:
	var lines := ["Inventário:"]
	for k in inventory:
		lines.append("- %s: %d" % [k, inventory[k]])
	inventory_label.text = "\n".join(lines)

func _spawn_items() -> void:
	var types := ["mineral", "fruit", "plant", "crystal", "stone", "animal"]
	for i in range(30):
		var it: Node3D = item_scene.instantiate()
		var idx := i % types.size()
		var angle := i * TAU / 30.0
		var radius := 6.0 + (i % 5) * 4.0
		var pos := Vector3(cos(angle) * radius, 1.0 if types[idx] != "animal" else 0.86, sin(angle) * radius)
		# Não deixar itens boiando no lago.
		if Vector2(pos.x - lake_position.x, pos.z - lake_position.z).length() < 6.5:
			pos.z -= 14.0
			pos.x += 2.0
		# Nem sobre a plataforma/nave.
		var ship_offset := Vector2(pos.x - ship_position.x, pos.z - ship_position.z)
		if ship_offset.length() < 9.0:
			var away := ship_offset.normalized() if ship_offset.length() > 0.1 else Vector2.RIGHT
			pos.x = ship_position.x + away.x * 9.0
			pos.z = ship_position.z + away.y * 9.0
		it.position = pos
		it.tipo_item = types[idx]
		it.lake_center = lake_position
		it.ship_center = ship_position
		it.collected.connect(_on_item_collected)
		items_node.add_child(it)

func _create_snakes() -> void:
	# Cobras vivem em um nó separado de Items: a contagem de recursos e as
	# missões de coleta continuam exatamente como antes.
	snake_root = Node3D.new()
	snake_root.name = "Snakes"
	add_child(snake_root)
	var spots := [
		Vector3(-8.0, 0.18, -12.0),
		Vector3(8.0, 0.18, -9.5),
		Vector3(-7.5, 0.18, 1.5),
		Vector3(7.0, 0.18, 4.0),
		Vector3(0.0, 0.18, -14.5),
	]
	var limit := spots.size() if not low_end else 4
	for i in range(limit):
		var snake: Node3D = snake_scene.new()
		snake.name = "Snake%d" % i
		snake.position = spots[i]
		snake.lake_center = lake_position
		snake.ship_center = ship_position
		snake.defeated.connect(_on_snake_defeated)
		snake_root.add_child(snake)
		snakes.append(snake)
		# As cobras só acordam à noite; durante o dia ficam escondidas.
		snake.set_active(false)

func _update_snakes(_delta: float) -> void:
	if snakes.is_empty() or not is_instance_valid(player):
		return
	var night := _is_night()
	for snake in snakes:
		if not is_instance_valid(snake):
			continue
		if snake.health <= 0.0:
			continue
		var should := night and player.global_position.distance_to(snake.global_position) < 30.0
		if should != snake.active:
			snake.set_active(should)

func _nearest_snake() -> Node3D:
	var nearest: Node3D = null
	var best := 2.35
	for snake in snakes:
		if not is_instance_valid(snake) or not snake.active or snake.health <= 0.0:
			continue
		var d: float = player.global_position.distance_to(snake.global_position)
		if d < best:
			best = d
			nearest = snake
	return nearest

func _attack_snake(snake: Node3D) -> void:
	if not is_instance_valid(snake) or not snake.active:
		return
	snake.hit(12.0, player)
	Sfx.play("click")
	if snake.health <= 0.0:
		_gain_xp(12)
		set_score(score + 15)
		_show_popup("🐍 Cobra derrotada! O caminho da floresta está mais seguro.")
	else:
		_gain_xp(4)
		_show_popup("⚔ Cobra %d/%d ❤ • ela vai dar o bote!" % [int(ceil(snake.health)), int(snake.max_health)])

func _on_snake_defeated() -> void:
	GameManager.add_achievement("Caçador de cobras")

func _on_item_collected(type: String) -> void:
	Sfx.play("collect")
	inventory[type] = inventory.get(type, 0) + 1
	_update_inventory()
	match type:
		"fruit":
			hunger = minf(100.0, hunger + 20.0)
			thirst = minf(100.0, thirst + 6.0)
			health = minf(100.0, health + 4.0)
			_show_popup("🍎 Fruta • +20 fome, +6 sede")
		"animal":
			hunger = minf(100.0, hunger + 25.0)
			health = minf(100.0, health + 6.0)
			_show_popup("🍖 Carne • +25 fome")
		"plant":
			thirst = minf(100.0, thirst + 8.0)
			_show_popup("🌿 Planta • +8 sede")
		_:
			_show_popup("+1 %s" % type)
	_update_bars()
	_gain_xp(10)
	var completed: bool = GameManager.register_action("collect", type)
	_update_mission()
	if completed:
		Sfx.play("mission")
		_gain_xp(25)
		_show_popup("✅ Missão concluída!")
	_check_achievements()

func _show_popup(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = 1
	lbl.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	lbl.add_theme_font_size_override("font_size", 24)
	popup_container.add_child(lbl)
	# fade out
	var tw := create_tween()
	tw.tween_property(lbl, "modulate:a", 0.0, 1.5)
	tw.tween_callback(lbl.queue_free)

# Terreno único que cobre as três regiões. O shader mistura deserto, floresta
# e nevado com ruído e transições suaves, sem emendas visíveis e sem
# z-fighting (fica 2 cm acima do piso, que continua sendo o único colisor).
func _create_boundary() -> void:
	boundary_body = StaticBody3D.new()
	boundary_body.name = "PlanetBoundary"
	boundary_body.add_to_group("planet_boundary")
	add_child(boundary_body)
	var wall_height := 14.0
	var thickness := 2.0
	for i in range(4):
		var shape := BoxShape3D.new()
		shape.size = Vector3(WORLD_LIMIT * 2.0 + thickness * 2.0, wall_height, thickness)
		var collision := CollisionShape3D.new()
		collision.shape = shape
		var angle := i * PI * 0.5
		collision.position = Vector3(sin(angle) * (WORLD_LIMIT + thickness * 0.5), wall_height * 0.5, cos(angle) * (WORLD_LIMIT + thickness * 0.5))
		collision.rotation.y = angle
		boundary_body.add_child(collision)

func _update_planet_bounds() -> void:
	if not is_instance_valid(player):
		return
	var pos := player.global_position
	# Guarda o último ponto firme para devolver o astronauta se algo der errado.
	if player.is_on_floor() and pos.y > 0.0 and absf(pos.x) < WORLD_LIMIT and absf(pos.z) < WORLD_LIMIT:
		last_safe_position = pos
	if pos.y < VOID_Y or absf(pos.x) > WORLD_LIMIT + 4.0 or absf(pos.z) > WORLD_LIMIT + 4.0:
		player.global_position = last_safe_position + Vector3(0, 0.6, 0)
		player.velocity = Vector3.ZERO
		_show_popup("🧲 A gravidade do planeta trouxe você de volta")

func _create_biomes() -> void:
	var ground := MeshInstance3D.new()
	ground.name = "BiomeGround"
	var plane := PlaneMesh.new()
	plane.size = Vector2(90, 90)
	plane.subdivide_width = 16 if low_end else 40
	plane.subdivide_depth = 16 if low_end else 40
	ground.mesh = plane
	ground.position = Vector3(0, 0.02, 0)
	var material := ShaderMaterial.new()
	material.shader = load("res://assets/biome_ground.gdshader")
	ground.material_override = material
	add_child(ground)

	_build_desert_props()
	_build_forest_props()
	_build_snow_props()

	var regions := [
		{"center": Vector3(-31, 0, -10), "name": "DESERTO ROCHOSO", "label_color": Color("ffe0b0")},
		{"center": Vector3(0, 0, 0), "name": "FLORESTA", "label_color": Color("c6f5cf")},
		{"center": Vector3(27, 0, 0), "name": "NEVADO", "label_color": Color("d9f2ff")},
	]
	for region in regions:
		var label := Label3D.new()
		label.text = region["name"]
		label.position = region["center"] + Vector3(0, 3.4, 0)
		label.font_size = 56
		label.outline_size = 12
		label.modulate = region["label_color"]
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(label)

func _prop(shape: Mesh, color: Color, pos: Vector3, scale_factor: Vector3 = Vector3.ONE, rot_y: float = 0.0) -> MeshInstance3D:
	var inst := _scenery(shape, color, pos, scale_factor)
	inst.rotation.y = rot_y
	return inst

func _near_ship(pos: Vector3, radius: float = 8.5) -> bool:
	return Vector2(pos.x - ship_position.x, pos.z - ship_position.z).length() < radius

func _build_desert_props() -> void:
	# Cactos com braços laterais.
	for i in range(_n(7)):
		var base := Vector3(scenery_rng.randf_range(-38.0, -17.0), 0.0, scenery_rng.randf_range(-17.0, 17.0))
		if _near_ship(base):
			continue
		var h := scenery_rng.randf_range(1.5, 2.8)
		var trunk := CylinderMesh.new()
		trunk.top_radius = 0.22
		trunk.bottom_radius = 0.3
		trunk.height = h
		trunk.radial_segments = 8
		_prop(trunk, Color("4f8f56"), base + Vector3(0, h * 0.5, 0))
		for side in [-1.0, 1.0]:
			var arm := CylinderMesh.new()
			arm.top_radius = 0.11
			arm.bottom_radius = 0.14
			arm.height = scenery_rng.randf_range(0.5, 0.9)
			arm.radial_segments = 6
			var arm_node := _prop(arm, Color("58a05f"), base + Vector3(side * 0.42, h * 0.6, 0))
			arm_node.rotation.z = side * deg_to_rad(72)
	# Pedras e cascalho.
	for i in range(_n(14)):
		var rock := SphereMesh.new()
		rock.radius = scenery_rng.randf_range(0.25, 0.9)
		rock.height = rock.radius * scenery_rng.randf_range(0.9, 1.6)
		rock.radial_segments = 7
		var rock_pos := Vector3(scenery_rng.randf_range(-38.0, -16.0), rock.radius * 0.4, scenery_rng.randf_range(-17.0, 17.0))
		if _near_ship(rock_pos):
			continue
		_prop(rock, Color("a9614a").lightened(scenery_rng.randf_range(0.0, 0.2)), rock_pos, Vector3.ONE, scenery_rng.randf_range(0.0, TAU))
	# Tufos de capim seco.
	for i in range(_n(26)):
		var tuft := CylinderMesh.new()
		tuft.top_radius = 0.0
		tuft.bottom_radius = 0.09
		tuft.height = scenery_rng.randf_range(0.3, 0.7)
		tuft.radial_segments = 4
		var tuft_pos := Vector3(scenery_rng.randf_range(-38.0, -16.0), tuft.height * 0.5, scenery_rng.randf_range(-17.0, 17.0))
		if _near_ship(tuft_pos):
			continue
		_prop(tuft, Color("b39a5c"), tuft_pos, Vector3.ONE, scenery_rng.randf_range(0.0, TAU))

func _build_forest_props() -> void:
	# Árvores com copa em camadas (fora do lago).
	for i in range(_n(14)):
		var off := Vector3(scenery_rng.randf_range(-10.0, 10.0), 0.0, scenery_rng.randf_range(-17.0, 17.0))
		if Vector2(off.x - lake_position.x, off.z - lake_position.z).length() < 7.5:
			continue
		var h := scenery_rng.randf_range(2.4, 3.8)
		var trunk := CylinderMesh.new()
		trunk.top_radius = 0.16
		trunk.bottom_radius = 0.28
		trunk.height = h
		trunk.radial_segments = 8
		_prop(trunk, Color("5b3d22"), off + Vector3(0, h * 0.5, 0))
		for layer in range(3):
			var crown := SphereMesh.new()
			crown.radius = (1.25 - layer * 0.22) * scenery_rng.randf_range(0.9, 1.1)
			crown.height = crown.radius * 1.5
			crown.radial_segments = 10
			crown.rings = 6
			_prop(crown, Color("4f9c68").lightened(layer * 0.07 + scenery_rng.randf_range(0.0, 0.08)), off + Vector3(0, h + layer * 0.55, 0), Vector3.ONE, scenery_rng.randf_range(0.0, TAU))
	# Arbustos.
	for i in range(_n(12)):
		var bush := SphereMesh.new()
		bush.radius = scenery_rng.randf_range(0.45, 0.8)
		bush.height = bush.radius * 1.25
		bush.radial_segments = 8
		var bpos := Vector3(scenery_rng.randf_range(-10.0, 10.0), bush.radius * 0.5, scenery_rng.randf_range(-17.0, 17.0))
		if Vector2(bpos.x - lake_position.x, bpos.z - lake_position.z).length() < 6.5:
			continue
		_prop(bush, Color("3f8556").lightened(scenery_rng.randf_range(0.0, 0.12)), bpos, Vector3(1.0, 0.8, 1.0), scenery_rng.randf_range(0.0, TAU))
	# Cogumelos.
	for i in range(_n(9)):
		var mpos := Vector3(scenery_rng.randf_range(-9.0, 9.0), 0.0, scenery_rng.randf_range(-16.0, 16.0))
		if Vector2(mpos.x - lake_position.x, mpos.z - lake_position.z).length() < 6.0:
			continue
		var stem_h := scenery_rng.randf_range(0.22, 0.4)
		var stem := CylinderMesh.new()
		stem.top_radius = 0.05
		stem.bottom_radius = 0.07
		stem.height = stem_h
		stem.radial_segments = 6
		_prop(stem, Color("efe6d2"), mpos + Vector3(0, stem_h * 0.5, 0))
		var cap := SphereMesh.new()
		cap.radius = scenery_rng.randf_range(0.18, 0.3)
		cap.height = cap.radius
		cap.radial_segments = 10
		_prop(cap, Color("d8564f") if i % 2 == 0 else Color("c98a4b"), mpos + Vector3(0, stem_h, 0), Vector3(1.0, 0.7, 1.0))
	# Tufos de grama.
	for i in range(_n(30)):
		var gpos := Vector3(scenery_rng.randf_range(-10.0, 10.0), 0.0, scenery_rng.randf_range(-17.0, 17.0))
		if Vector2(gpos.x - lake_position.x, gpos.z - lake_position.z).length() < 6.0:
			continue
		var blade := CylinderMesh.new()
		blade.top_radius = 0.0
		blade.bottom_radius = 0.07
		blade.height = scenery_rng.randf_range(0.25, 0.5)
		blade.radial_segments = 4
		_prop(blade, Color("74b96f"), gpos + Vector3(0, blade.height * 0.5, 0), Vector3.ONE, scenery_rng.randf_range(0.0, TAU))

func _build_snow_props() -> void:
	# Pinheiros nevados.
	for i in range(_n(9)):
		var base := Vector3(scenery_rng.randf_range(17.0, 38.0), 0.0, scenery_rng.randf_range(-17.0, 17.0))
		var h := scenery_rng.randf_range(2.0, 3.2)
		var trunk := CylinderMesh.new()
		trunk.top_radius = 0.13
		trunk.bottom_radius = 0.22
		trunk.height = h
		trunk.radial_segments = 6
		_prop(trunk, Color("6b5a4d"), base + Vector3(0, h * 0.5, 0))
		for layer in range(3):
			var cone := CylinderMesh.new()
			cone.top_radius = 0.0
			cone.bottom_radius = 1.15 - layer * 0.25
			cone.height = 1.2 - layer * 0.15
			cone.radial_segments = 7
			_prop(cone, Color("e8f6ff").lightened(layer * 0.03), base + Vector3(0, h * 0.75 + layer * 0.62, 0), Vector3.ONE, scenery_rng.randf_range(0.0, TAU))
	# Cristais de gelo com brilho sutil.
	for i in range(_n(8)):
		var crystal := CylinderMesh.new()
		crystal.top_radius = 0.0
		crystal.bottom_radius = scenery_rng.randf_range(0.25, 0.5)
		crystal.height = scenery_rng.randf_range(0.9, 2.2)
		crystal.radial_segments = 5
		var node := _prop(crystal, Color("9ed8f0"), Vector3(scenery_rng.randf_range(17.0, 38.0), crystal.height * 0.4, scenery_rng.randf_range(-17.0, 17.0)), Vector3.ONE, scenery_rng.randf_range(0.0, TAU))
		var crystal_mat := node.material_override as StandardMaterial3D
		if crystal_mat:
			crystal_mat.emission_enabled = true
			crystal_mat.emission = Color("74c5e8")
			crystal_mat.emission_energy_multiplier = 0.35
	# Montes de neve.
	for i in range(_n(12)):
		var drift := SphereMesh.new()
		drift.radius = scenery_rng.randf_range(0.5, 1.2)
		drift.height = drift.radius * 0.55
		drift.radial_segments = 8
		_prop(drift, Color("f5fbff"), Vector3(scenery_rng.randf_range(16.0, 39.0), drift.radius * 0.2, scenery_rng.randf_range(-18.0, 18.0)))

func _add_lighting() -> void:
	var omni := OmniLight3D.new()
	omni.light_color = Color("d4eced")
	omni.light_energy = 0.35
	omni.omni_range = 30.0
	omni.position = Vector3(0, 8, 0)
	add_child(omni)
	moon_light = DirectionalLight3D.new()
	moon_light.light_color = Color("9fb6e8")
	moon_light.light_energy = 0.0
	moon_light.shadow_enabled = true
	moon_light.rotation_degrees = Vector3(-58, 40, 0)
	add_child(moon_light)
	_create_stars()

func _create_stars() -> void:
	var sphere := SphereMesh.new()
	sphere.radius = 0.09
	sphere.height = 0.18
	sphere.radial_segments = 4
	sphere.rings = 2
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = sphere
	mm.instance_count = 130 if low_end else 220
	for i in range(mm.instance_count):
		var dir := Vector3(
			scenery_rng.randf_range(-1.0, 1.0),
			scenery_rng.randf_range(0.12, 1.0),
			scenery_rng.randf_range(-1.0, 1.0)
		).normalized()
		var pos := dir * 70.0
		var s := scenery_rng.randf_range(0.45, 1.6)
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * s), pos))
		mm.set_instance_color(i, Color(0.85, 0.9, 1.0).lerp(Color(1.0, 0.86, 0.72), scenery_rng.randf()))
	stars_instance = MultiMeshInstance3D.new()
	stars_instance.name = "Stars"
	stars_instance.multimesh = mm
	stars_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var star_mat := StandardMaterial3D.new()
	star_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	star_mat.vertex_color_use_as_albedo = true
	star_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	stars_instance.material_override = star_mat
	add_child(stars_instance)

func _create_weather_fx() -> void:
	weather_root = Node3D.new()
	weather_root.name = "WeatherFX"
	add_child(weather_root)

	var rain := BoxMesh.new()
	rain.size = Vector3(0.035, 0.55, 0.035)
	var rain_mat := StandardMaterial3D.new()
	rain_mat.albedo_color = Color(0.66, 0.82, 1.0, 0.75)
	rain_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rain_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rain.material = rain_mat
	rain_fx = _make_particles(rain, Color(0.66, 0.82, 1.0, 0.8), 420, 1.1, Vector3(22, 0.6, 22), 3.0, 6.0, Vector3(0, -20.0, 0), Vector3(0, -1, 0), 4.0, 0.8, 1.4, Vector3(0, 9, 0))

	var flake := SphereMesh.new()
	flake.radius = 0.07
	flake.height = 0.14
	flake.radial_segments = 6
	flake.rings = 3
	var snow_mat := StandardMaterial3D.new()
	snow_mat.albedo_color = Color(0.95, 0.98, 1.0, 0.9)
	snow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	snow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flake.material = snow_mat
	snow_fx = _make_particles(flake, Color(0.95, 0.98, 1.0, 0.9), 320, 7.0, Vector3(22, 9, 22), 0.7, 1.5, Vector3(0, -1.2, 0), Vector3(0, -1, 0), 30.0, 0.7, 1.5, Vector3(0, 6, 0))

	var grain := BoxMesh.new()
	grain.size = Vector3(0.12, 0.05, 0.12)
	var sand_mat := StandardMaterial3D.new()
	sand_mat.albedo_color = Color(0.82, 0.68, 0.44, 0.75)
	sand_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sand_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	grain.material = sand_mat
	sand_fx = _make_particles(grain, Color(0.82, 0.68, 0.44, 0.75), 500, 2.2, Vector3(24, 6, 24), 9.0, 16.0, Vector3(0, -1.5, 0), Vector3(1, 0, 0.25), 25.0, 0.8, 1.8, Vector3(0, 4, 0))

	var mote := SphereMesh.new()
	mote.radius = 0.05
	mote.height = 0.1
	mote.radial_segments = 5
	mote.rings = 2
	var dust_mat := StandardMaterial3D.new()
	dust_mat.albedo_color = Color(0.9, 0.95, 1.0, 0.35)
	dust_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dust_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mote.material = dust_mat
	dust_fx = _make_particles(mote, Color(0.9, 0.95, 1.0, 0.35), 160, 5.0, Vector3(22, 1, 22), 0.3, 1.0, Vector3(0, 0.15, 0), Vector3(0.3, 1, 0.1), 60.0, 0.6, 1.3, Vector3(0, 0.9, 0))

func _make_particles(mesh: Mesh, color: Color, amount: int, lifetime: float, extents: Vector3, vel_min: float, vel_max: float, gravity: Vector3, direction: Vector3, spread: float, scale_min: float, scale_max: float, offset: Vector3) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.mesh = mesh
	p.amount = maxi(8, int(amount * (0.45 if low_end else 1.0)))
	p.lifetime = lifetime
	p.preprocess = lifetime
	p.local_coords = true
	p.emitting = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = extents
	p.position = offset
	p.direction = direction
	p.spread = spread
	p.gravity = gravity
	p.initial_velocity_min = vel_min
	p.initial_velocity_max = vel_max
	p.scale_amount_min = scale_min
	p.scale_amount_max = scale_max
	p.color = color
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	weather_root.add_child(p)
	return p

func _update_weather_fx(_delta: float) -> void:
	if weather_root == null or player == null:
		return
	weather_root.global_position = player.global_position
	var active := not paused and not game_over and not _is_interior()
	if is_instance_valid(rain_fx):
		rain_fx.emitting = active and weather == "rain"
	if is_instance_valid(snow_fx):
		snow_fx.emitting = active and weather == "snow"
	if is_instance_valid(sand_fx):
		sand_fx.emitting = active and weather == "sandstorm"
	if is_instance_valid(dust_fx):
		dust_fx.emitting = active and weather == "clear"

func _update_time_label() -> void:
	if not is_instance_valid(time_label):
		return
	var total_minutes := int(time_of_day * 24.0 * 60.0) % 1440
	var hours := total_minutes / 60
	var minutes := total_minutes % 60
	var icon := "☀"
	if hours < 6 or hours >= 19:
		icon = "🌙"
	match weather:
		"rain":
			icon = "🌧"
		"snow":
			icon = "❄"
		"sandstorm":
			icon = "🌪"
	time_label.text = "%s Dia %d • %02d:%02d • %s" % [icon, day_count, hours, minutes, _weather_label()]

func _weather_label() -> String:
	return {"clear": "Limpo", "rain": "Chuva", "snow": "Neve", "sandstorm": "Tempestade"}.get(weather, "Limpo")

func _is_night() -> bool:
	var hours := int(time_of_day * 24.0) % 24
	return hours < 6 or hours >= 19

func _check_chapter() -> void:
	if GameManager.mission_list.is_empty():
		return
	var chapter: int = GameManager.chapter_for_index(GameManager.current_mission_index)
	if GameManager.missions_complete:
		chapter = 5
	if chapter == _last_chapter:
		return
	var first_time := _last_chapter == 0
	_last_chapter = chapter
	_show_chapter(chapter, not first_time)

func _show_chapter(chapter: int, grant_xp: bool) -> void:
	var data: Array = GameManager.get_chapter_data(chapter)
	chapter_title.text = str(data[0])
	chapter_subtitle.text = str(data[1])
	Sfx.play("chapter")
	if grant_xp:
		_gain_xp(50)
	chapter_banner.visible = true
	chapter_banner.modulate.a = 0.0
	if _chapter_tween and _chapter_tween.is_valid():
		_chapter_tween.kill()
	_chapter_tween = create_tween()
	_chapter_tween.tween_property(chapter_banner, "modulate:a", 1.0, 0.4)
	_chapter_tween.tween_interval(3.0)
	_chapter_tween.tween_property(chapter_banner, "modulate:a", 0.0, 0.6)
	_chapter_tween.tween_callback(func() -> void: chapter_banner.visible = false)

func _show_level_up(new_level: int) -> void:
	if not is_instance_valid(popup_container):
		return
	var lbl := Label.new()
	lbl.text = "⭐ NÍVEL %d!" % new_level
	lbl.horizontal_alignment = 1
	lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.35))
	lbl.add_theme_font_size_override("font_size", 34)
	lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.1, 0.2))
	lbl.add_theme_constant_override("outline_size", 8)
	popup_container.add_child(lbl)
	var tw := create_tween()
	tw.tween_interval(1.2)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.8)
	tw.tween_callback(lbl.queue_free)

# --- Touch controls ---
var lake_position: Vector3 = Vector3(0, 0.15, 12)

func _create_lake() -> void:
	var lake := MeshInstance3D.new()
	var lm := CylinderMesh.new()
	lm.top_radius = 5.0
	lm.bottom_radius = 4.7
	lm.height = 0.35
	lm.radial_segments = 48
	lake.mesh = lm
	lake.position = lake_position
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/water.gdshader")
	lake.material_override = mat
	add_child(lake)

	# Margem de areia em volta do lago.
	var margin := MeshInstance3D.new()
	var mm := TorusMesh.new()
	mm.inner_radius = 5.0
	mm.outer_radius = 6.1
	mm.rings = 40
	mm.ring_segments = 12
	margin.mesh = mm
	margin.position = lake_position + Vector3(0, -0.04, 0)
	var margin_mat := StandardMaterial3D.new()
	margin_mat.albedo_color = Color("8f7c5f")
	margin_mat.roughness = 1.0
	margin.material_override = margin_mat
	add_child(margin)

	# Pedras na borda.
	for i in range(10):
		var angle := i * TAU / 10.0 + 0.3
		var radius := 5.5 + scenery_rng.randf_range(-0.25, 0.45)
		var rock := SphereMesh.new()
		rock.radius = scenery_rng.randf_range(0.28, 0.55)
		rock.height = rock.radius * 1.2
		rock.radial_segments = 7
		_prop(rock, Color("9a8b74"), lake_position + Vector3(cos(angle) * radius, 0.05, sin(angle) * radius), Vector3.ONE, scenery_rng.randf_range(0.0, TAU))

	# Vitórias-régias.
	for i in range(6):
		var angle := scenery_rng.randf_range(0.0, TAU)
		var radius := scenery_rng.randf_range(1.0, 3.6)
		var pad := CylinderMesh.new()
		pad.top_radius = scenery_rng.randf_range(0.28, 0.5)
		pad.bottom_radius = pad.top_radius
		pad.height = 0.04
		pad.radial_segments = 10
		_prop(pad, Color("4f9d63"), lake_position + Vector3(cos(angle) * radius, 0.20, sin(angle) * radius))

	# A água é intransponível: o jogador precisa contornar o lago pelas laterais.
	lake_blocker = StaticBody3D.new()
	lake_blocker.name = "LakeBlocker"
	lake_blocker.add_to_group("lake_blocker")
	lake_blocker.position = lake_position + Vector3(0, 2.0, 0)
	lake_collider = CollisionShape3D.new()
	var blocker_shape := CylinderShape3D.new()
	blocker_shape.radius = 5.25
	blocker_shape.height = 6.0
	lake_collider.shape = blocker_shape
	lake_blocker.add_child(lake_collider)
	add_child(lake_blocker)

func _create_sky_features() -> void:
	# Gigante gasoso com anéis e uma lua distante deixam o céu mais espacial.
	sky_features = Node3D.new()
	sky_features.name = "SkyFeatures"
	add_child(sky_features)

	var planet := MeshInstance3D.new()
	var planet_mesh := SphereMesh.new()
	planet_mesh.radius = 26.0
	planet_mesh.height = 52.0
	planet_mesh.radial_segments = 64
	planet_mesh.rings = 32
	planet.mesh = planet_mesh
	planet.position = Vector3(-112, 96, -175)
	var planet_mat := ShaderMaterial.new()
	planet_mat.shader = load("res://assets/planet_shader.gdshader")
	planet_mat.set_shader_parameter("noise_scale", 2.6)
	planet_mat.set_shader_parameter("ocean_color", Color("3d6f9e"))
	planet_mat.set_shader_parameter("continent_color", Color("9a7f55"))
	planet_mat.set_shader_parameter("desert_color", Color("c9a06c"))
	planet_mat.set_shader_parameter("ice_color", Color("e8eef4"))
	planet.material_override = planet_mat
	sky_features.add_child(planet)

	var ring := MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 34.0
	ring_mesh.outer_radius = 50.0
	ring_mesh.rings = 96
	ring_mesh.ring_segments = 8
	ring.mesh = ring_mesh
	ring.position = planet.position
	ring.rotation = Vector3(deg_to_rad(74.0), deg_to_rad(12.0), deg_to_rad(-18.0))
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = Color("cdbb9d")
	ring_mat.roughness = 0.9
	ring_mat.metallic = 0.1
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_mat.albedo_color.a = 0.72
	ring.material_override = ring_mat
	sky_features.add_child(ring)

	var moon := MeshInstance3D.new()
	var moon_mesh := SphereMesh.new()
	moon_mesh.radius = 7.0
	moon_mesh.height = 14.0
	moon_mesh.radial_segments = 32
	moon_mesh.rings = 16
	moon.mesh = moon_mesh
	moon.position = Vector3(106, 58, -150)
	var moon_mat := StandardMaterial3D.new()
	moon_mat.albedo_color = Color("d7dde6")
	moon_mat.roughness = 1.0
	moon_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	moon.material_override = moon_mat
	sky_features.add_child(moon)

func _ship_material(color: Color, metallic: float = 0.55, roughness: float = 0.38, emission: Color = Color(0, 0, 0, 0), energy: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	if energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = energy
	return material

func _ship_box(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh

func _ship_cylinder(top_radius: float, bottom_radius: float, height: float, segments: int = 24) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = segments
	return mesh

func _ship_sphere(radius: float, segments: int = 24, rings: int = 12) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = segments
	mesh.rings = rings
	return mesh

func _ship_part(parent: Node3D, mesh: Mesh, color: Color, pos: Vector3, scale_factor: Vector3 = Vector3.ONE, rot: Vector3 = Vector3.ZERO, metallic: float = 0.55, roughness: float = 0.38, emission: Color = Color(0, 0, 0, 0), energy: float = 0.0) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = pos
	part.scale = scale_factor
	part.rotation = rot
	part.material_override = _ship_material(color, metallic, roughness, emission, energy)
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if low_end else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(part)
	return part

func _ship_glass(parent: Node3D, mesh: Mesh, pos: Vector3, scale_factor: Vector3 = Vector3.ONE, rot: Vector3 = Vector3.ZERO, tint: Color = Color("8ed8f2")) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = pos
	part.scale = scale_factor
	part.rotation = rot
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(tint.r, tint.g, tint.b, 0.58)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.metallic = 0.35
	material.roughness = 0.08
	material.emission_enabled = true
	material.emission = tint
	material.emission_energy_multiplier = 0.55
	part.material_override = material
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(part)
	return part

func _ship_collider(size: Vector3, pos: Vector3, rot: Vector3 = Vector3.ZERO, parent: Node3D = null) -> CollisionShape3D:
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	collision.shape = box
	collision.position = pos
	collision.rotation = rot
	(parent if parent != null else ship_body).add_child(collision)
	return collision

func _create_ship() -> void:
	ship_root = Node3D.new()
	ship_root.name = "Ship"
	ship_root.position = ship_position
	ship_root.add_to_group("ship")
	add_child(ship_root)
	ship_body = StaticBody3D.new()
	ship_body.name = "ShipBody"
	ship_body.add_to_group("ship_body")
	ship_root.add_child(ship_body)
	ship_door_position = ship_position + Vector3(0, 1.2, 4.7)

	var hull := Color("cdd7df")
	var hull_dark := Color("7f929f")
	var steel := Color("3f4b58")
	var accent := Color("e8a34b")
	var glow := Color("7fe3ff")

	# Plataforma de pouso com marcações e luzes.
	_ship_part(ship_root, _ship_cylinder(7.4, 7.4, 0.08, 64), Color("3c434d"), Vector3(0, 0.04, 0), Vector3.ONE, Vector3.ZERO, 0.2, 0.9)
	_ship_part(ship_root, _ship_cylinder(7.0, 7.0, 0.03, 64), Color("4b535e"), Vector3(0, 0.085, 0), Vector3.ONE, Vector3.ZERO, 0.35, 0.85)
	var pad_ring := MeshInstance3D.new()
	var pad_torus := TorusMesh.new()
	pad_torus.inner_radius = 6.35
	pad_torus.outer_radius = 6.85
	pad_torus.rings = 64
	pad_torus.ring_segments = 8
	pad_ring.mesh = pad_torus
	pad_ring.position = Vector3(0, 0.105, 0)
	pad_ring.material_override = _ship_material(Color("e9b45b"), 0.3, 0.5, Color("e9b45b"), 0.5)
	ship_root.add_child(pad_ring)
	for i in range(8):
		var angle := i * TAU / 8.0
		_ship_part(ship_root, _ship_cylinder(0.09, 0.09, 0.12, 10), glow, Vector3(cos(angle) * 6.6, 0.11, sin(angle) * 6.6), Vector3.ONE, Vector3.ZERO, 0.2, 0.3, glow, 1.4)

	# Base e piso da nave (o piso interno fica em y = 0.58).
	_ship_part(ship_root, _ship_box(Vector3(4.2, 0.18, 8.2)), steel, Vector3(0, 0.20, 0))
	_ship_part(ship_root, _ship_box(Vector3(4.9, 0.30, 9.0)), hull_dark, Vector3(0, 0.43, 0), Vector3.ONE, Vector3.ZERO, 0.6, 0.4)
	_ship_part(ship_root, _ship_box(Vector3(4.3, 0.05, 8.7)), Color("2c3440"), Vector3(0, 0.585, 0), Vector3.ONE, Vector3.ZERO, 0.7, 0.45)
	for x in [-1.8, 1.8]:
		_ship_part(ship_root, _ship_box(Vector3(0.06, 0.02, 7.6)), glow, Vector3(x, 0.605, 0), Vector3.ONE, Vector3.ZERO, 0.2, 0.3, glow, 0.6)

	# Pernas de pouso com sapatas.
	for x in [-2.2, 2.2]:
		for z in [-3.6, 3.6]:
			_ship_part(ship_root, _ship_cylinder(0.14, 0.18, 0.30, 10), steel, Vector3(x, 0.15, z))
			_ship_part(ship_root, _ship_box(Vector3(0.78, 0.10, 0.78)), Color("596673"), Vector3(x, 0.05, z), Vector3.ONE, Vector3.ZERO, 0.45, 0.6)
			_ship_part(ship_root, _ship_box(Vector3(0.12, 0.34, 0.12)), hull_dark, Vector3(x * 0.9, 0.32, z * 0.95), Vector3.ONE, Vector3(x * 0.05, 0, z * 0.04))

	# Casco: paredes laterais, parede traseira e frente com vão de porta.
	var wall_height := 2.52
	var wall_y := 1.84
	_ship_part(ship_root, _ship_box(Vector3(0.30, wall_height, 9.0)), hull, Vector3(-2.35, wall_y, 0), Vector3.ONE, Vector3.ZERO, 0.65, 0.32)
	_ship_part(ship_root, _ship_box(Vector3(0.30, wall_height, 9.0)), hull, Vector3(2.35, wall_y, 0), Vector3.ONE, Vector3.ZERO, 0.65, 0.32)
	_ship_part(ship_root, _ship_box(Vector3(5.0, wall_height, 0.30)), hull, Vector3(0, wall_y, -4.35), Vector3.ONE, Vector3.ZERO, 0.65, 0.32)
	_ship_part(ship_root, _ship_box(Vector3(1.55, wall_height, 0.30)), hull, Vector3(-1.725, wall_y, 4.35), Vector3.ONE, Vector3.ZERO, 0.65, 0.32)
	_ship_part(ship_root, _ship_box(Vector3(1.55, wall_height, 0.30)), hull, Vector3(1.725, wall_y, 4.35), Vector3.ONE, Vector3.ZERO, 0.65, 0.32)
	_ship_part(ship_root, _ship_box(Vector3(1.9, 0.60, 0.30)), hull, Vector3(0, 2.80, 4.35), Vector3.ONE, Vector3.ZERO, 0.65, 0.32)

	# Colisores: piso, paredes e vão da porta.
	_ship_collider(Vector3(4.9, 0.30, 9.0), Vector3(0, 0.43, 0))
	_ship_collider(Vector3(0.30, wall_height, 9.0), Vector3(-2.35, wall_y, 0))
	_ship_collider(Vector3(0.30, wall_height, 9.0), Vector3(2.35, wall_y, 0))
	_ship_collider(Vector3(5.0, wall_height, 0.30), Vector3(0, wall_y, -4.35))
	_ship_collider(Vector3(1.55, wall_height, 0.30), Vector3(-1.725, wall_y, 4.35))
	_ship_collider(Vector3(1.55, wall_height, 0.30), Vector3(1.725, wall_y, 4.35))
	_ship_collider(Vector3(1.9, 0.60, 0.30), Vector3(0, 2.80, 4.35))
	_ship_collider(Vector3(3.8, 1.8, 2.6), Vector3(0, 1.55, -5.5))

	# Teto separado para a câmera enxergar o interior.
	ship_roof = _ship_part(ship_root, _ship_box(Vector3(5.0, 0.22, 9.0)), hull, Vector3(0, 3.22, 0), Vector3.ONE, Vector3.ZERO, 0.65, 0.32)
	ship_roof.name = "ShipRoof"
	ship_roof.transparency = 0.0
	for x in [-2.15, 2.15]:
		_ship_part(ship_root, _ship_box(Vector3(0.34, 0.12, 9.0)), hull_dark, Vector3(x, 3.36, 0), Vector3.ONE, Vector3.ZERO, 0.6, 0.42)
	for z in [-2.6, 0.0, 2.6]:
		_ship_part(ship_root, _ship_box(Vector3(1.7, 0.045, 0.16)), accent, Vector3(0, 3.345, z), Vector3.ONE, Vector3.ZERO, 0.4, 0.45, accent, 0.25)

	# Detalhes externos: painéis, nervuras e janelas.
	for x in [-2.52, 2.52]:
		_ship_part(ship_root, _ship_box(Vector3(0.07, 0.82, 7.4)), Color("aebdc8"), Vector3(x, 1.20, 0), Vector3.ONE, Vector3.ZERO, 0.7, 0.3)
		for z in [-3.9, -1.25, 1.25, 3.9]:
			_ship_part(ship_root, _ship_box(Vector3(0.12, 2.35, 0.12)), hull_dark, Vector3(x * 1.015, 1.82, z), Vector3.ONE, Vector3.ZERO, 0.6, 0.42)
	for side in [-1.0, 1.0]:
		for z in [-2.45, 0.05, 2.45]:
			_ship_part(ship_root, _ship_box(Vector3(0.08, 0.70, 0.94)), steel, Vector3(side * 2.534, 2.35, z), Vector3.ONE, Vector3.ZERO, 0.55, 0.4)
			_ship_glass(ship_root, _ship_box(Vector3(0.055, 0.56, 0.78)), Vector3(side * 2.572, 2.35, z), Vector3.ONE, Vector3.ZERO, Color("86d9f4"))

	# Nariz cônico, cabine e luz de proa.
	var collar := TorusMesh.new()
	collar.inner_radius = 2.16
	collar.outer_radius = 2.38
	collar.rings = 40
	collar.ring_segments = 8
	_ship_part(ship_root, collar, steel, Vector3(0, 1.84, -4.58), Vector3(1.0, 1.0, 0.46), Vector3(deg_to_rad(90), 0, 0), 0.7, 0.35)
	var nose := _ship_part(ship_root, _ship_cylinder(0.0, 2.30, 2.5, 32), hull, Vector3(0, 1.84, -5.85), Vector3(1.0, 1.0, 0.46), Vector3(deg_to_rad(-90), 0, 0), 0.62, 0.34)
	nose.name = "NoseCone"
	_ship_part(ship_root, _ship_cylinder(1.36, 1.48, 0.18, 32), steel, Vector3(0, 3.04, -3.55))
	_ship_glass(ship_root, _ship_sphere(1.0, 32, 16), Vector3(0, 3.12, -3.55), Vector3(1.02, 0.62, 1.55), Vector3.ZERO, Color("77c8e8"))
	for x in [-0.52, 0.0, 0.52]:
		_ship_part(ship_root, _ship_box(Vector3(0.055, 0.06, 2.7)), steel, Vector3(x, 3.46, -3.55), Vector3.ONE, Vector3.ZERO, 0.7, 0.3)
	_ship_part(ship_root, _ship_sphere(0.13, 12, 6), Color("ffd27f"), Vector3(0, 1.55, -7.0), Vector3.ONE, Vector3.ZERO, 0.2, 0.3, Color("ffd27f"), 2.0)

	# Motores laranja/azuis ladeando a porta.
	for x in [-2.72, 2.72]:
		_ship_part(ship_root, _ship_cylinder(0.46, 0.46, 1.9, 20), steel, Vector3(x, 1.02, 3.35), Vector3.ONE, Vector3(deg_to_rad(90), 0, 0), 0.8, 0.25)
		_ship_part(ship_root, _ship_box(Vector3(0.55, 0.25, 1.25)), hull_dark, Vector3(x * 0.87, 1.02, 3.35), Vector3.ONE, Vector3.ZERO, 0.65, 0.4)
		_ship_part(ship_root, _ship_cylinder(0.52, 0.34, 0.38, 20), Color("2a3038"), Vector3(x, 1.02, 4.42), Vector3.ONE, Vector3(deg_to_rad(90), 0, 0), 0.7, 0.35)
		_ship_part(ship_root, _ship_cylinder(0.34, 0.34, 0.04, 20), glow, Vector3(x, 1.02, 4.62), Vector3.ONE, Vector3(deg_to_rad(90), 0, 0), 0.2, 0.2, glow, 2.2)
		var exhaust := OmniLight3D.new()
		exhaust.light_color = Color("70d8ff")
		exhaust.light_energy = 0.7
		exhaust.omni_range = 4.0
		exhaust.position = Vector3(x, 1.02, 4.75)
		ship_root.add_child(exhaust)

	# Antena lateral, luz de sinalização e nome da nave.
	_ship_part(ship_root, _ship_cylinder(0.04, 0.06, 1.7, 8), steel, Vector3(-2.55, 3.35, 2.0))
	_ship_part(ship_root, _ship_cylinder(0.46, 0.34, 0.08, 16), Color("b7c4cf"), Vector3(-2.55, 4.2, 2.0), Vector3.ONE, Vector3(deg_to_rad(28), 0, 0), 0.7, 0.3)
	_ship_part(ship_root, _ship_sphere(0.09, 10, 5), Color("ff6b5f"), Vector3(-2.55, 4.25, 2.0), Vector3.ONE, Vector3.ZERO, 0.2, 0.3, Color("ff6b5f"), 2.0)
	var ship_label := Label3D.new()
	ship_label.text = "NAVE"
	ship_label.position = Vector3(0, 4.35, 0)
	ship_label.font_size = 64
	ship_label.outline_size = 14
	ship_label.modulate = Color("e9f6ff")
	ship_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	ship_root.add_child(ship_label)

	# Rampa caminhável (ângulo de ~8°, abaixo do limite de 45° do jogador).
	var ramp_root := Node3D.new()
	ramp_root.name = "Ramp"
	ramp_root.position = Vector3(0, 0.245, 6.5)
	ramp_root.rotation.x = atan(0.53 / 3.9)
	ship_root.add_child(ramp_root)
	_ship_part(ramp_root, _ship_box(Vector3(1.9, 0.14, 3.98)), hull_dark, Vector3.ZERO, Vector3.ONE, Vector3.ZERO, 0.6, 0.42)
	_ship_part(ramp_root, _ship_box(Vector3(1.72, 0.02, 3.80)), Color("8b9ba7"), Vector3(0, 0.075, 0), Vector3.ONE, Vector3.ZERO, 0.55, 0.45)
	for i in range(6):
		_ship_part(ramp_root, _ship_box(Vector3(1.68, 0.025, 0.07)), accent, Vector3(0, 0.09, -1.62 + i * 0.65), Vector3.ONE, Vector3.ZERO, 0.3, 0.5)
	for x in [-0.98, 0.98]:
		_ship_part(ramp_root, _ship_box(Vector3(0.07, 0.20, 3.98)), steel, Vector3(x, 0.15, 0), Vector3.ONE, Vector3.ZERO, 0.6, 0.4)
	var ramp_body := StaticBody3D.new()
	ramp_body.name = "RampBody"
	ramp_root.add_child(ramp_body)
	_ship_collider(Vector3(1.9, 0.14, 3.98), Vector3.ZERO, Vector3.ZERO, ramp_body)

	# Porta aberta, dobradiça e moldura iluminada.
	for x in [-1.0, 1.0]:
		_ship_part(ship_root, _ship_box(Vector3(0.16, 2.18, 0.16)), steel, Vector3(x, 1.63, 4.50), Vector3.ONE, Vector3.ZERO, 0.7, 0.32)
		_ship_part(ship_root, _ship_box(Vector3(0.04, 2.0, 0.05)), glow, Vector3(x * 0.97, 1.63, 4.60), Vector3.ONE, Vector3.ZERO, 0.2, 0.3, glow, 1.1)
	_ship_part(ship_root, _ship_box(Vector3(2.16, 0.16, 0.16)), steel, Vector3(0, 2.66, 4.50), Vector3.ONE, Vector3.ZERO, 0.7, 0.32)
	_ship_part(ship_root, _ship_box(Vector3(1.9, 0.04, 0.08)), glow, Vector3(0, 2.57, 4.61), Vector3.ONE, Vector3.ZERO, 0.2, 0.3, glow, 1.0)
	var door_hinge := Node3D.new()
	door_hinge.position = Vector3(1.0, 1.60, 4.60)
	door_hinge.rotation.y = deg_to_rad(105.0)
	ship_root.add_child(door_hinge)
	_ship_part(door_hinge, _ship_box(Vector3(1.72, 2.0, 0.12)), hull, Vector3(-0.86, 0, 0), Vector3.ONE, Vector3.ZERO, 0.6, 0.35)
	_ship_glass(door_hinge, _ship_box(Vector3(0.62, 0.62, 0.05)), Vector3(-0.86, 0.28, 0.075), Vector3.ONE, Vector3.ZERO, Color("8ed8f2"))

	# Airlock fechado: o interior real é um cenário separado, carregado ao entrar.
	var airlock := _ship_part(ship_root, _ship_box(Vector3(3.9, 2.35, 0.14)), Color("1b232e"), Vector3(0, 1.72, 3.92), Vector3.ONE, Vector3.ZERO, 0.5, 0.5)
	airlock.name = "Airlock"
	_ship_part(ship_root, _ship_box(Vector3(2.9, 0.06, 0.06)), glow, Vector3(0, 2.55, 3.84), Vector3.ONE, Vector3.ZERO, 0.2, 0.3, glow, 1.2)
	_ship_part(ship_root, _ship_box(Vector3(1.1, 0.16, 0.08)), accent, Vector3(0, 1.25, 3.83), Vector3.ONE, Vector3.ZERO, 0.3, 0.4, accent, 0.5)
	_ship_collider(Vector3(3.9, 2.35, 0.14), Vector3(0, 1.72, 3.92))
	var airlock_label := Label3D.new()
	airlock_label.text = "AIRLOCK • ENTRAR"
	airlock_label.position = Vector3(0, 2.05, 3.80)
	airlock_label.font_size = 34
	airlock_label.outline_size = 8
	airlock_label.modulate = Color("9feeff")
	airlock_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	ship_root.add_child(airlock_label)

func _build_interior_world() -> void:
	# Cenário separado: a nave por dentro. Nada do planeta é montado aqui.
	$Ground.visible = false
	var ground_collision := $Ground.get_node_or_null("Collision")
	if ground_collision:
		ground_collision.disabled = true
	player.global_position = INTERIOR_SPAWN
	camera.global_position = INTERIOR_SPAWN + Vector3(0, 6.4, 8.4)
	interior_root = Node3D.new()
	interior_root.name = "ShipInterior"
	add_child(interior_root)

	var hull := Color("cdd7df")
	var hull_dark := Color("6f8291")
	var steel := Color("3c4856")
	var accent := Color("e8a34b")
	var glow := Color("7fe3ff")
	var warm := Color("ffe2b8")
	var floor_color := Color("2b3542")

	# Piso e rodapés.
	_ship_part(interior_root, _ship_box(Vector3(10.4, 0.20, 12.4)), floor_color, Vector3(0, 0, 0), Vector3.ONE, Vector3.ZERO, 0.75, 0.5)
	_ship_collider(Vector3(10.4, 0.20, 12.4), Vector3(0, 0, 0), Vector3.ZERO, interior_root)
	for x in [-5.1, 5.1]:
		_ship_part(interior_root, _ship_box(Vector3(0.12, 0.22, 12.4)), hull_dark, Vector3(x, 0.16, 0), Vector3.ONE, Vector3.ZERO, 0.6, 0.4)
	_ship_part(interior_root, _ship_box(Vector3(3.8, 0.025, 2.6)), Color("24515c"), Vector3(0, 0.115, 0.7), Vector3.ONE, Vector3.ZERO, 0.2, 0.85)
	_ship_part(interior_root, _ship_box(Vector3(3.3, 0.02, 2.1)), Color("2f6f78"), Vector3(0, 0.125, 0.7), Vector3.ONE, Vector3.ZERO, 0.2, 0.85)

	# Paredes laterais, traseira e frente com escotilha.
	var wall_height := 3.9
	var wall_y := 1.95
	_ship_part(interior_root, _ship_box(Vector3(0.30, wall_height, 12.4)), hull, Vector3(-5.05, wall_y, 0), Vector3.ONE, Vector3.ZERO, 0.65, 0.34)
	_ship_part(interior_root, _ship_box(Vector3(0.30, wall_height, 12.4)), hull, Vector3(5.05, wall_y, 0), Vector3.ONE, Vector3.ZERO, 0.65, 0.34)
	_ship_part(interior_root, _ship_box(Vector3(10.4, wall_height, 0.30)), hull, Vector3(0, wall_y, -6.05), Vector3.ONE, Vector3.ZERO, 0.65, 0.34)
	for x in [-3.15, 3.15]:
		_ship_part(interior_root, _ship_box(Vector3(4.10, wall_height, 0.30)), hull, Vector3(x, wall_y, 6.05), Vector3.ONE, Vector3.ZERO, 0.65, 0.34)
	_ship_part(interior_root, _ship_box(Vector3(2.30, 1.30, 0.30)), hull, Vector3(0, 3.25, 6.05), Vector3.ONE, Vector3.ZERO, 0.65, 0.34)
	_ship_collider(Vector3(0.30, wall_height, 12.4), Vector3(-5.05, wall_y, 0), Vector3.ZERO, interior_root)
	_ship_collider(Vector3(0.30, wall_height, 12.4), Vector3(5.05, wall_y, 0), Vector3.ZERO, interior_root)
	_ship_collider(Vector3(10.4, wall_height, 0.30), Vector3(0, wall_y, -6.05), Vector3.ZERO, interior_root)
	_ship_collider(Vector3(4.10, wall_height, 0.30), Vector3(-3.15, wall_y, 6.05), Vector3.ZERO, interior_root)
	_ship_collider(Vector3(4.10, wall_height, 0.30), Vector3(3.15, wall_y, 6.05), Vector3.ZERO, interior_root)
	# A escotilha é interativa, mas mantém o astronauta dentro da sala.
	_ship_collider(Vector3(2.30, wall_height, 0.30), Vector3(0, wall_y, 6.05), Vector3.ZERO, interior_root)

	# Vigas e faixas de luz no teto (a sala é um corte, sem teto sólido).
	for z in [-4.6, -2.0, 0.6, 3.2, 5.4]:
		_ship_part(interior_root, _ship_box(Vector3(9.4, 0.18, 0.20)), hull_dark, Vector3(0, 3.82, z), Vector3.ONE, Vector3.ZERO, 0.6, 0.4)
	for z in [-3.2, 0.0, 3.0]:
		_ship_part(interior_root, _ship_box(Vector3(3.0, 0.035, 0.15)), warm, Vector3(0, 3.68, z), Vector3.ONE, Vector3.ZERO, 0.2, 0.3, warm, 1.3)
	for x in [-4.6, 4.6]:
		_ship_part(interior_root, _ship_box(Vector3(0.10, 0.10, 11.6)), accent, Vector3(x, 3.42, 0), Vector3.ONE, Vector3.ZERO, 0.35, 0.4, accent, 0.25)

	# Janelas laterais com o vazio estrelado do espaço.
	for side in [-1.0, 1.0]:
		_ship_part(interior_root, _ship_box(Vector3(0.12, 1.45, 2.35)), steel, Vector3(side * 4.92, 2.05, -1.1), Vector3.ONE, Vector3.ZERO, 0.6, 0.35)
		_ship_glass(interior_root, _ship_box(Vector3(0.05, 1.00, 1.85)), Vector3(side * 4.86, 2.05, -1.1), Vector3.ONE, Vector3.ZERO, Color("12283f"))
		_ship_glass(interior_root, _ship_box(Vector3(0.045, 0.10, 1.85)), Vector3(side * 4.84, 2.05, -1.1), Vector3.ONE, Vector3.ZERO, Color("6fdcff"))

	# Armários, caixas e tubulações nas laterais.
	for z in [-4.9, -3.2]:
		_ship_part(interior_root, _ship_box(Vector3(1.20, 2.10, 1.05)), Color("54626f"), Vector3(-4.25, 1.15, z), Vector3.ONE, Vector3.ZERO, 0.55, 0.45)
		_ship_part(interior_root, _ship_box(Vector3(0.90, 0.08, 0.06)), accent, Vector3(-4.25, 1.55, z + 0.54), Vector3.ONE, Vector3.ZERO, 0.3, 0.4)
	for i in range(3):
		_ship_part(interior_root, _ship_box(Vector3(0.72, 0.62, 0.72)), Color("7a6046").lightened(i * 0.06), Vector3(4.10 - i * 0.12, 0.42 + i * 0.0, 4.35 - i * 0.85), Vector3.ONE, Vector3(0, i * 0.25, 0), 0.5, 0.65)
	for side in [-1.0, 1.0]:
		_ship_part(interior_root, _ship_cylinder(0.10, 0.10, 7.6, 10), steel, Vector3(side * 4.62, 3.30, 0), Vector3.ONE, Vector3(deg_to_rad(90), 0, 0), 0.7, 0.35)
		_ship_part(interior_root, _ship_cylinder(0.06, 0.06, 7.6, 8), accent, Vector3(side * 4.62, 3.10, 0), Vector3.ONE, Vector3(deg_to_rad(90), 0, 0), 0.4, 0.4, accent, 0.3)

	# Console de voo no fundo da sala.
	_ship_part(interior_root, _ship_box(Vector3(3.30, 0.90, 1.10)), steel, Vector3(0, 0.55, -4.95), Vector3.ONE, Vector3.ZERO, 0.7, 0.35)
	_ship_part(interior_root, _ship_box(Vector3(3.50, 0.12, 1.30)), Color("596673"), Vector3(0, 1.04, -4.85), Vector3.ONE, Vector3(deg_to_rad(-7), 0, 0), 0.65, 0.35)
	_ship_part(interior_root, _ship_box(Vector3(2.70, 1.00, 0.08)), Color("16323d"), Vector3(0, 1.78, -5.35), Vector3.ONE, Vector3(deg_to_rad(-10), 0, 0), 0.3, 0.25)
	_ship_part(interior_root, _ship_box(Vector3(2.48, 0.80, 0.05)), Color("49d8c4"), Vector3(0, 1.79, -5.30), Vector3.ONE, Vector3(deg_to_rad(-10), 0, 0), 0.2, 0.2, Color("49d8c4"), 1.5)
	_ship_part(interior_root, _ship_box(Vector3(1.10, 0.05, 0.05)), Color("bdf7ee"), Vector3(0, 1.60, -5.26), Vector3.ONE, Vector3.ZERO, 0.2, 0.2, Color("bdf7ee"), 1.8)
	for x in [-1.05, 1.05]:
		_ship_part(interior_root, _ship_box(Vector3(0.22, 0.14, 0.16)), Color("ffb45c"), Vector3(x, 1.16, -4.55), Vector3.ONE, Vector3.ZERO, 0.2, 0.3, Color("ffb45c"), 1.4)
	_ship_collider(Vector3(3.40, 1.30, 1.20), Vector3(0, 0.65, -4.95), Vector3.ZERO, interior_root)
	console_position = INTERIOR_CONSOLE

	# Escotilha de saída.
	_ship_part(interior_root, _ship_cylinder(1.12, 1.12, 0.22, 32), steel, Vector3(0, 1.15, 5.92), Vector3.ONE, Vector3(deg_to_rad(90), 0, 0), 0.7, 0.35)
	var hatch_ring := TorusMesh.new()
	hatch_ring.inner_radius = 0.86
	hatch_ring.outer_radius = 1.04
	hatch_ring.rings = 32
	hatch_ring.ring_segments = 8
	_ship_part(interior_root, hatch_ring, glow, Vector3(0, 1.15, 6.04), Vector3.ONE, Vector3(deg_to_rad(90), 0, 0), 0.2, 0.25, glow, 1.5)
	_ship_part(interior_root, _ship_box(Vector3(0.62, 0.16, 0.10)), accent, Vector3(0, 1.15, 6.08), Vector3.ONE, Vector3.ZERO, 0.35, 0.4, accent, 0.7)
	var hatch_label := Label3D.new()
	hatch_label.text = "ESCOTILHA"
	hatch_label.position = Vector3(0, 2.62, 5.95)
	hatch_label.font_size = 34
	hatch_label.outline_size = 8
	hatch_label.modulate = Color("9feeff")
	hatch_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	interior_root.add_child(hatch_label)
	exit_hatch_position = Vector3(0, 1.05, 5.05)

	# Iluminação interna, registrada para escurecer com a noite.
	_add_interior_light(Vector3(0, 3.15, 0.6), Color("ffe6c7"), 1.15, 9.0)
	_add_interior_light(Vector3(0, 2.35, -4.6), Color("54e6d4"), 0.95, 4.8)
	_add_interior_light(Vector3(-3.2, 1.7, -2.4), Color("62e6d4"), 0.55, 3.4)
	_add_interior_light(Vector3(3.1, 1.9, 1.5), Color("ffd9a6"), 0.55, 3.4)
	_add_interior_light(Vector3(0, 2.1, 5.1), Color("6fdcff"), 0.75, 4.2)

	_create_crew_quarters()

func _add_interior_light(pos: Vector3, color: Color, energy: float, light_range: float) -> void:
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = energy
	light.omni_range = light_range
	light.position = pos
	light.set_meta("base_energy", energy)
	interior_lights.append(light)
	interior_root.add_child(light)

func _create_crew_quarters() -> void:
	# ARIA: robô que envia e acompanha as missões dentro da nave.
	robot_root = Node3D.new()
	robot_root.name = "MissionRobot"
	robot_root.position = Vector3(-3.2, 0.10, -2.4)
	interior_root.add_child(robot_root)
	var dark := Color("2b3440")
	var shell := Color("cdd7df")
	var cyan := Color("5ce0d0")
	_ship_part(robot_root, _ship_cylinder(0.34, 0.42, 0.16, 16), dark, Vector3(0, 0.08, 0), Vector3.ONE, Vector3.ZERO, 0.7, 0.35)
	_ship_part(robot_root, _ship_cylinder(0.24, 0.30, 0.72, 16), shell, Vector3(0, 0.52, 0), Vector3.ONE, Vector3.ZERO, 0.5, 0.3)
	_ship_part(robot_root, _ship_sphere(0.27, 16, 8), shell, Vector3(0, 1.06, 0), Vector3(1.0, 0.92, 0.9), Vector3.ZERO, 0.45, 0.28)
	_ship_part(robot_root, _ship_box(Vector3(0.36, 0.11, 0.06)), cyan, Vector3(0, 1.10, 0.24), Vector3.ONE, Vector3.ZERO, 0.2, 0.2, cyan, 1.5)
	_ship_part(robot_root, _ship_box(Vector3(0.16, 0.16, 0.04)), cyan, Vector3(0, 0.58, 0.29), Vector3.ONE, Vector3.ZERO, 0.2, 0.2, cyan, 1.1)
	for side in [-1.0, 1.0]:
		_ship_part(robot_root, _ship_cylinder(0.055, 0.06, 0.52, 8), dark, Vector3(side * 0.33, 0.52, 0), Vector3.ONE, Vector3(0, 0, side * 0.35), 0.6, 0.4)
		_ship_part(robot_root, _ship_sphere(0.075, 8, 4), cyan, Vector3(side * 0.42, 0.27, 0), Vector3.ONE, Vector3.ZERO, 0.2, 0.2, cyan, 0.8)
	_ship_part(robot_root, _ship_cylinder(0.025, 0.03, 0.32, 8), dark, Vector3(0, 1.36, 0))
	_ship_part(robot_root, _ship_sphere(0.065, 10, 5), cyan, Vector3(0, 1.54, 0), Vector3.ONE, Vector3.ZERO, 0.2, 0.2, cyan, 2.0)
	var label := Label3D.new()
	label.text = "ARIA"
	label.position = Vector3(0, 1.78, 0)
	label.font_size = 42
	label.outline_size = 10
	label.modulate = Color("8ff3e4")
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	robot_root.add_child(label)
	var robot_light := OmniLight3D.new()
	robot_light.light_color = Color("62e6d4")
	robot_light.light_energy = 0.55
	robot_light.omni_range = 3.0
	robot_light.position = Vector3(0, 1.2, 0)
	robot_light.set_meta("base_energy", 0.55)
	robot_root.add_child(robot_light)
	interior_lights.append(robot_light)
	_ship_collider(Vector3(0.85, 1.35, 0.65), Vector3(-3.2, 0.8, -2.4), Vector3.ZERO, interior_root)
	robot_position = Vector3(-3.2, 1.0, -2.4)

	# Beliche de duas camas, encostado na parede direita.
	bed_root = Node3D.new()
	bed_root.name = "BunkBed"
	bed_root.position = Vector3(3.15, 0.10, 1.5)
	interior_root.add_child(bed_root)
	var frame := Color("7d8a96")
	var mattress := Color("5f8fc4")
	var pillow := Color("e8eef5")
	var blanket := Color("2d5f8f")
	for x in [-0.55, 0.55]:
		for z in [-1.15, 1.15]:
			_ship_part(bed_root, _ship_box(Vector3(0.10, 1.85, 0.10)), frame, Vector3(x, 0.92, z), Vector3.ONE, Vector3.ZERO, 0.7, 0.35)
	for y in [0.52, 1.52]:
		_ship_part(bed_root, _ship_box(Vector3(1.12, 0.12, 2.36)), frame, Vector3(0, y, 0), Vector3.ONE, Vector3.ZERO, 0.65, 0.4)
		_ship_part(bed_root, _ship_box(Vector3(1.02, 0.16, 2.20)), mattress, Vector3(0, y + 0.13, 0), Vector3.ONE, Vector3.ZERO, 0.25, 0.65)
		_ship_part(bed_root, _ship_box(Vector3(0.72, 0.10, 0.40)), pillow, Vector3(0, y + 0.24, -0.82), Vector3.ONE, Vector3.ZERO, 0.1, 0.85)
		_ship_part(bed_root, _ship_box(Vector3(1.00, 0.05, 1.10)), blanket, Vector3(0, y + 0.22, 0.48), Vector3.ONE, Vector3.ZERO, 0.2, 0.75)
	for i in range(4):
		_ship_part(bed_root, _ship_box(Vector3(0.06, 0.05, 1.15)), frame, Vector3(-0.62, 0.28 + i * 0.42, 0.2))
	_ship_collider(Vector3(1.25, 1.9, 2.5), Vector3(3.15, 0.95, 1.5), Vector3.ZERO, interior_root)
	bed_position = Vector3(3.15, 1.0, 1.5)

func _near_robot() -> bool:
	return _is_interior() and player.global_position.distance_to(robot_position) <= 1.8

func _near_bed() -> bool:
	return _is_interior() and player.global_position.distance_to(bed_position) <= 1.8

func _near_exit_hatch() -> bool:
	return _is_interior() and player.global_position.distance_to(exit_hatch_position) <= 2.2

func _ship_station_nearby() -> String:
	if not _is_interior():
		return ""
	var stations := [
		["robot", robot_position, 1.8],
		["bed", bed_position, 1.8],
		["console", console_position, 2.4],
		["hatch", exit_hatch_position, 2.2],
	]
	var best := ""
	var best_distance := INF
	for station in stations:
		var distance: float = player.global_position.distance_to(station[1])
		if distance <= float(station[2]) and distance < best_distance:
			best_distance = distance
			best = station[0]
	return best

func _talk_to_robot() -> void:
	if ending_started:
		return
	if not robot_talked:
		robot_talked = true
		GameManager.add_achievement("Contato com ARIA")
		_gain_xp(10)
	_refresh_robot_dialog()
	robot_panel.visible = true
	robot_panel.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(robot_panel, "modulate:a", 1.0, 0.25)
	paused = true
	player.external_move = Vector2.ZERO
	player.set_physics_process(false)
	_clear_touch()
	touch_controls.visible = false
	Sfx.play("click")

func _refresh_robot_dialog() -> void:
	if not is_instance_valid(robot_body_label):
		return
	var lines: Array[String] = []
	lines.append("Olá, %s. Sou ARIA, a inteligência da nave." % GameManager.player_name)
	if GameManager.missions_complete:
		lines.append("Todas as %d missões foram concluídas. O console no fundo da nave está liberado para voltar para casa." % GameManager.mission_list.size())
	else:
		var mission := GameManager.get_current_mission()
		var total := GameManager.mission_list.size()
		var index := clampi(GameManager.current_mission_index + 1, 1, total)
		lines.append("Missão %d/%d\n%s" % [index, total, GameManager.get_mission_text(mission)])
		var need := int(mission.get("count", 1))
		if need > 1:
			lines.append("Progresso: %d/%d" % [GameManager.current_mission_progress, need])
		lines.append("Dica: aproxime-se do alvo e use AÇÃO para coletar, analisar ou atacar criaturas.")
	lines.append("Dia %d • %s • %s" % [day_count, "Noite" if _is_night() else "Dia", _weather_label()])
	robot_body_label.text = "\n\n".join(lines)

func _close_robot_dialog() -> void:
	robot_panel.visible = false
	paused = false
	player.set_physics_process(true)
	touch_controls.visible = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")

func _sleep_in_bed() -> void:
	if ending_started or game_over:
		return
	if not _is_night():
		_show_popup("🛏 O beliche serve para dormir à noite. Volte quando anoitecer.")
		return
	var slept_after_midnight := time_of_day >= 0.79
	time_of_day = 0.27
	if slept_after_midnight:
		day_count += 1
	health = minf(100.0, health + 30.0)
	hunger = maxf(0.0, hunger - 4.0)
	thirst = maxf(0.0, thirst - 4.0)
	_update_bars()
	_update_day_night()
	_update_time_label()
	_flash_sleep()
	Sfx.play("level")
	_show_popup("💤 Você dormiu até o amanhecer • +30 vida • Dia %d" % day_count)

func _attack_animal(animal: Node3D) -> void:
	if not is_instance_valid(animal) or not animal.available:
		return
	var alive_before: bool = animal.health > 0.0
	animal.hit(14.0, player)
	Sfx.play("click")
	if not animal.available:
		_gain_xp(8)
		_show_popup("🏆 Criatura derrotada! Você ganhou carne.")
	elif alive_before:
		_gain_xp(6)
		var reaction := "ela revidou!" if animal.combat_state == "chase" else "ela fugiu!"
		_show_popup("⚔ Criatura %d/%d ❤ • %s" % [int(ceil(animal.health)), int(animal.max_health), reaction])

func hurt_player(amount: float, source: String = "Criatura") -> void:
	if game_over or paused or ending_started or damage_cooldown > 0.0:
		return
	damage_cooldown = 0.85
	health = maxf(0.0, health - amount)
	_update_bars()
	_flash_damage()
	_show_popup("💥 %s atacou você • -%d vida" % [source, int(round(amount))])
	if health <= 0.0:
		_trigger_game_over()

func _setup_extra_ui() -> void:
	var canvas: CanvasLayer = $CanvasLayer
	sleep_overlay = ColorRect.new()
	sleep_overlay.name = "SleepOverlay"
	sleep_overlay.color = Color(0.004, 0.008, 0.025, 1)
	sleep_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sleep_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sleep_overlay.visible = false
	canvas.add_child(sleep_overlay)

	damage_overlay = ColorRect.new()
	damage_overlay.name = "DamageOverlay"
	damage_overlay.color = Color(0.72, 0.05, 0.04, 1)
	damage_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	damage_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	damage_overlay.visible = false
	canvas.add_child(damage_overlay)

	robot_panel = Panel.new()
	robot_panel.name = "RobotPanel"
	robot_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	robot_panel.visible = false
	robot_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	robot_panel.offset_left = -320.0
	robot_panel.offset_top = -210.0
	robot_panel.offset_right = 320.0
	robot_panel.offset_bottom = 210.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.06, 0.09, 0.98)
	style.border_color = Color(0.36, 0.88, 0.82, 0.92)
	style.set_border_width_all(2)
	style.set_corner_radius_all(20)
	robot_panel.add_theme_stylebox_override("panel", style)
	canvas.add_child(robot_panel)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_bottom", 24)
	robot_panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)
	var title := Label.new()
	title.text = "🤖 ARIA • CENTRAL DE MISSÕES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 23)
	title.add_theme_color_override("font_color", Color(0.55, 0.95, 0.88))
	box.add_child(title)
	robot_body_label = Label.new()
	robot_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	robot_body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	robot_body_label.add_theme_font_size_override("font_size", 17)
	robot_body_label.add_theme_color_override("font_color", Color(0.86, 0.94, 1.0))
	box.add_child(robot_body_label)
	var close_button := Button.new()
	close_button.text = "Fechar"
	close_button.custom_minimum_size = Vector2(0, 42)
	close_button.pressed.connect(_close_robot_dialog)
	box.add_child(close_button)

func _flash_sleep() -> void:
	if not is_instance_valid(sleep_overlay):
		return
	sleep_overlay.visible = true
	sleep_overlay.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(sleep_overlay, "modulate:a", 1.0, 0.35)
	tween.tween_interval(0.15)
	tween.tween_property(sleep_overlay, "modulate:a", 0.0, 0.85)
	tween.tween_callback(func() -> void: sleep_overlay.visible = false)

func _flash_damage() -> void:
	if not is_instance_valid(damage_overlay):
		return
	damage_overlay.visible = true
	damage_overlay.modulate.a = 0.45
	var tween := create_tween()
	tween.tween_property(damage_overlay, "modulate:a", 0.0, 0.55)
	tween.tween_callback(func() -> void: damage_overlay.visible = false)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_on_interact_pressed()

func _nearest_item() -> Node3D:
	var nearest: Node3D = null
	var distance := 3.0
	for it in items_node.get_children():
		if not it.available:
			continue
		var d: float = player.global_position.distance_to(it.global_position)
		if d < distance:
			distance = d
			nearest = it
	return nearest

func _near_lake() -> bool:
	var offset := player.global_position - lake_position
	return Vector2(offset.x, offset.z).length() <= 6.5

func _near_ship_door() -> bool:
	if _is_interior():
		return false
	return player.global_position.distance_to(ship_door_position) <= 4.2

func _near_ship_entrance() -> bool:
	if _is_interior():
		return false
	var local := player.global_position - ship_position
	return absf(local.x) < 1.2 and local.z > 3.1 and local.z < 4.95 and local.y > 0.82

func _near_ship_console() -> bool:
	return _is_interior() and player.global_position.distance_to(console_position) <= 2.4

func _refresh_ending_texts() -> void:
	ending_title.text = GameManager.t("ending_title")
	ending_subtitle.text = GameManager.t("ending_subtitle")
	ending_continue_button.text = GameManager.t("ending_continue")
	ending_menu_button.text = GameManager.t("ending_menu")

func _start_ending() -> void:
	if ending_started or not GameManager.missions_complete:
		return
	if not _is_interior() or not _near_ship_console():
		return
	ending_started = true
	paused = true
	player.external_move = Vector2.ZERO
	player.set_physics_process(false)
	_clear_touch()
	touch_controls.visible = false
	GameManager.add_achievement("Voltou para casa")
	_save_progress()
	Sfx.play("chapter")
	_refresh_ending_texts()
	var resource_total := 0
	for amount in inventory.values():
		resource_total += int(amount)
	ending_stats.text = "%s: %s\n%s %d  •  %s %d\n%s: %d  •  %s: %d/%d" % [
		GameManager.t("username"), GameManager.player_name,
		GameManager.t("ending_level"), GameManager.level,
		GameManager.t("ending_score"), score,
		GameManager.t("ending_resources"), resource_total,
		GameManager.t("ending_missions"), GameManager.mission_list.size(), GameManager.mission_list.size(),
	]
	ending_overlay.visible = true
	ending_overlay.modulate.a = 0.0
	ending_panel.visible = true
	ending_panel.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(ending_overlay, "modulate:a", 1.0, 0.7)
	tween.parallel().tween_property(ending_panel, "modulate:a", 1.0, 0.9).set_delay(0.4)

func _close_ending() -> void:
	ending_overlay.visible = false
	ending_panel.visible = false
	ending_started = false
	paused = false
	player.set_physics_process(true)
	touch_controls.visible = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")

func _ending_to_menu() -> void:
	GameManager.in_interior = false
	GameManager.interior_snapshot.clear()
	GameManager.pending_snapshot.clear()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _player_inside_ship() -> bool:
	# A nave é um cenário separado: só existe "dentro" no modo interior.
	return _is_interior()

func _update_ship_interior(_delta: float) -> void:
	# O casco exterior permanece fechado; o interior é carregado à parte.
	ship_inside = false

func _check_ship_entry() -> void:
	if transitioning or enter_guard > 0.0 or paused or game_over or _is_interior():
		return
	if _near_ship_entrance():
		_enter_ship()

func _enter_ship(reload: bool = true) -> void:
	if transitioning or _is_interior():
		return
	var snap := _snapshot()
	snap["in_interior"] = true
	snap["interior_return"] = [player.global_position.x, player.global_position.y, player.global_position.z]
	snap["exterior_cooldowns"] = snap.get("resource_cooldowns", [])
	snap["position"] = [INTERIOR_SPAWN.x, INTERIOR_SPAWN.y, INTERIOR_SPAWN.z]
	GameManager.interior_snapshot = snap.duplicate(true)
	GameManager.in_interior = true
	GameManager.pending_snapshot = snap
	if reload:
		transitioning = true
		_reload_gameplay()

func _exit_ship(reload: bool = true) -> void:
	if not _is_interior() or transitioning:
		return
	var snap := _snapshot()
	snap["in_interior"] = false
	var outside := ship_position + Vector3(0, 1.05, 6.0)
	snap["position"] = [outside.x, outside.y, outside.z]
	snap["interior_return"] = [outside.x, outside.y, outside.z]
	snap["resource_cooldowns"] = exterior_cooldowns if not exterior_cooldowns.is_empty() else snap.get("exterior_cooldowns", [])
	snap.erase("exterior_cooldowns")
	GameManager.in_interior = false
	GameManager.interior_snapshot.clear()
	GameManager.pending_snapshot = snap
	if reload:
		transitioning = true
		_reload_gameplay()

func _reload_gameplay() -> void:
	get_tree().paused = false
	if get_tree().current_scene != null:
		get_tree().change_scene_to_file("res://scenes/Gameplay.tscn")
	else:
		transitioning = false

func _should_use_lake(mission: Dictionary, item: Node3D) -> bool:
	return _near_lake() and (item == null or mission.get("target", "") == "lake" or (thirst < 100.0 and mission.get("action", "") != "interact"))

func _update_hint() -> void:
	var item: Node3D = _nearest_item()
	var mission: Dictionary = GameManager.get_current_mission()
	var snake: Node3D = _nearest_snake()
	var hint := "Explore os biomas • Encontre recursos e o lago turquesa"
	if _is_interior():
		match _ship_station_nearby():
			"robot":
				hint = "🤖 E / AÇÃO • Falar com ARIA (missões)"
			"bed":
				hint = "🛏 E / AÇÃO • Dormir até o amanhecer" if _is_night() else "🛏 O beliche serve para dormir à noite"
			"console":
				hint = GameManager.t("ending_console_hint") if GameManager.missions_complete else "🚀 Console sem energia • conclua as missões"
			"hatch":
				hint = "🚪 E / AÇÃO • Sair da nave para o planeta"
			_:
				hint = GameManager.t("ending_console_go") if GameManager.missions_complete else "🚀 Interior da nave • fale com ARIA para ver as missões"
	elif snake != null and mission.get("action", "") != "interact":
		hint = "🐍 E / AÇÃO • Atacar cobra (%d/%d) • cuidado, ela dá o bote" % [int(ceil(snake.health)), int(snake.max_health)]
	elif _should_use_lake(mission, item):
		hint = "E / AÇÃO • Beber água / analisar o lago"
	elif item:
		if item.tipo_item == "animal" and mission.get("action", "") != "interact":
			hint = "⚔ E / AÇÃO • Atacar %s (%d/%d)" % [item.display_name(), int(ceil(item.health)), int(item.max_health)]
		else:
			var verb: String = "Analisar" if mission.get("action", "") == "interact" else "Coletar"
			hint = "E / AÇÃO • %s %s" % [verb, item.display_name()]
	elif _near_lake():
		hint = "E / AÇÃO • Beber água / analisar o lago"
	elif _near_ship_door():
		hint = GameManager.t("ending_console_door") if GameManager.missions_complete else "🚀 Suba a rampa para entrar na nave"
	$CanvasLayer/HUD/HintLabel.text = hint

func _setup_touch() -> void:
	# O joystick analógico e os botões usam toques crus, cada dedo é
	# rastreado separadamente. A GUI continua disponível para os menus.
	for control in [joystick, joystick_base, joystick_knob, jump_button, interact_button]:
		if is_instance_valid(control):
			control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_move_knob(Vector2.ZERO)

func _input(event: InputEvent) -> void:
	if paused or game_over or not touch_controls.visible:
		return
	if event is InputEventScreenTouch:
		if event.pressed and not event.canceled:
			var action := _touch_action_at(event.position)
			if not action.is_empty():
				_set_finger_action(event.index, action, event.position)
		else:
			_set_finger_action(event.index, "", event.position)
			touch_fingers.erase(event.index)
		if touch_controls.get_global_rect().has_point(event.position):
			# Deixa o botão de pausa do HUD receber toques fora dos controles.
			if _touch_action_at(event.position) != "":
				get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if event.index == joystick_index:
			# O dedo do joystick continua controlando a direção mesmo se
			# escorregar para fora da base (joystick analógico clássico).
			_set_finger_action(event.index, "move", event.position)
			get_viewport().set_input_as_handled()
		elif touch_fingers.has(event.index):
			_set_finger_action(event.index, _touch_action_at(event.position), event.position)
			get_viewport().set_input_as_handled()

func _touch_action_at(point: Vector2) -> String:
	if is_instance_valid(joystick) and joystick.get_global_rect().has_point(point):
		return "move"
	var controls := {"jump": jump_button, "interact": interact_button}
	for action in controls:
		if controls[action].get_global_rect().has_point(point):
			return action
	return ""

func _set_finger_action(index: int, action: String, point: Vector2 = Vector2.ZERO) -> void:
	var previous: String = touch_fingers.get(index, "")
	if action == "move":
		if joystick_index == -1:
			joystick_index = index
		elif joystick_index != index:
			# Um segundo dedo no joystick é ignorado até o primeiro soltar.
			return
		touch_fingers[index] = "move"
		_update_joystick(point)
	else:
		if joystick_index == index:
			joystick_index = -1
			joystick_vector = Vector2.ZERO
			touch_dir = Vector2.ZERO
			_move_knob(Vector2.ZERO)
		if action.is_empty():
			touch_fingers.erase(index)
		else:
			touch_fingers[index] = action
	_refresh_touch_dir()
	var held := touch_fingers.values()
	jump_button.set_pressed_no_signal(held.has("jump"))
	interact_button.set_pressed_no_signal(held.has("interact"))
	if action != previous:
		if action == "jump":
			_on_jump_pressed()
		elif action == "interact":
			_on_interact_pressed()

func _update_joystick(point: Vector2) -> void:
	if not is_instance_valid(joystick_base):
		return
	var center := joystick_base.get_global_rect().get_center()
	var radius := _joystick_radius()
	var offset := point - center
	var strength := clampf(offset.length() / radius, 0.0, 1.0)
	if strength <= JOYSTICK_DEADZONE:
		joystick_vector = Vector2.ZERO
	else:
		var scaled := (strength - JOYSTICK_DEADZONE) / (1.0 - JOYSTICK_DEADZONE)
		joystick_vector = offset.normalized() * clampf(scaled, 0.0, 1.0)
	_move_knob(joystick_vector * radius)
	_refresh_touch_dir()

func _joystick_radius() -> float:
	var base_size: Vector2 = joystick_base.size
	var knob_size: Vector2 = joystick_knob.size
	if base_size.x <= 0.0 or knob_size.x <= 0.0:
		return 65.0
	return maxf(8.0, minf(base_size.x, base_size.y) * 0.5 - knob_size.x * 0.5)

func _move_knob(offset: Vector2) -> void:
	if not is_instance_valid(joystick_base) or not is_instance_valid(joystick_knob):
		return
	var center := (joystick_base.size - joystick_knob.size) * 0.5
	joystick_knob.position = center + offset

func _clear_touch() -> void:
	touch_fingers.clear()
	joystick_index = -1
	joystick_vector = Vector2.ZERO
	touch_dir = Vector2.ZERO
	_move_knob(Vector2.ZERO)
	if is_instance_valid(jump_button):
		jump_button.set_pressed_no_signal(false)
	if is_instance_valid(interact_button):
		interact_button.set_pressed_no_signal(false)
	if is_instance_valid(player):
		player.external_move = Vector2.ZERO

func _refresh_touch_dir() -> void:
	touch_dir = joystick_vector

func _on_jump_pressed() -> void:
	if player and player.is_on_floor():
		player.velocity.y = player.JUMP_VELOCITY

func _on_interact_pressed() -> void:
	if paused or game_over or ending_started:
		return
	if _player_inside_ship():
		match _ship_station_nearby():
			"robot":
				_talk_to_robot()
				return
			"bed":
				_sleep_in_bed()
				return
			"console":
				if GameManager.missions_complete:
					_start_ending()
				else:
					_show_popup("🚀 Console sem energia • conclua as missões com ARIA")
				return
			"hatch":
				_exit_ship()
				return
		if GameManager.missions_complete:
			_show_popup(GameManager.t("ending_console_go"))
			return
	var m: Dictionary = GameManager.get_current_mission()
	if m.get("action", "") == "report":
		var done: bool = GameManager.register_action("report", "any")
		_gain_xp(25 if done else 5)
		_update_mission()
		_show_popup("Relatório entregue!" if done else "Relatório em andamento")
		return
	var snake: Node3D = _nearest_snake()
	if snake != null and m.get("action", "") != "interact":
		_attack_snake(snake)
		return
	var item: Node3D = _nearest_item()
	if item and item.tipo_item == "animal" and item.available and m.get("action", "") != "interact" and not _should_use_lake(m, item):
		_attack_animal(item)
		return
	var target := ""
	if item and not _should_use_lake(m, item):
		target = item.tipo_item
	elif _near_lake():
		target = "lake"
		thirst = minf(100.0, thirst + 40.0)
		Sfx.play("drink")
		_update_bars()
		_show_popup("Água potável • +40 hidratação")
	else:
		_show_popup("Aproxime-se de um recurso ou do lago")
		return
	if m.get("action", "") == "interact":
		var completed: bool = GameManager.register_action("interact", target)
		_gain_xp(25 if completed else 5)
		_show_popup("Missão concluída!" if completed else "Análise registrada • " + target)
	elif item and target != "lake":
		item.collect(player)
	_update_mission()

# --- Pause / Game Over ---
func _toggle_pause() -> void:
	if robot_panel != null and robot_panel.visible:
		return
	_clear_touch()
	paused = not paused
	pause_panel.visible = paused
	get_tree().paused = paused
	_update_weather_fx(0.0)
	if paused:
		$CanvasLayer/PausePanel/PauseVBox/SaveStatus.text = "Salvamento automático a cada 10s"

func _quit_to_menu() -> void:
	if not game_over and _save_progress() != OK:
		$CanvasLayer/PausePanel/PauseVBox/SaveStatus.text = "Falha ao salvar. Tente novamente."
		return
	GameManager.in_interior = false
	GameManager.interior_snapshot.clear()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _trigger_game_over() -> void:
	if game_over:
		return
	_clear_touch()
	game_over = true
	gameover_panel.visible = true
	get_tree().paused = true

func _restart() -> void:
	GameManager.pending_snapshot.clear()
	GameManager.in_interior = false
	GameManager.interior_snapshot.clear()
	GameManager.build_mission_list()
	get_tree().paused = false
	get_tree().reload_current_scene()

# --- Achievements ---
func _check_achievements() -> void:
	if score >= 50 and not GameManager.achievements.has("50 pontos"):
		GameManager.add_achievement("50 pontos")
	if inventory.get("mineral", 0) >= 5 and not GameManager.achievements.has("5 minerais"):
		GameManager.add_achievement("5 minerais")
	if inventory.get("fruit", 0) >= 3 and not GameManager.achievements.has("3 frutas"):
		GameManager.add_achievement("3 frutas")

# --- Auto-save ---
func _snapshot() -> Dictionary:
	var cooldowns: Array = []
	if _is_interior():
		cooldowns = exterior_cooldowns.duplicate()
	else:
		for item in items_node.get_children():
			cooldowns.append(item.respawn_timer.time_left)
	var snap := {
		"version": GameManager.SAVE_VERSION,
		"position": [player.global_position.x, player.global_position.y, player.global_position.z],
		"health": health,
		"hunger": hunger, "thirst": thirst, "score": score,
		"inventory": inventory.duplicate(true), "time_of_day": time_of_day,
		"day": day_count, "weather": weather, "weather_timer": weather_timer,
		"world_seed": world_seed, "resource_cooldowns": cooldowns,
		"in_interior": _is_interior(),
		"interior_return": [exterior_return.x, exterior_return.y, exterior_return.z],
		"exterior_cooldowns": cooldowns.duplicate() if _is_interior() else cooldowns.duplicate(),
		"singleplayer": GameManager.singleplayer, "role": GameManager.role,
		"player": {
			"name": GameManager.player_name,
			"language": GameManager.language,
			"sfx_volume": GameManager.sfx_volume,
			"music_volume": GameManager.music_volume,
			"appearance": GameManager.appearance,
			"singleplayer": GameManager.singleplayer,
			"role": GameManager.role,
			"achievements": GameManager.achievements.duplicate(),
			"experience": GameManager.experience,
			"level": GameManager.level,
			"xp_to_next_level": GameManager.xp_to_next_level,
			"max_level": GameManager.max_level,
		},
		"mission_index": GameManager.current_mission_index,
		"mission_progress": GameManager.current_mission_progress,
	}
	if _is_interior():
		snap["exterior_day"] = exterior_day
	return snap

func _restore_snapshot(snapshot: Dictionary) -> void:
	if snapshot.is_empty():
		return
	var saved_position: Variant = snapshot.get("position", null)
	if saved_position is Array and saved_position.size() == 3:
		player.global_position = Vector3(saved_position[0], saved_position[1], saved_position[2])
	elif saved_position is Vector3:
		player.global_position = saved_position
	player.velocity = Vector3.ZERO
	var cam_offset := Vector3(0, 6.4, 8.4) if _is_interior() else Vector3(0, 12, 14)
	camera.global_position = player.global_position + cam_offset
	camera.look_at(player.global_position, Vector3.UP)
	health = clampf(snapshot.get("health", 100.0), 1.0, 100.0)
	hunger = clampf(snapshot.get("hunger", 100.0), 0.0, 100.0)
	thirst = clampf(snapshot.get("thirst", 100.0), 0.0, 100.0)
	score = maxi(0, int(snapshot.get("score", 0)))
	player.score = score
	score_label.text = "Pontos: %d" % score
	var saved_inventory: Dictionary = snapshot.get("inventory", {})
	for type in ["mineral", "fruit", "plant", "crystal", "stone", "animal"]:
		inventory[type] = maxi(0, int(saved_inventory.get(type, 0)))
	time_of_day = clampf(snapshot.get("time_of_day", 0.3), 0.0, 1.0)
	day_count = maxi(1, int(snapshot.get("day", 1)))
	weather = snapshot.get("weather", "clear")
	weather_timer = maxf(0.0, snapshot.get("weather_timer", 0.0))
	var cooldowns: Array = snapshot.get("resource_cooldowns", [])
	for i in range(mini(cooldowns.size(), items_node.get_child_count())):
		items_node.get_child(i).restore_cooldown(cooldowns[i])
	if not GameManager.mission_list.is_empty():
		var saved_index: int = int(snapshot.get("mission_index", 0))
		GameManager.current_mission_progress = int(snapshot.get("mission_progress", 0))
		if saved_index >= GameManager.mission_list.size():
			GameManager.current_mission_index = GameManager.mission_list.size()
			GameManager.missions_complete = true
		else:
			GameManager.current_mission_index = clampi(saved_index, 0, GameManager.mission_list.size() - 1)
			GameManager.missions_complete = false
	_update_mission()
	_update_level_ui()

func _save_progress() -> Error:
	if game_over or health <= 0:
		return OK # Preserve the last living checkpoint.
	if GameManager.active_slot < 0:
		# Criar o slot no meio da partida não pode derrubar o modo interior.
		var was_interior: bool = GameManager.in_interior
		var index: int = GameManager.first_empty_slot()
		if index < 0:
			index = maxi(0, GameManager.saved_games.size() - 1)
		var error: Error = GameManager.begin_new_game(index, true)
		GameManager.in_interior = was_interior
		if error != OK:
			return error
	var error := GameManager.store_snapshot(_snapshot())
	if error != OK:
		return error
	return GameManager.save_game()

func _autosave() -> void:
	var error := _save_progress()
	if error != OK and not save_error_shown:
		_show_popup("Não foi possível salvar a partida")
	save_error_shown = error != OK

func _manual_save() -> void:
	var error := _save_progress()
	$CanvasLayer/PausePanel/PauseVBox/SaveStatus.text = "Partida salva" if error == OK else "Falha ao salvar. Tente novamente."

func _notification(what: int) -> void:
	if not is_node_ready():
		return
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_clear_touch()
		_autosave()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		if _save_progress() == OK:
			get_tree().quit()
		else:
			_show_popup("Falha ao salvar. Salve no menu de pausa antes de sair.")

func _n(base: int) -> int:
	# Densidade de cenário: no Android mantém a composição, mas com menos nós.
	return maxi(2, int(round(float(base) * (0.58 if low_end else 1.0))))

func _apply_low_end_settings() -> void:
	# Ajustes de desempenho aplicados apenas em dispositivos móveis.
	Engine.max_fps = 60
	var viewport := get_viewport()
	if viewport:
		viewport.scaling_3d_scale = 0.78
	var env: Environment = $WorldEnvironment.environment
	env.glow_enabled = false
	env.ssao_enabled = false
	env.ssil_enabled = false
	env.sdfgi_enabled = false
	env.volumetric_fog_enabled = false
	env.adjustment_enabled = false
	sun.shadow_enabled = false
	if is_instance_valid(moon_light):
		moon_light.shadow_enabled = false

func _setup_visuals() -> void:
	# Duplicate the resource so the menu/cutscene keep their own environment.
	$WorldEnvironment.environment = $WorldEnvironment.environment.duplicate(true)
	var ground_material := StandardMaterial3D.new()
	ground_material.albedo_color = Color("637b77")
	ground_material.roughness = 0.95
	$Ground/Mesh.material_override = ground_material
	touch_controls.visible = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")
	var bar_colors := [Color("f0787e"), Color("efb85c"), Color("55c9dc")]
	var bars := [health_bar, hunger_bar, thirst_bar]
	for i in range(bars.size()):
		var fill := StyleBoxFlat.new()
		fill.bg_color = bar_colors[i]
		fill.set_corner_radius_all(5)
		bars[i].add_theme_stylebox_override("fill", fill)
		var background := StyleBoxFlat.new()
		background.bg_color = Color("172c3b")
		background.set_corner_radius_all(5)
		bars[i].add_theme_stylebox_override("background", background)
	if is_instance_valid(xp_bar):
		var xp_fill := StyleBoxFlat.new()
		xp_fill.bg_color = Color("f2c463")
		xp_fill.set_corner_radius_all(4)
		xp_bar.add_theme_stylebox_override("fill", xp_fill)
		var xp_bg := StyleBoxFlat.new()
		xp_bg.bg_color = Color("172c3b")
		xp_bg.set_corner_radius_all(4)
		xp_bar.add_theme_stylebox_override("background", xp_bg)
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.035, 0.08, 0.13, 0.9)
	panel.set_corner_radius_all(12)
	panel.content_margin_left = 16
	panel.content_margin_right = 16
	panel.content_margin_top = 10
	panel.content_margin_bottom = 10
	mission_label.add_theme_stylebox_override("normal", panel)
	mission_label.add_theme_color_override("font_color", Color("f2dc99"))
	inventory_label.add_theme_stylebox_override("normal", panel)
	$CanvasLayer/HUD/HintLabel.add_theme_stylebox_override("normal", panel)
	if low_end:
		_apply_low_end_settings()
	_update_day_night()


func _scenery(shape: Mesh, color: Color, pos: Vector3, size: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.mesh = shape
	mesh.position = pos
	mesh.scale = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	mesh.material_override = material
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if low_end else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(mesh)
	return mesh

func _create_landmarks() -> void:
	# Pontos de referência dentro de cada bioma (sem invadir as outras regiões).
	for i in range(3):
		var spire := CylinderMesh.new()
		spire.top_radius = 0.5
		spire.bottom_radius = 1.4
		spire.height = 5.0 + i
		spire.radial_segments = 6
		_scenery(spire, Color("b96c50"), Vector3(-30 + i * 2.2, spire.height / 2.0, -15))
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.35
	trunk.bottom_radius = 0.65
	trunk.height = 5.0
	_scenery(trunk, Color("6d5761"), Vector3(6, 2.5, -10))
	for i in range(3):
		var canopy := SphereMesh.new()
		canopy.radius = 2.7 - i * 0.45
		canopy.height = 2.0
		_scenery(canopy, Color("75c4ab").lightened(i * 0.08), Vector3(6, 4.5 + i, -10))
	for i in range(4):
		var ice := CylinderMesh.new()
		ice.top_radius = 0
		ice.bottom_radius = 0.7
		ice.height = 2.0 + i * 0.65
		ice.radial_segments = 5
		_scenery(ice, Color("8abed5"), Vector3(30 + i * 1.2, ice.height / 2.0, 12))
	for i in range(_n(36)):
		var flower := SphereMesh.new()
		flower.radius = 0.14
		flower.height = 0.25
		_scenery(flower, Color("ff9988") if i % 2 == 0 else Color("f5ce78"), Vector3(scenery_rng.randf_range(-9, 9), 0.16, scenery_rng.randf_range(-16, 16)))
	var label := Label3D.new()
	label.text = "LAGO • ÁGUA POTÁVEL"
	label.position = lake_position + Vector3(0, 1.5, 0)
	label.font_size = 40
	label.modulate = Color("b4fff1")
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)


func _exit_tree() -> void:
	get_tree().auto_accept_quit = true
