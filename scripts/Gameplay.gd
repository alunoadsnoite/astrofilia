extends Node3D

@onready var player: CharacterBody3D = $Player
@onready var camera: Camera3D = $Camera3D
@onready var items_node: Node3D = $Items
@onready var mission_label: Label = $CanvasLayer/HUD/MissionLabel
@onready var score_label: Label = $CanvasLayer/HUD/ScoreLabel
@onready var health_bar: ProgressBar = $CanvasLayer/HUD/Bars/HealthBar
@onready var hunger_bar: ProgressBar = $CanvasLayer/HUD/Bars/HungerBar
@onready var thirst_bar: ProgressBar = $CanvasLayer/HUD/Bars/ThirstBar
@onready var inventory_label: Label = $CanvasLayer/HUD/InventoryLabel
@onready var popup_container: VBoxContainer = $CanvasLayer/HUD/PopupContainer
@onready var pause_panel: Panel = $CanvasLayer/PausePanel
@onready var gameover_panel: Panel = $CanvasLayer/GameOverPanel
@onready var sun: DirectionalLight3D = $Sun
@onready var touch_controls: Control = $CanvasLayer/TouchControls
@onready var left_button: Button = $CanvasLayer/TouchControls/DPad/LeftButton
@onready var right_button: Button = $CanvasLayer/TouchControls/DPad/RightButton
@onready var up_button: Button = $CanvasLayer/TouchControls/DPad/UpButton
@onready var down_button: Button = $CanvasLayer/TouchControls/DPad/DownButton
@onready var jump_button: Button = $CanvasLayer/TouchControls/JumpButton
@onready var interact_button: Button = $CanvasLayer/TouchControls/InteractButton
@onready var pause_button: Button = $CanvasLayer/HUD/PauseButton

var item_scene := preload("res://scenes/Item.tscn")

# Stats
var health: float = 100.0
var hunger: float = 100.0
var thirst: float = 100.0
var score: int = 0
var inventory: Dictionary = {"mineral": 0, "fruit": 0, "plant": 0, "crystal": 0, "stone": 0}

# Time of day
var time_of_day: float = 0.3  # 0..1
var day_speed: float = 0.002

# Weather
var weather: String = "clear"  # clear, rain, sandstorm, snow
var weather_timer: float = 0.0

# Touch
var touch_dir: Vector2 = Vector2.ZERO

var paused: bool = false
var game_over: bool = false
var world_seed: int = 0
var scenery_rng := RandomNumberGenerator.new()
var save_error_shown := false

func _ready() -> void:
	add_to_group("hud")
	if GameManager.mission_list.is_empty():
		GameManager.build_mission_list()
	world_seed = GameManager.pending_snapshot.get("world_seed", randi())
	scenery_rng.seed = world_seed
	_setup_visuals()
	_spawn_items()
	_update_mission()
	_create_biomes()
	_add_lighting()
	_add_particles()
	_create_lake()
	_create_landmarks()
	_setup_touch()
	_restore_snapshot(GameManager.pending_snapshot)
	GameManager.pending_snapshot.clear()
	_update_day_night()
	_update_mission()
	_update_bars()
	_update_inventory()
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
	get_tree().auto_accept_quit = false
	if GameManager.active_slot >= 0:
		_autosave()

func _process(delta: float) -> void:
	if paused or game_over:
		return
	# Day/night
	time_of_day = fmod(time_of_day + day_speed * delta, 1.0)
	_update_day_night()
	# Stats decay
	hunger = max(0, hunger - 0.22 * delta)
	thirst = max(0, thirst - 0.35 * delta)
	if hunger <= 0 or thirst <= 0:
		health = max(0, health - 5.0 * delta)
	_update_bars()
	if health <= 0:
		_trigger_game_over()
	# Weather timer
	weather_timer -= delta
	if weather_timer <= 0:
		_change_weather()
	# Camera follow
	if player:
		var target := player.global_position + Vector3(0, 12, 14)
		camera.global_position = camera.global_position.lerp(target, 1.0 - exp(-8.0 * delta))
		camera.look_at(player.global_position, Vector3.UP)
	_update_mission()
	_update_hint()
	# Controles de toque -> jogador
	if player:
		player.external_move = touch_dir

func _update_day_night() -> void:
	var daylight := clampf(-cos(time_of_day * TAU), 0.0, 1.0)
	sun.light_energy = lerpf(0.25, 1.2, daylight)
	sun.light_color = Color("b9c9ff").lerp(Color("fff0d5"), daylight)
	var env: Environment = $WorldEnvironment.environment
	env.ambient_light_energy = lerpf(0.35, 0.7, daylight)
	env.ambient_light_color = Color("818bb5").lerp(Color("dbe9f0"), daylight)
	env.fog_light_color = Color("373653").lerp(Color("a1c5cc"), daylight)
	var sky_material := env.sky.sky_material as ProceduralSkyMaterial
	sky_material.sky_top_color = Color("171d40").lerp(Color("24749c"), daylight)
	sky_material.sky_horizon_color = Color("635075").lerp(Color("b4d8d9"), daylight)

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
	# Could change particle color; skip heavy for now

func _update_mission() -> void:
	var m := GameManager.get_current_mission()
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

func _update_inventory() -> void:
	var lines := ["Inventário:"]
	for k in inventory:
		lines.append("- %s: %d" % [k, inventory[k]])
	inventory_label.text = "\n".join(lines)

func _spawn_items() -> void:
	var types := ["mineral", "fruit", "plant", "crystal", "stone", "animal"]
	for i in range(30):
		var it := item_scene.instantiate()
		var angle := i * TAU / 30.0
		var radius := 6.0 + (i % 5) * 4.0
		it.position = Vector3(cos(angle) * radius, 1.0, sin(angle) * radius)
		var idx := i % types.size()
		it.tipo_item = types[idx]
		it.collected.connect(_on_item_collected)
		items_node.add_child(it)

func _on_item_collected(type: String) -> void:
	inventory[type] = inventory.get(type, 0) + 1
	_update_inventory()
	if type == "fruit":
		hunger = min(100, hunger + 15)
		health = min(100, health + 5)
	_show_popup("+1 %s" % type)
	var completed := GameManager.register_action("collect", type)
	_update_mission()
	if completed:
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

func _create_biomes() -> void:
	var biomes := [
		{"pos": Vector3(-18, -0.5, -18), "color": Color("ce9758"), "name": "Deserto", "accent": Color(0.9, 0.7, 0.3), "prop": "rock"},
		{"pos": Vector3(18, -0.5, 0), "color": Color("286f64"), "name": "Floresta", "accent": Color(0.2, 0.8, 0.3), "prop": "tree"},
		{"pos": Vector3(0, -0.5, 18), "color": Color("dcecf0"), "name": "Nevado", "accent": Color(0.5, 0.7, 1.0), "prop": "snow"},
	]
	for b in biomes:
		for gx in range(-1, 2):
			for gz in range(-1, 2):
				var mb := MeshInstance3D.new()
				var bm := BoxMesh.new()
				var h := 1.0
				bm.size = Vector3(9, h, 9)
				mb.mesh = bm
				var mat := StandardMaterial3D.new()
				mat.albedo_color = b["color"].darkened(scenery_rng.randf_range(0.0, 0.15))
				mat.roughness = 0.8
				mb.material_override = mat
				mb.position = b["pos"] + Vector3(gx * 9, (h - 1.0) * 0.5, gz * 9)
				add_child(mb)
		var sb := StaticBody3D.new()
		sb.position = b["pos"]
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(26, 1, 26)
		cs.shape = bs
		sb.add_child(cs)
		add_child(sb)
		for j in range(10):
			var prop := MeshInstance3D.new()
			var off := Vector3(scenery_rng.randf_range(-11, 11), 0.5, scenery_rng.randf_range(-11, 11))
			if b["prop"] == "rock":
				var rm := SphereMesh.new()
				rm.radius = scenery_rng.randf_range(0.4, 1.2)
				rm.height = rm.radius * 1.4
				prop.mesh = rm
				prop.position = b["pos"] + off + Vector3(0, rm.radius * 0.7, 0)
				var pmat := StandardMaterial3D.new()
				pmat.albedo_color = Color("ac654d")
				pmat.roughness = 0.9
				prop.material_override = pmat
			elif b["prop"] == "tree":
				var trunk := MeshInstance3D.new()
				var tm := CylinderMesh.new()
				tm.top_radius = 0.2
				tm.bottom_radius = 0.3
				tm.height = 2.5
				trunk.mesh = tm
				trunk.position = b["pos"] + off + Vector3(0, 1.25, 0)
				var tmat := StandardMaterial3D.new()
				tmat.albedo_color = Color(0.4, 0.25, 0.1)
				trunk.material_override = tmat
				add_child(trunk)
				var crown := MeshInstance3D.new()
				var cm := SphereMesh.new()
				cm.radius = 1.3
				cm.height = 2.6
				crown.mesh = cm
				crown.position = b["pos"] + off + Vector3(0, 3.2, 0)
				var cmat := StandardMaterial3D.new()
				cmat.albedo_color = Color("54b995")
				cmat.emission_enabled = true
				cmat.emission = Color(0.05, 0.3, 0.1)
				cmat.emission_energy_multiplier = 0.3
				crown.material_override = cmat
				add_child(crown)
				prop.free()
				continue
			else:
				var sm := SphereMesh.new()
				sm.radius = scenery_rng.randf_range(0.5, 1.0)
				sm.height = sm.radius * 1.2
				prop.mesh = sm
				prop.position = b["pos"] + off + Vector3(0, sm.radius * 0.6, 0)
				var pmat := StandardMaterial3D.new()
				pmat.albedo_color = Color(0.95, 0.97, 1.0)
				pmat.roughness = 0.3
				prop.material_override = pmat
			add_child(prop)

func _add_lighting() -> void:
	var omni := OmniLight3D.new()
	omni.light_color = Color("d4eced")
	omni.light_energy = 0.35
	omni.omni_range = 30.0
	omni.position = Vector3(0, 8, 0)
	add_child(omni)

func _add_particles() -> void:
	var particles := CPUParticles3D.new()
	particles.amount = 200
	particles.lifetime = 6.0
	particles.preprocess = 3.0
	particles.emission_shape = 2
	particles.emission_box_extents = Vector3(40, 10, 40)
	particles.gravity = Vector3(0, -0.5, 0)
	particles.initial_velocity_min = 0.5
	particles.initial_velocity_max = 1.5
	particles.scale_amount_min = 0.05
	particles.scale_amount_max = 0.15
	particles.color = Color(0.8, 0.9, 1.0, 0.6)
	add_child(particles)

# --- Touch controls ---
var lake_position: Vector3 = Vector3(-18, 0.3, 8)

func _create_lake() -> void:
	var lake := MeshInstance3D.new()
	var lm := CylinderMesh.new()
	lm.top_radius = 5.0
	lm.bottom_radius = 5.0
	lm.height = 0.3
	lake.mesh = lm
	lake.position = lake_position
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("28b9bf")
	mat.emission_enabled = true
	mat.emission = Color(0.05, 0.25, 0.6)
	mat.emission_energy_multiplier = 0.5
	mat.metallic = 0.3
	mat.roughness = 0.2
	lake.material_override = mat
	add_child(lake)

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

func _should_use_lake(mission: Dictionary, item: Node3D) -> bool:
	return _near_lake() and (item == null or mission.get("target", "") == "lake" or (thirst < 100.0 and mission.get("action", "") != "interact"))

func _update_hint() -> void:
	var item := _nearest_item()
	var mission := GameManager.get_current_mission()
	var hint := "Explore os biomas • Encontre recursos e o lago turquesa"
	if _should_use_lake(mission, item):
		hint = "E / AÇÃO • Beber água / analisar o lago"
	elif item:
		var verb := "Analisar" if mission.get("action", "") == "interact" else "Coletar"
		hint = "E / AÇÃO • %s %s" % [verb, item.display_name()]
	elif _near_lake():
		hint = "E / AÇÃO • Beber água / analisar o lago"
	$CanvasLayer/HUD/HintLabel.text = hint

var touch_left := false
var touch_right := false
var touch_up := false
var touch_down := false

func _setup_touch() -> void:
	left_button.button_down.connect(func(): touch_left = true; _refresh_touch_dir())
	left_button.button_up.connect(func(): touch_left = false; _refresh_touch_dir())
	right_button.button_down.connect(func(): touch_right = true; _refresh_touch_dir())
	right_button.button_up.connect(func(): touch_right = false; _refresh_touch_dir())
	up_button.button_down.connect(func(): touch_up = true; _refresh_touch_dir())
	up_button.button_up.connect(func(): touch_up = false; _refresh_touch_dir())
	down_button.button_down.connect(func(): touch_down = true; _refresh_touch_dir())
	down_button.button_up.connect(func(): touch_down = false; _refresh_touch_dir())

func _refresh_touch_dir() -> void:
	var x := (1.0 if touch_right else 0.0) - (1.0 if touch_left else 0.0)
	var y := (1.0 if touch_down else 0.0) - (1.0 if touch_up else 0.0)
	touch_dir = Vector2(x, y)

func _on_jump_pressed() -> void:
	if player and player.is_on_floor():
		player.velocity.y = player.JUMP_VELOCITY

func _on_interact_pressed() -> void:
	if paused or game_over:
		return
	var m := GameManager.get_current_mission()
	if m.get("action", "") == "report":
		GameManager.advance_mission()
		_update_mission()
		_show_popup("Relatório entregue!")
		return
	var item := _nearest_item()
	var target := ""
	if item and not _should_use_lake(m, item):
		target = item.tipo_item
	elif _near_lake():
		target = "lake"
		thirst = minf(100.0, thirst + 40.0)
		_update_bars()
		_show_popup("Água potável • +40 hidratação")
	else:
		_show_popup("Aproxime-se de um recurso ou do lago")
		return
	if m.get("action", "") == "interact":
		var completed := GameManager.register_action("interact", target)
		_show_popup("Missão concluída!" if completed else "Análise registrada • " + target)
	elif item and target != "lake":
		item.collect(player)
	_update_mission()

# --- Pause / Game Over ---
func _toggle_pause() -> void:
	paused = not paused
	pause_panel.visible = paused
	get_tree().paused = paused
	if paused:
		$CanvasLayer/PausePanel/PauseVBox/SaveStatus.text = "Salvamento automático a cada 10s"

func _quit_to_menu() -> void:
	if not game_over and _save_progress() != OK:
		$CanvasLayer/PausePanel/PauseVBox/SaveStatus.text = "Falha ao salvar. Tente novamente."
		return
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _trigger_game_over() -> void:
	if game_over:
		return
	game_over = true
	gameover_panel.visible = true
	get_tree().paused = true

func _restart() -> void:
	GameManager.pending_snapshot.clear()
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
	var cooldowns: Array[float] = []
	for item in items_node.get_children():
		cooldowns.append(item.respawn_timer.time_left)
	return {
		"version": GameManager.SAVE_VERSION,
		"position": player.global_position, "health": health,
		"hunger": hunger, "thirst": thirst, "score": score,
		"inventory": inventory.duplicate(true), "time_of_day": time_of_day,
		"weather": weather, "weather_timer": weather_timer,
		"world_seed": world_seed, "resource_cooldowns": cooldowns,
		"singleplayer": GameManager.singleplayer, "role": GameManager.role,
		"mission_index": GameManager.current_mission_index,
		"mission_progress": GameManager.current_mission_progress,
	}

func _restore_snapshot(snapshot: Dictionary) -> void:
	if snapshot.is_empty():
		return
	player.global_position = snapshot.get("position", Vector3(0, 1, 0))
	player.velocity = Vector3.ZERO
	camera.global_position = player.global_position + Vector3(0, 12, 14)
	camera.look_at(player.global_position, Vector3.UP)
	health = clampf(snapshot.get("health", 100.0), 1.0, 100.0)
	hunger = clampf(snapshot.get("hunger", 100.0), 0.0, 100.0)
	thirst = clampf(snapshot.get("thirst", 100.0), 0.0, 100.0)
	score = maxi(0, snapshot.get("score", 0))
	player.score = score
	score_label.text = "Pontos: %d" % score
	var saved_inventory: Dictionary = snapshot.get("inventory", {})
	for type in ["mineral", "fruit", "plant", "crystal", "stone", "animal"]:
		inventory[type] = maxi(0, saved_inventory.get(type, 0))
	time_of_day = clampf(snapshot.get("time_of_day", 0.3), 0.0, 1.0)
	weather = snapshot.get("weather", "clear")
	weather_timer = maxf(0.0, snapshot.get("weather_timer", 0.0))
	var cooldowns: Array = snapshot.get("resource_cooldowns", [])
	for i in range(mini(cooldowns.size(), items_node.get_child_count())):
		items_node.get_child(i).restore_cooldown(cooldowns[i])

func _save_progress() -> Error:
	if game_over or health <= 0:
		return OK # Preserve the last living checkpoint.
	if GameManager.active_slot < 0:
		var index := GameManager.first_empty_slot()
		if index < 0:
			return ERR_ALREADY_IN_USE
		var error := GameManager.begin_new_game(index, false)
		if error != OK:
			return error
	return GameManager.store_snapshot(_snapshot())

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
		_autosave()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		if _save_progress() == OK:
			get_tree().quit()
		else:
			_show_popup("Falha ao salvar. Salve no menu de pausa antes de sair.")

func _setup_visuals() -> void:
	# Duplicate the resource so the menu/cutscene keep their own environment.
	$WorldEnvironment.environment = $WorldEnvironment.environment.duplicate(true)
	var ground_material := StandardMaterial3D.new()
	ground_material.albedo_color = Color("637b77")
	ground_material.roughness = 0.95
	$Ground/Mesh.material_override = ground_material
	touch_controls.visible = DisplayServer.is_touchscreen_available()
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
	add_child(mesh)
	return mesh

func _create_landmarks() -> void:
	# Warm desert spires, a broad forest canopy, and ice needles aid navigation.
	for i in range(3):
		var spire := CylinderMesh.new()
		spire.top_radius = 0.5
		spire.bottom_radius = 1.4
		spire.height = 5.0 + i
		spire.radial_segments = 6
		_scenery(spire, Color("b96c50"), Vector3(-22 + i * 2.0, spire.height / 2.0, -22))
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.35
	trunk.bottom_radius = 0.65
	trunk.height = 5.0
	_scenery(trunk, Color("6d5761"), Vector3(23, 2.5, -7))
	for i in range(3):
		var canopy := SphereMesh.new()
		canopy.radius = 2.7 - i * 0.45
		canopy.height = 2.0
		_scenery(canopy, Color("75c4ab").lightened(i * 0.08), Vector3(23, 4.5 + i, -7))
	for i in range(4):
		var ice := CylinderMesh.new()
		ice.top_radius = 0
		ice.bottom_radius = 0.7
		ice.height = 2.0 + i * 0.65
		ice.radial_segments = 5
		_scenery(ice, Color("8abed5"), Vector3(-6 + i * 1.1, ice.height / 2.0, 24))
	for i in range(36):
		var flower := SphereMesh.new()
		flower.radius = 0.14
		flower.height = 0.25
		_scenery(flower, Color("ff9988") if i % 2 == 0 else Color("f5ce78"), Vector3(scenery_rng.randf_range(6, 29), 0.16, scenery_rng.randf_range(-11, 11)))
	var label := Label3D.new()
	label.text = "LAGO • ÁGUA POTÁVEL"
	label.position = lake_position + Vector3(0, 1.5, 0)
	label.font_size = 40
	label.modulate = Color("b4fff1")
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)


func _exit_tree() -> void:
	get_tree().auto_accept_quit = true
