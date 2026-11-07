extends SceneTree

var failures: Array[String] = []

func check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
	print(("PASS " if condition else "FAIL ") + description)

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var manager = root.get_node("GameManager")
	manager.singleplayer = true
	manager.role = "collector"
	manager.build_mission_list()
	manager.in_interior = false
	manager.pending_snapshot.clear()

	var scene = load("res://scenes/Gameplay.tscn").instantiate()
	# Simula o modo de baixo custo usado no Android antes de montar a cena.
	scene.low_end = true
	root.add_child(scene)
	await process_frame
	scene.set_process(false)
	scene.player.set_physics_process(false)

	check(scene.low_end, "mobile budget enables low-end mode")
	check(Engine.max_fps == 60, "mobile budget caps the frame rate at 60 fps")
	var viewport: Viewport = scene.get_viewport()
	check(viewport.scaling_3d_scale <= 0.8, "mobile budget lowers the 3D render scale")

	var env: Environment = scene.get_node("WorldEnvironment").environment
	check(not env.glow_enabled, "mobile budget disables glow")
	check(not env.ssao_enabled and not env.ssil_enabled and not env.sdfgi_enabled, "mobile budget disables heavy screen effects")
	check(not scene.sun.shadow_enabled, "mobile budget disables the sun shadow")

	var ground: MeshInstance3D = scene.get_node("BiomeGround")
	var plane := ground.mesh as PlaneMesh
	check(plane != null and plane.subdivide_width == 16 and plane.subdivide_depth == 16, "mobile budget reduces terrain subdivisions")

	check(scene.stars_instance.multimesh.instance_count <= 130, "mobile budget reduces the starfield")
	check(scene.rain_fx.amount <= 200 and scene.snow_fx.amount <= 160, "mobile budget reduces weather particles")
	check(scene.dust_fx.amount <= 80, "mobile budget reduces ambient dust")

	# Nenhum cenário fora do jogador continua projetando sombra.
	var shadow_casters := 0
	for node in scene.find_children("*", "MeshInstance3D", true, false):
		if scene.player.is_ancestor_of(node):
			continue
		if node.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			shadow_casters += 1
	check(shadow_casters == 0, "mobile budget removes scenery shadow casters (%d left)" % shadow_casters)

	# A densidade de props cai, mas a composição continua existindo.
	var scenery_meshes: Array[Node] = scene.find_children("*", "MeshInstance3D", true, false)
	check(scenery_meshes.size() > 40, "mobile budget keeps the scenery readable")

	scene.queue_free()
	await process_frame
	print("CHECKS COMPLETE: ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
