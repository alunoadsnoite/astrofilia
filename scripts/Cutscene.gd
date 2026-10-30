extends Node3D

@onready var rocket: MeshInstance3D = $Rocket
@onready var ship: MeshInstance3D = $Ship
@onready var astronaut: MeshInstance3D = $Astronaut
@onready var planet: MeshInstance3D = $Planet
@onready var camera: Camera3D = $Camera3D
@onready var mission_panel: ColorRect = $CanvasLayer/MissionPanel
@onready var mission_label: Label = $CanvasLayer/MissionPanel/MissionLabel
@onready var applause_label: Label = $CanvasLayer/ApplauseLabel

var mission_index: int = 0
var mission_timer: float = 3.5

func _ready() -> void:
	mission_panel.visible = false
	applause_label.visible = false
	# O planeta usa um shader procedural com oceanos, continentes,
	# desertos e calotas polares (ver assets/planet_shader.gdshader).
	# Nuvens
	var clouds := MeshInstance3D.new()
	var csm := SphereMesh.new()
	csm.radius = 41.5
	csm.height = 83.0
	clouds.mesh = csm
	var cloud_mat := StandardMaterial3D.new()
	cloud_mat.albedo_color = Color(1, 1, 1, 0.25)
	cloud_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cloud_mat.roughness = 1.0
	clouds.material_override = cloud_mat
	planet.add_child(clouds)
	# Foguete colorido
	var rocket_mat := StandardMaterial3D.new()
	rocket_mat.albedo_color = Color(0.9, 0.3, 0.2)
	rocket_mat.emission_enabled = true
	rocket_mat.emission = Color(0.4, 0.1, 0.05)
	rocket.material_override = rocket_mat
	_build_rocket_details(rocket_mat)
	# Nave colorida
	var ship_mat := StandardMaterial3D.new()
	ship_mat.albedo_color = Color(0.7, 0.75, 0.85)
	ship_mat.metallic = 0.6
	ship_mat.roughness = 0.3
	ship.material_override = ship_mat
	_build_ship_details(ship_mat)
	# Astronauta colorido
	var astro_mat := StandardMaterial3D.new()
	astro_mat.albedo_color = Color(1.0, 0.85, 0.2)
	astro_mat.emission_enabled = true
	astro_mat.emission = Color(0.5, 0.4, 0.1)
	astro_mat.emission_energy_multiplier = 0.4
	astronaut.material_override = astro_mat
	# Estrelas de fundo
	_add_stars()
	await _play_cutscene()

func _build_rocket_details(mat: StandardMaterial3D) -> void:
	# Cone topo
	var cone := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0
	cm.bottom_radius = 1.5
	cm.height = 3.0
	cone.mesh = cm
	cone.position = Vector3(0, 5.5, 0)
	cone.material_override = mat
	rocket.add_child(cone)
	# Aletas
	for i in range(4):
		var fin := MeshInstance3D.new()
		var fm := BoxMesh.new()
		fm.size = Vector3(0.2, 3.0, 1.5)
		fin.mesh = fm
		var angle := i * 90.0
		fin.position = Vector3(sin(deg_to_rad(angle)) * 2.2, -2.5, cos(deg_to_rad(angle)) * 2.2)
		fin.rotation_degrees = Vector3(0, angle, 0)
		fin.material_override = mat
		rocket.add_child(fin)

func _build_ship_details(mat: StandardMaterial3D) -> void:
	# Asas
	for side in [-1, 1]:
		var wing := MeshInstance3D.new()
		var wm := BoxMesh.new()
		wm.size = Vector3(8.0, 0.3, 2.0)
		wing.mesh = wm
		wing.position = Vector3(side * 6.0, 0, 0)
		wing.rotation_degrees = Vector3(0, 0, side * 15.0)
		wing.material_override = mat
		ship.add_child(wing)
	# Cockpit
	var cockpit := MeshInstance3D.new()
	var ckm := SphereMesh.new()
	ckm.radius = 1.2
	ckm.height = 2.4
	cockpit.mesh = ckm
	cockpit.position = Vector3(0, 1.2, 1.5)
	var cockpit_mat := StandardMaterial3D.new()
	cockpit_mat.albedo_color = Color(0.2, 0.6, 0.9)
	cockpit_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cockpit_mat.albedo_color.a = 0.6
	cockpit_mat.emission_enabled = true
	cockpit_mat.emission = Color(0.3, 0.7, 1.0)
	cockpit_mat.emission_energy_multiplier = 0.8
	cockpit.material_override = cockpit_mat
	ship.add_child(cockpit)

func _add_continents() -> void:
	var continents := [
		{"pos": Vector3(12, 5, 8), "color": Color(0.15, 0.6, 0.25), "scale": Vector3(18, 6, 14)},
		{"pos": Vector3(-10, -3, 15), "color": Color(0.15, 0.6, 0.25), "scale": Vector3(14, 5, 12)},
		{"pos": Vector3(5, -12, -6), "color": Color(0.85, 0.75, 0.2), "scale": Vector3(10, 4, 8)},
		{"pos": Vector3(-14, 8, -5), "color": Color(0.85, 0.75, 0.2), "scale": Vector3(8, 3, 7)},
		{"pos": Vector3(18, -5, -12), "color": Color(0.95, 0.95, 0.98), "scale": Vector3(12, 4, 10)},
		{"pos": Vector3(-6, 14, 10), "color": Color(0.95, 0.95, 0.98), "scale": Vector3(9, 3, 8)},
	]
	for c in continents:
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 1.0
		sm.height = 2.0
		mi.mesh = sm
		mi.position = (c["pos"] as Vector3).normalized() * 38.0
		mi.scale = c["scale"]
		var m := StandardMaterial3D.new()
		m.albedo_color = c["color"]
		m.roughness = 0.7
		mi.material_override = m
		planet.add_child(mi)

func _add_stars() -> void:
	var particles := CPUParticles3D.new()
	particles.amount = 400
	particles.lifetime = 8.0
	particles.preprocess = 4.0
	particles.emission_shape = 2
	particles.emission_box_extents = Vector3(80, 50, 80)
	particles.gravity = Vector3.ZERO
	particles.initial_velocity_min = 0.0
	particles.initial_velocity_max = 0.0
	particles.scale_amount_min = 0.08
	particles.scale_amount_max = 0.3
	particles.color = Color(1, 1, 1, 0.9)
	add_child(particles)

func _play_cutscene() -> void:
	# Fase 1: foguete parte com aplausos
	applause_label.visible = true
	var tw := create_tween()
	tw.tween_property(rocket, "position:y", 60.0, 2.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(rocket, "position:z", 0.0, 2.5)
	await tw.finished
	applause_label.visible = false
	await get_tree().create_timer(0.5).timeout

	# Fase 2: nave pousa no planeta
	ship.visible = true
	ship.position = Vector3(0, 30, 0)
	var tw2 := create_tween()
	tw2.tween_property(ship, "position:y", 6.0, 2.0).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	await tw2.finished
	await get_tree().create_timer(0.5).timeout

	# Astronauta desce
	astronaut.visible = true
	astronaut.position = Vector3(0, 6.0, 0)
	var tw3 := create_tween()
	tw3.tween_property(astronaut, "position:y", 0.5, 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await tw3.finished
	await get_tree().create_timer(0.5).timeout

	# Fase 3: missões
	GameManager.build_mission_list()
	mission_panel.visible = true
	await _run_missions()
	# Missão final
	var final_text := GameManager.t("mission_final_mp") if not GameManager.singleplayer else GameManager.t("mission_final_sp")
	mission_label.text = final_text
	await get_tree().create_timer(3.0).timeout
	# Transição
	mission_label.text = "⚠ Sistema da nave falhando... ⚠"
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://scenes/Gameplay.tscn")

func _run_missions() -> void:
	var list: Array[Dictionary] = []
	for m in GameManager.mission_list:
		list.append(m)

	for m in list:
		mission_label.text = GameManager.get_mission_text(m)
		await get_tree().create_timer(mission_timer).timeout
		GameManager.advance_mission()
		if GameManager.missions_complete:
			break
	mission_panel.visible = false
	await get_tree().create_timer(0.3).timeout
	mission_panel.visible = true
