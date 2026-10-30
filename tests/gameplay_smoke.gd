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
	manager.build_mission_list()
	var scene = load("res://scenes/Gameplay.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.set_process(false)
	scene.player.set_physics_process(false)
	check(scene.items_node.get_child_count() == 30, "30 resources instantiate")
	var item = scene.items_node.get_child(0)
	var initial = scene.inventory.mineral
	item.collect(scene.player)
	item.collect(scene.player)
	check(scene.inventory.mineral == initial + 1, "one collection emits once and updates inventory")
	check(not item.available, "collected resource is temporarily unavailable")
	Engine.time_scale = 60.0
	await create_timer(12.1).timeout
	Engine.time_scale = 1.0
	check(item.available and item.visual.visible, "resource respawns after cooldown")
	# Move to the lake after the tutorial, ensuring hydration remains available.
	manager.missions_complete = true
	manager.current_mission_index = manager.mission_list.size()
	scene.player.position = scene.lake_position + Vector3(0, 1, 0)
	scene.thirst = 20.0
	scene._on_interact_pressed()
	check(scene.thirst == 60.0, "lake restores water after mission completion")
	scene._on_interact_pressed()
	scene._on_interact_pressed()
	check(scene.thirst == 100.0, "hydration is capped at 100")
	manager.build_mission_list()
	var safety := 0
	while not manager.missions_complete and safety < 40:
		safety += 1
		var mission = manager.get_current_mission()
		if mission.action == "report":
			scene._on_interact_pressed()
		elif mission.target == "lake":
			scene.player.position = scene.lake_position + Vector3(0, 1, 0)
			scene._on_interact_pressed()
		else:
			var found := false
			for resource in scene.items_node.get_children():
				if resource.tipo_item == mission.target and resource.available:
					scene.player.position = resource.position
					scene._on_interact_pressed()
					found = true
					break
			if not found:
				break
	check(manager.missions_complete, "all 16 singleplayer missions complete through interaction")
	scene._toggle_pause()
	check(paused and scene.pause_panel.can_process(), "pause menu remains interactive while paused")
	scene._toggle_pause()
	check(not paused, "resume unpauses game")
	check(InputMap.action_has_event("move_forward", make_key(KEY_W)), "W mapped to forward")
	check(InputMap.action_has_event("move_back", make_key(KEY_S)), "S mapped to backward")
	scene.queue_free()
	await process_frame
	print("CHECKS COMPLETE: ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)

func make_key(code: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	return event
