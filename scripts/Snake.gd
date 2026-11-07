extends Area3D

# Cobra noturna da floresta. Vive em um nó próprio (fora de Items) para não
# alterar a contagem de recursos nem as missões de coleta de animais.
signal defeated

@export var max_health: float = 24.0
@export var move_speed: float = 3.6
@export var home_radius: float = 5.0
@export var lake_center: Vector3 = Vector3(0, 0.15, 12)
@export var ship_center: Vector3 = Vector3(-24, 0, 5)

var health := 24.0
var active := false
# No cliente, a cobra é um fantoche: o host manda posição, vida e visibilidade.
var remote_mode := false
var visual: Node3D
var body_parts: Array[MeshInstance3D] = []
var home_position := Vector3.ZERO
var attack_timer := 0.0
var wander_angle := 0.0
var wander_timer := 0.0
var respawn_timer: Timer
var _phase := 0.0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	add_to_group("snakes")
	_rng.randomize()
	home_position = global_position
	health = max_health
	_build_visual()
	respawn_timer = Timer.new()
	respawn_timer.one_shot = true
	respawn_timer.timeout.connect(_respawn)
	add_child(respawn_timer)
	_wander_pick()
	set_process(active)
	visible = active

func _build_visual() -> void:
	visual = Node3D.new()
	visual.name = "SnakeVisual"
	visual.position.y = 0.18
	add_child(visual)
	var scale_body := 0.55 if OS.has_feature("mobile") else 1.0
	var body_color := Color("2f5c3c")
	var spot_color := Color("78b96e")
	var belly_color := Color("c8d9a0")
	for i in range(9):
		var radius := lerpf(0.20, 0.11, float(i) / 8.0)
		var part := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = radius
		mesh.height = radius * 2.0
		mesh.radial_segments = 8 if scale_body > 0.75 else 6
		mesh.rings = 4
		part.mesh = mesh
		var material := StandardMaterial3D.new()
		material.albedo_color = body_color.lightened(float(i) * 0.02)
		material.roughness = 0.55
		part.material_override = material
		part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		part.position = Vector3(sin(float(i) * 1.15) * 0.16, 0.02 * sin(float(i) * 1.6), -float(i) * 0.19)
		visual.add_child(part)
		body_parts.append(part)
		if i % 3 == 0:
			var spot := MeshInstance3D.new()
			var spot_mesh := SphereMesh.new()
			spot_mesh.radius = radius * 0.42
			spot_mesh.height = radius * 0.42
			spot_mesh.radial_segments = 6
			spot_mesh.rings = 3
			spot.mesh = spot_mesh
			var spot_mat := StandardMaterial3D.new()
			spot_mat.albedo_color = spot_color
			spot_mat.roughness = 0.5
			spot.material_override = spot_mat
			spot.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			spot.position = Vector3(0, radius * 0.72, 0)
			part.add_child(spot)
	# Cabeça, olhos e língua.
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.26
	head_mesh.height = 0.34
	head_mesh.radial_segments = 10
	head_mesh.rings = 5
	head.mesh = head_mesh
	var head_mat := StandardMaterial3D.new()
	head_mat.albedo_color = body_color.darkened(0.08)
	head_mat.roughness = 0.45
	head.material_override = head_mat
	head.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	head.position = Vector3(0, 0.03, 0.24)
	visual.add_child(head)
	body_parts.append(head)
	for x in [-0.11, 0.11]:
		var eye := MeshInstance3D.new()
		var eye_mesh := SphereMesh.new()
		eye_mesh.radius = 0.045
		eye_mesh.height = 0.09
		eye_mesh.radial_segments = 6
		eye_mesh.rings = 3
		eye.mesh = eye_mesh
		var eye_mat := StandardMaterial3D.new()
		eye_mat.albedo_color = Color("ffd34d")
		eye_mat.emission_enabled = true
		eye_mat.emission = Color("ffb52e")
		eye_mat.emission_energy_multiplier = 0.8
		eye.material_override = eye_mat
		eye.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		eye.position = Vector3(x, 0.12, 0.38)
		visual.add_child(eye)
	var tongue := MeshInstance3D.new()
	var tongue_mesh := BoxMesh.new()
	tongue_mesh.size = Vector3(0.035, 0.018, 0.28)
	tongue.mesh = tongue_mesh
	var tongue_mat := StandardMaterial3D.new()
	tongue_mat.albedo_color = Color("ff5f5f")
	tongue_mat.emission_enabled = true
	tongue_mat.emission = Color("ff3333")
	tongue_mat.emission_energy_multiplier = 0.5
	tongue.material_override = tongue_mat
	tongue.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	tongue.position = Vector3(0, 0.02, 0.55)
	visual.add_child(tongue)
	# Área de contato (não empurra o jogador; serve de referência).
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.7
	shape.shape = sphere
	shape.position.y = 0.2
	add_child(shape)

func set_active(enabled: bool) -> void:
	if enabled and health <= 0.0:
		return
	active = enabled
	visible = enabled
	set_process(enabled)

func _wander_pick() -> void:
	wander_angle = _rng.randf_range(0.0, TAU)
	wander_timer = _rng.randf_range(1.0, 2.8)

func _process(delta: float) -> void:
	if remote_mode:
		_animate(delta)
		return
	if not active:
		return
	attack_timer = maxf(0.0, attack_timer - delta)
	var target := get_tree().get_first_node_in_group("player") as Node3D
	var direction := Vector3.ZERO
	var speed := 1.15
	if is_instance_valid(target):
		var offset := target.global_position - global_position
		offset.y = 0.0
		var distance := offset.length()
		if distance < 1.55:
			# Dá o bote quando o astronauta chega perto.
			if attack_timer <= 0.0:
				attack_timer = 1.5
				_phase += 2.0
				var hud := get_tree().get_first_node_in_group("hud")
				if hud and hud.has_method("hurt_player"):
					hud.hurt_player(7.0, "🐍 Cobra")
			direction = Vector3.ZERO
		elif distance < 9.5:
			direction = offset.normalized()
			speed = move_speed
		else:
			_wander_step(delta)
	else:
		_wander_step(delta)
	if direction.length_squared() > 0.001:
		_move(direction, speed, delta)
	_animate(delta)

func _wander_step(delta: float) -> void:
	wander_timer -= delta
	if wander_timer <= 0.0:
		_wander_pick()
	var away := Vector3(cos(wander_angle), 0.0, sin(wander_angle))
	var from_home := Vector2(global_position.x - home_position.x, global_position.z - home_position.z)
	if from_home.length() > home_radius:
		away = Vector3(-from_home.x, 0.0, -from_home.y).normalized()
	_move(away, 1.0, delta)

func _move(direction: Vector3, speed: float, delta: float) -> void:
	var next := global_position + direction * speed * delta
	next = _keep_out(next)
	next.x = clampf(next.x, -42.0, 42.0)
	next.z = clampf(next.z, -42.0, 42.0)
	next.y = home_position.y
	global_position = next
	visual.rotation.y = lerp_angle(visual.rotation.y, atan2(direction.x, direction.z), clampf(delta * 10.0, 0.0, 1.0))

func _keep_out(point: Vector3) -> Vector3:
	for zone in [[lake_center, 6.7], [ship_center, 7.7]]:
		var center: Vector3 = zone[0]
		var radius: float = zone[1]
		var offset := Vector2(point.x - center.x, point.z - center.z)
		if offset.length() < radius:
			var fallback := Vector2(1, 0) if offset.length() < 0.01 else offset.normalized()
			point.x = center.x + fallback.x * radius
			point.z = center.z + fallback.y * radius
	return point

func _animate(delta: float) -> void:
	_phase += delta * (8.0 if active else 4.0)
	# Ondulação lateral do corpo, como uma cobra rastejando.
	for i in range(body_parts.size()):
		var part := body_parts[i]
		var wave := sin(_phase + float(i) * 0.55) * 0.05
		part.position.x = wave
		part.position.y = 0.02 + absf(cos(_phase + float(i) * 0.55)) * 0.025
	visual.position.y = 0.18 + sin(_phase * 0.7) * 0.02

func hit(damage: float, _attacker: Node3D = null) -> void:
	if not active:
		return
	health = maxf(0.0, health - damage)
	attack_timer = 0.4
	if health <= 0.0:
		_die()
		return
	# Fica mais agressiva ao ser atacada.
	var tween := create_tween()
	tween.tween_property(visual, "modulate", Color(1.4, 0.5, 0.5), 0.08)
	tween.tween_property(visual, "modulate", Color.WHITE, 0.18)

func _die() -> void:
	active = false
	set_process(false)
	visible = false
	defeated.emit()
	respawn_timer.start(18.0)

func _respawn() -> void:
	health = max_health
	global_position = home_position
	visual.rotation = Vector3.ZERO
	_wander_pick()
	if active:
		visible = true
		set_process(true)

func remote_apply(state: Dictionary) -> void:
	if not remote_mode:
		return
	global_position = state.get("pos", global_position)
	if is_instance_valid(visual):
		visual.rotation.y = float(state.get("rot", visual.rotation.y))
	active = bool(state.get("active", false))
	health = float(state.get("health", health))
	visible = bool(state.get("visible", active)) and health > 0.0

func reset_for_night() -> void:
	health = max_health
	global_position = home_position
	visual.rotation = Vector3.ZERO
	respawn_timer.stop()
	_wander_pick()

func display_name() -> String:
	return "cobra"
