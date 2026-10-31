extends SceneTree

var failures: Array[String] = []

func check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
	print(("PASS " if condition else "FAIL ") + description)

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var scene = load("res://scenes/Gameplay.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	scene.set_process(false)

	# Fica de frente para a rampa e caminha em direção à porta.
	var player: CharacterBody3D = scene.player
	player.global_position = scene.ship_position + Vector3(0, 1.0, 12.0)
	await physics_frame
	player.external_move = Vector2(0, -1)
	var entered := false
	var floor_height := 0.0
	for i in range(220):
		await physics_frame
		var local: Vector3 = player.global_position - scene.ship_position
		if local.z < 4.2 and absf(local.x) < 1.4:
			floor_height = player.global_position.y
			entered = scene._player_inside_ship()
			if entered:
				break
	player.external_move = Vector2.ZERO
	scene._update_ship_interior(0.05)
	check(entered, "player walks up the ramp and enters the ship")
	check(floor_height > 1.2, "player stands on the raised ship floor")
	check(scene.ship_inside, "ship interior state detects the player")

	# Não é possível atravessar a água.
	player.global_position = scene.lake_position + Vector3(0, 1.0, -8.0)
	await physics_frame
	player.external_move = Vector2(0, 1)
	for i in range(180):
		await physics_frame
	player.external_move = Vector2.ZERO
	var lake_distance := Vector2(player.global_position.x - scene.lake_position.x, player.global_position.z - scene.lake_position.z).length()
	check(lake_distance >= 5.6, "lake blocker stops the player at the shore")

	# E pode contornar o lago pelas laterais.
	player.global_position = scene.lake_position + Vector3(-8.0, 1.0, 0)
	await physics_frame
	player.external_move = Vector2(0, 1)
	for i in range(40):
		await physics_frame
	player.external_move = Vector2.ZERO
	check(player.global_position.z > scene.lake_position.z + 2.0, "player can walk around the side of the lake")

	scene.queue_free()
	await process_frame
	print("CHECKS COMPLETE: ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
