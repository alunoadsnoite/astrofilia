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
	manager.in_interior = false
	manager.pending_snapshot.clear()
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
	var entered_area := false
	var floor_height := 0.0
	for i in range(240):
		await physics_frame
		if scene._near_ship_entrance():
			floor_height = player.global_position.y
			entered_area = true
			break
	player.external_move = Vector2.ZERO
	check(entered_area, "player walks up the ramp to the ship entrance")
	check(floor_height > 1.0, "player stands at the raised entrance")
	check(not scene._player_inside_ship(), "the exterior hull is not the interior scene")

	# A entrada troca para o cenário interior, guardando o retorno ao planeta.
	var return_position: Vector3 = player.global_position
	scene._enter_ship(false)
	check(manager.in_interior, "entering the ship switches to the interior scene")
	check(scene._is_interior(), "gameplay reads the interior mode from the manager")
	check(manager.pending_snapshot.get("in_interior", false), "the interior flag is stored for the scene reload")
	var spawn: Array = manager.pending_snapshot.get("position", [])
	check(spawn.size() == 3 and Vector3(spawn[0], spawn[1], spawn[2]).distance_to(scene.INTERIOR_SPAWN) < 0.01, "player is moved to the interior spawn")
	var saved_return: Array = manager.pending_snapshot.get("interior_return", [])
	check(saved_return.size() == 3 and Vector3(saved_return[0], saved_return[1], saved_return[2]).distance_to(return_position) < 1.0, "exterior position is kept for the way back")
	check(manager.interior_snapshot.get("in_interior", false), "interior snapshot keeps the run state")
	check(not manager.interior_snapshot.get("resource_cooldowns", []).is_empty(), "exterior resource cooldowns follow the player inside")

	# Volta ao planeta para os testes do lago.
	manager.in_interior = false
	manager.pending_snapshot.clear()
	scene.transitioning = false

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
