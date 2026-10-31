extends Area3D

signal collected(type: String)

@export var tipo_item: String = "mineral"
@export var quantidade: int = 1
@export var mensagem_coleta: String = "Coletado!"

# Movimento das criaturas: cada animal patrulha uma pequena área ao redor do
# ponto onde nasceu, sem entrar no lago nem na nave.
@export var move_speed: float = 0.9
@export var wander_radius: float = 3.4
@export var lake_center: Vector3 = Vector3(0, 0.15, 12)
@export var ship_center: Vector3 = Vector3(-24, 0, 5)

var available := true
var visual: Node3D
var respawn_timer: Timer
var home_position := Vector3.ZERO
var wander_direction := Vector3.ZERO
var wander_timer := 0.0
var hop_phase := 0.0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	$MeshInstance3D.hide()
	$Label3D.hide()
	visual = Node3D.new()
	add_child(visual)
	_build_visual()
	respawn_timer = Timer.new()
	respawn_timer.one_shot = true
	respawn_timer.timeout.connect(_respawn)
	add_child(respawn_timer)
	_rng.randomize()
	home_position = position
	if tipo_item == "animal":
		_pick_wander_direction()
	else:
		set_process(false)

func _process(delta: float) -> void:
	if tipo_item != "animal" or not available:
		return
	wander_timer -= delta
	if wander_timer <= 0.0:
		_pick_wander_direction()
	if wander_direction.length_squared() <= 0.001:
		hop_phase = 0.0
		visual.position.y = move_toward(visual.position.y, 0.0, delta * 0.6)
		return
	var next := global_position + wander_direction * move_speed * delta
	var steer := _steer_away(next)
	if steer.length_squared() > 0.0:
		next += steer * delta * 2.2
	var clamped := _keep_out(next)
	if not clamped.is_equal_approx(next):
		wander_direction = -wander_direction
		wander_timer = minf(wander_timer, 1.2)
	next = clamped
	# Mantém a criatura perto do ponto de origem.
	var from_home := Vector2(next.x - home_position.x, next.z - home_position.z)
	if from_home.length() > wander_radius:
		from_home = from_home.normalized() * wander_radius
		next.x = home_position.x + from_home.x
		next.z = home_position.z + from_home.y
		wander_direction = Vector3(-from_home.normalized().x, 0.0, -from_home.normalized().y)
		wander_timer = minf(wander_timer, 0.8)
	# Limites do terreno.
	next.x = clampf(next.x, -42.0, 42.0)
	next.z = clampf(next.z, -42.0, 42.0)
	global_position = Vector3(next.x, home_position.y, next.z)
	visual.rotation.y = lerp_angle(visual.rotation.y, atan2(wander_direction.x, wander_direction.z), clampf(delta * 7.0, 0.0, 1.0))
	hop_phase += delta * 10.0
	visual.position.y = absf(sin(hop_phase)) * 0.075

func _pick_wander_direction() -> void:
	wander_timer = _rng.randf_range(1.4, 3.8)
	if _rng.randf() < 0.18:
		wander_direction = Vector3.ZERO
	else:
		var angle := _rng.randf_range(0.0, TAU)
		wander_direction = Vector3(cos(angle), 0.0, sin(angle))

func _steer_away(point: Vector3) -> Vector3:
	var push := Vector3.ZERO
	var lake_offset := Vector2(point.x - lake_center.x, point.z - lake_center.z)
	if lake_offset.length() < 6.8:
		var fallback := Vector3(_rng.randf_range(-1.0, 1.0), 0.0, _rng.randf_range(-1.0, 1.0))
		if lake_offset.length() < 0.05:
			push += fallback.normalized()
		else:
			push += Vector3(lake_offset.x, 0.0, lake_offset.y).normalized() * (6.8 - lake_offset.length())
	var ship_offset := Vector2(point.x - ship_center.x, point.z - ship_center.z)
	if ship_offset.length() < 7.4:
		var fallback := Vector3(_rng.randf_range(-1.0, 1.0), 0.0, _rng.randf_range(-1.0, 1.0))
		if ship_offset.length() < 0.05:
			push += fallback.normalized()
		else:
			push += Vector3(ship_offset.x, 0.0, ship_offset.y).normalized() * (7.4 - ship_offset.length())
	return push

func _keep_out(point: Vector3) -> Vector3:
	# Barreira rígida: nenhuma criatura entra na água ou na plataforma da nave.
	for zone in [[lake_center, 6.6], [ship_center, 7.6]]:
		var center: Vector3 = zone[0]
		var radius: float = zone[1]
		var offset := Vector2(point.x - center.x, point.z - center.z)
		if offset.length() < radius:
			var fallback := Vector2(1, 0) if offset.length() < 0.01 else offset.normalized()
			point.x = center.x + fallback.x * radius
			point.z = center.z + fallback.y * radius
	return point

func _respawn() -> void:
	available = true
	if tipo_item == "animal":
		global_position = home_position
		visual.position.y = 0.0
		wander_direction = Vector3.ZERO
		wander_timer = 0.0
	visual.show()

func display_name() -> String:
	return {"mineral": "minério", "fruit": "fruta", "plant": "planta", "crystal": "cristal", "stone": "pedra", "animal": "criatura"}.get(tipo_item, tipo_item)

func _part(shape: Mesh, color: Color, offset: Vector3, size: Vector3 = Vector3.ONE, glow: bool = false) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.mesh = shape
	part.position = offset
	part.scale = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	if glow:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 0.35
	part.material_override = material
	visual.add_child(part)
	return part

func _sphere(radius: float) -> SphereMesh:
	var shape := SphereMesh.new()
	shape.radius = radius
	shape.height = radius * 2.0
	shape.radial_segments = 8
	shape.rings = 4
	return shape

func _cone(radius: float, height: float) -> CylinderMesh:
	var shape := CylinderMesh.new()
	shape.top_radius = 0.0
	shape.bottom_radius = radius
	shape.height = height
	shape.radial_segments = 5
	return shape

func _build_visual() -> void:
	match tipo_item:
		"crystal":
			for i in range(3):
				var shard := _part(_cone(0.22, 1.1 - i * 0.18), Color("53dcd5"), Vector3((i - 1) * 0.26, -0.2, 0), Vector3.ONE, true)
				shard.rotation.z = (i - 1) * -0.25
		"mineral":
			_part(_sphere(0.5), Color("475d77"), Vector3(0, -0.45, 0), Vector3(1.2, 0.8, 1))
			for i in range(3):
				_part(_cone(0.16, 0.45), Color("efbf60"), Vector3((i - 1) * 0.23, -0.1, 0.12), Vector3.ONE, true)
		"stone":
			_part(_sphere(0.5), Color("bb7860"), Vector3(0, -0.45, 0), Vector3(1.3, 0.75, 0.9))
			_part(_sphere(0.24), Color("d4a17a"), Vector3(0.3, -0.6, 0.2))
		"plant", "fruit":
			var stem := CylinderMesh.new()
			stem.top_radius = 0.06
			stem.bottom_radius = 0.09
			stem.height = 0.7
			_part(stem, Color("276e61"), Vector3(0, -0.4, 0))
			for i in range(4):
				var angle := i * TAU / 4
				var leaf := _part(_sphere(0.3), Color("73d5a5"), Vector3(cos(angle) * 0.25, -0.25, sin(angle) * 0.25), Vector3(1.3, 0.3, 0.65))
				leaf.rotation.y = -angle
			if tipo_item == "fruit":
				for i in range(3):
					_part(_sphere(0.18), Color("ff786e"), Vector3((i - 1) * 0.22, 0, 0.1), Vector3.ONE)
			else:
				_part(_cone(0.25, 0.4), Color("e7a5e9"), Vector3(0, 0.06, 0), Vector3.ONE, true)
		"animal":
			_part(_sphere(0.36), Color("edab62"), Vector3(0, -0.3, 0), Vector3(1.4, 0.85, 1))
			_part(_sphere(0.25), Color("f2cf8f"), Vector3(0, -0.12, 0.35))
			for x in [-0.22, 0.22]:
				for z in [-0.2, 0.2]:
					_part(_sphere(0.12), Color("835453"), Vector3(x, -0.65, z), Vector3(0.7, 1.5, 0.7))
			for x in [-0.1, 0.1]:
				_part(_sphere(0.055), Color("192a3b"), Vector3(x, -0.08, 0.57))
				_part(_cone(0.09, 0.35), Color("be7361"), Vector3(x * 1.6, 0.16, 0.28))

func collect(body: Node3D) -> void:
	if not available or not body.is_in_group("player"):
		return
	available = false
	visual.hide()
	if body.has_method("add_score"):
		body.add_score(10)
	collected.emit(tipo_item)
	respawn_timer.start(12.0)

func restore_cooldown(seconds: float) -> void:
	available = seconds <= 0.0
	visual.visible = available
	if available:
		respawn_timer.stop()
	else:
		respawn_timer.start(clampf(seconds, 0.01, 12.0))
