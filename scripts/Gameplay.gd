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
@onready var joystick_base: Panel = $CanvasLayer/TouchControls/JoystickBase
@onready var joystick_stick: Panel = $CanvasLayer/TouchControls/JoystickBase/JoystickStick
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
var day_speed: float = 0.02

# Weather
var weather: String = "clear"  # clear, rain, sandstorm, snow
var weather_timer: float = 0.0

# Touch
var joystick_touch_index: int = -1
var joystick_center: Vector2 = Vector2.ZERO
var joystick_radius: float = 60.0

var paused: bool = false
var game_over: bool = false

func _ready() -> void:
	add_to_group("hud")
	_spawn_items()
	_update_mission()
	_create_biomes()
	_add_lighting()
	_add_particles()
	_setup_touch()
	_update_bars()
	_update_inventory()
	# Auto-save timer
	var timer := Timer.new()
	timer.wait_time = 10.0
	timer.autostart = true
	timer.timeout.connect(_autosave)
	add_child(timer)
	# Buttons
	pause_button.pressed.connect(_toggle_pause)
	$CanvasLayer/PausePanel/PauseVBox/ResumeButton.pressed.connect(_toggle_pause)
	$CanvasLayer/PausePanel/PauseVBox/QuitButton.pressed.connect(_quit_to_menu)
	$CanvasLayer/GameOverPanel/GameOverVBox/RestartButton.pressed.connect(_restart)
	jump_button.pressed.connect(_on_jump_pressed)
	interact_button.pressed.connect(_on_interact_pressed)

func _process(delta: float) -> void:
	if paused or game_over:
		return
	# Day/night
	time_of_day = fmod(time_of_day + day_speed * delta, 1.0)
	_update_day_night()
	# Stats decay
	hunger = max(0, hunger - 1.5 * delta)
	thirst = max(0, thirst - 2.0 * delta)
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
		camera.global_position = camera.global_position.lerp(target, 0.1)
		camera.look_at(player.global_position, Vector3.UP)
	_update_mission()
	# Touch joystick -> player
	if player:
		player.external_move = _joystick_value()

func _update_day_night() -> void:
	# sun energy varies
	var t := time_of_day
	var sun_energy: float = 0.3 + 0.9 * (1.0 - abs(t - 0.5) * 2.0)
	sun.light_energy = clamp(sun_energy, 0.2, 1.2)
	# ambient via environment
	var env := get_viewport().world_3d.environment if get_viewport() else null
	if env:
		env.ambient_light_energy = 0.3 + 0.4 * sun_energy

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
		mission_label.text = GameManager.get_mission_text(m)

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
	var positions := [
		Vector3(5, 1, 0), Vector3(-4, 1, 3), Vector3(8, 1, -5),
		Vector3(-7, 1, -2), Vector3(3, 1, 6), Vector3(-2, 1, -6),
		Vector3(10, 1, 2), Vector3(-9, 1, 4), Vector3(0, 1, -10),
		Vector3(12, 1, 8),
	]
	var types := ["mineral", "fruit", "plant", "crystal", "stone"]
	var colors := [Color(0.6, 0.6, 0.7), Color(0.9, 0.3, 0.3), Color(0.2, 0.7, 0.3), Color(0.3, 0.8, 0.9), Color(0.7, 0.5, 0.2)]
	for i in range(positions.size()):
		var it := item_scene.instantiate()
		it.position = positions[i]
		var idx := i % types.size()
		it.tipo_item = types[idx]
		var mesh := it.get_node_or_null("MeshInstance3D")
		if mesh:
			var mat := StandardMaterial3D.new()
			mat.albedo_color = colors[idx]
			mat.emission_enabled = true
			mat.emission = colors[idx] * 0.4
			mat.emission_energy_multiplier = 0.6
			mesh.material_override = mat
		it.collected.connect(_on_item_collected.bind(types[idx]))
		items_node.add_child(it)

func _on_item_collected(type: String) -> void:
	inventory[type] = inventory.get(type, 0) + 1
	_update_inventory()
	# heal if fruit
	if type == "fruit":
		hunger = min(100, hunger + 15)
		health = min(100, health + 5)
	# popup
	_show_popup("+1 %s" % type)
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
		{"pos": Vector3(-18, -0.5, -18), "color": Color(0.75, 0.55, 0.25), "name": "Deserto", "accent": Color(0.9, 0.7, 0.3), "prop": "rock"},
		{"pos": Vector3(18, -0.5, 0), "color": Color(0.12, 0.5, 0.18), "name": "Floresta", "accent": Color(0.2, 0.8, 0.3), "prop": "tree"},
		{"pos": Vector3(0, -0.5, 18), "color": Color(0.85, 0.9, 0.98), "name": "Nevado", "accent": Color(0.5, 0.7, 1.0), "prop": "snow"},
	]
	for b in biomes:
		for gx in range(-1, 2):
			for gz in range(-1, 2):
				var mb := MeshInstance3D.new()
				var bm := BoxMesh.new()
				var h := randf_range(0.6, 1.4)
				bm.size = Vector3(9, h, 9)
				mb.mesh = bm
				var mat := StandardMaterial3D.new()
				mat.albedo_color = b["color"].darkened(randf_range(0.0, 0.15))
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
			var off := Vector3(randf_range(-11, 11), 0, randf_range(-11, 11))
			if b["prop"] == "rock":
				var rm := SphereMesh.new()
				rm.radius = randf_range(0.4, 1.2)
				rm.height = rm.radius * 1.4
				prop.mesh = rm
				prop.position = b["pos"] + off + Vector3(0, rm.radius * 0.7, 0)
				var pmat := StandardMaterial3D.new()
				pmat.albedo_color = Color(0.5, 0.45, 0.4)
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
				cmat.albedo_color = Color(0.1, 0.6, 0.2)
				cmat.emission_enabled = true
				cmat.emission = Color(0.05, 0.3, 0.1)
				cmat.emission_energy_multiplier = 0.3
				crown.material_override = cmat
				add_child(crown)
				continue
			else:
				var sm := SphereMesh.new()
				sm.radius = randf_range(0.5, 1.0)
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
	omni.light_color = Color(0.6, 0.4, 1.0)
	omni.light_energy = 1.5
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
func _setup_touch() -> void:
	joystick_base.gui_input.connect(_on_joystick_input)
	jump_button.button_down.connect(func(): _on_jump_pressed())
	interact_button.button_down.connect(func(): _on_interact_pressed())

func _on_joystick_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			joystick_touch_index = event.index
			joystick_center = joystick_base.size / 2.0
		else:
			if event.index == joystick_touch_index:
				joystick_touch_index = -1
				joystick_stick.position = joystick_center - joystick_stick.size / 2.0
				if player:
					player.external_move = Vector2.ZERO
	elif event is InputEventScreenDrag:
		if event.index == joystick_touch_index:
			var local: Vector2 = event.position - joystick_center
			var dist := local.length()
			if dist > joystick_radius:
				local = local.normalized() * joystick_radius
			joystick_stick.position = joystick_center + local - joystick_stick.size / 2.0

func _joystick_value() -> Vector2:
	if joystick_touch_index == -1:
		return Vector2.ZERO
	var stick_pos: Vector2 = joystick_stick.position + joystick_stick.size / 2.0 - joystick_center
	return (stick_pos / joystick_radius).clamp(Vector2(-1, -1), Vector2(1, 1))

func _on_jump_pressed() -> void:
	if player and player.is_on_floor():
		player.velocity.y = player.JUMP_VELOCITY

func _on_interact_pressed() -> void:
	# interagir com item próximo
	pass

# --- Pause / Game Over ---
func _toggle_pause() -> void:
	paused = not paused
	pause_panel.visible = paused
	get_tree().paused = paused

func _quit_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _trigger_game_over() -> void:
	if game_over:
		return
	game_over = true
	gameover_panel.visible = true
	get_tree().paused = true

func _restart() -> void:
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
func _autosave() -> void:
	GameManager.saved_games = GameManager.saved_games
	GameManager.save_game()