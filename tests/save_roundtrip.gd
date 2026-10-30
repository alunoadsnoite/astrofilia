extends SceneTree

var failures: Array[String] = []

func check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
	print(("PASS " if condition else "FAIL ") + description)

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	# Always run with XDG_DATA_HOME pointing to a test-only directory.
	var manager = root.get_node("GameManager")
	manager.saved_games.clear()
	manager.player_name = "Teste slot 1"
	manager.singleplayer = true
	check(manager.begin_new_game(0) == OK, "create first slot")
	var scene = load("res://scenes/Gameplay.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	scene.player.set_physics_process(false)
	scene.player.position = Vector3(5, 1, -4)
	scene.health = 73.0
	scene.hunger = 42.0
	scene.thirst = 31.0
	scene.inventory.crystal = 8
	scene.set_score(120)
	scene.player.score = 120
	scene.time_of_day = 0.75
	scene.weather = "snow"
	scene.weather_timer = 17.0
	manager.current_mission_index = 7
	manager.current_mission_progress = 2
	scene.items_node.get_child(0).restore_cooldown(9.0)
	var original_seed = scene.world_seed
	var original_tree_position: Vector3 = Vector3.ZERO
	for child in scene.get_children():
		if child is MeshInstance3D and child.mesh is CylinderMesh:
			original_tree_position = child.position
			break
	check(scene._save_progress() == OK, "snapshot written to disk")
	var first_snapshot: Dictionary = manager.saved_games[0].snapshot.duplicate(true)
	scene.queue_free()
	await process_frame
	check(auto_accept_quit, "closing gameplay restores normal window-close handling")
	manager.player_name = "Teste slot 2"
	manager.singleplayer = false
	manager.role = "biologist"
	check(manager.begin_new_game(1) == OK, "create independent second slot")
	var second_scene = load("res://scenes/Gameplay.tscn").instantiate()
	root.add_child(second_scene)
	second_scene.set_process(false)
	second_scene.player.set_physics_process(false)
	second_scene.inventory.stone = 3
	check(second_scene._save_progress() == OK, "second slot snapshot written")
	check(manager.saved_games[0].snapshot == first_snapshot, "writing slot 2 preserves slot 1")
	second_scene.queue_free()
	await process_frame
	manager.saved_games.clear()
	manager.current_mission_index = 0
	manager.current_mission_progress = 0
	manager.load_game()
	check(manager.saved_games.size() == 2, "both slots reload from disk")
	check(manager.prepare_continue(0), "prepare saved singleplayer slot")
	check(manager.singleplayer and manager.current_mission_index == 7 and manager.current_mission_progress == 2, "mode and partial mission progress restored")
	var restored = load("res://scenes/Gameplay.tscn").instantiate()
	root.add_child(restored)
	restored.set_process(false)
	restored.player.set_physics_process(false)
	check(restored.player.position == Vector3(5, 1, -4), "player position restored")
	check(restored.health == 73.0 and restored.hunger == 42.0 and restored.thirst == 31.0, "survival values restored")
	check(restored.inventory.crystal == 8 and restored.score == 120 and restored.player.score == 120, "inventory and both score counters restored")
	check(restored.time_of_day == 0.75 and restored.weather == "snow" and restored.weather_timer == 17.0, "time and weather restored")
	check(restored.world_seed == original_seed, "world seed restored")
	var restored_tree_position: Vector3 = Vector3.ZERO
	for child in restored.get_children():
		if child is MeshInstance3D and child.mesh is CylinderMesh:
			restored_tree_position = child.position
			break
	check(restored_tree_position == original_tree_position, "scenery stays in the same location")
	var resource = restored.items_node.get_child(0)
	check(not resource.available and resource.respawn_timer.time_left > 8.0, "resource cooldown restored")
	restored.player.add_score(10)
	check(restored.score == 130, "score continues from saved value")
	var living_snapshot: Dictionary = manager.saved_games[0].snapshot.duplicate(true)
	restored.health = 0.0
	restored.game_over = true
	restored._save_progress()
	check(manager.saved_games[0].snapshot == living_snapshot, "death preserves last living checkpoint")
	restored.queue_free()
	await process_frame
	var menu = load("res://scenes/MainMenu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	var slots_before: Array = manager.saved_games.duplicate(true)
	menu._on_new_game_pressed()
	check(menu.choosing_new_slot and manager.saved_games == slots_before, "new game with full slots waits for a slot selection")
	menu._on_slot_pressed(0)
	check(menu.overwrite_dialog.visible and manager.saved_games == slots_before, "occupied slot requires confirmation before replacement")
	menu.overwrite_dialog.hide()
	menu._on_play_pressed()
	menu._on_slot_pressed(0)
	await process_frame
	var continued = current_scene
	check(continued != null and continued.scene_file_path == "res://scenes/Gameplay.tscn", "continue opens gameplay directly without the cutscene")
	if continued != null:
		continued.set_process(false)
		continued.player.set_physics_process(false)
		check(continued.inventory.crystal == 8 and manager.current_mission_index == 7, "menu continue restores gameplay progress")
		continued.queue_free()
	await process_frame
	check(manager.prepare_continue(1) and not manager.singleplayer and manager.role == "biologist", "second slot restores its own role and mode")
	manager.pending_snapshot.clear()
	for appearance in ["default", "blue", "red", "green"]:
		manager.appearance = appearance
		var player = load("res://scenes/Player.tscn").instantiate()
		root.add_child(player)
		var expected: Color = {"default": Color("edf1e8"), "blue": Color("438bd1"), "red": Color("d86b62"), "green": Color("64b38c")}[appearance]
		check(player.get_child(3).material_override.albedo_color == expected, "suit material applies " + appearance)
		player.queue_free()
	await process_frame
	# Legacy metadata has no gameplay to restore, but remains available as a new tutorial.
	manager.saved_games[0] = {"name": "Legacy", "created": 1}
	check(not manager.has_snapshot(0) and not manager.prepare_continue(0), "legacy metadata is not mistaken for a resumable game")
	manager.singleplayer = false
	for role in ["collector", "biologist"]:
		manager.role = role
		manager.build_mission_list()
		var safety := 0
		while not manager.missions_complete and safety < 30:
			safety += 1
			var mission = manager.get_current_mission()
			manager.register_action(mission.action, mission.target)
		check(manager.missions_complete and manager.mission_list.size() == 8, "eight role missions complete for " + role)
	manager.singleplayer = true
	manager.build_mission_list()
	check(not manager.register_action("report", "any") and manager.current_mission_index == 0, "report action cannot bypass another mission")
	print("CHECKS COMPLETE: ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
