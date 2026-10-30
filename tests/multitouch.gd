extends SceneTree

var failures: Array[String] = []

func check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
	print(("PASS " if condition else "FAIL ") + description)

func _initialize() -> void:
	call_deferred("run_checks")

func touch(scene: Node, index: int, position: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	scene._input(event)

func drag(scene: Node, index: int, position: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = position
	scene._input(event)

func run_checks() -> void:
	var manager = root.get_node("GameManager")
	manager.singleplayer = false
	manager.role = "collector"
	manager.build_mission_list()
	var scene = load("res://scenes/Gameplay.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.set_process(false)
	scene.player.set_physics_process(false)
	scene.touch_controls.show()
	var right: Vector2 = scene.right_button.get_global_rect().get_center()
	var up: Vector2 = scene.up_button.get_global_rect().get_center()
	var action: Vector2 = scene.interact_button.get_global_rect().get_center()
	var jump: Vector2 = scene.jump_button.get_global_rect().get_center()
	scene.player.position = scene.items_node.get_child(0).position
	touch(scene, 0, right, true)
	check(scene.touch_dir == Vector2.RIGHT, "left thumb holds movement")
	touch(scene, 1, action, true)
	check(scene.inventory.mineral == 1 and scene.touch_dir == Vector2.RIGHT, "right thumb collects while left thumb keeps moving")
	touch(scene, 1, action, false)
	check(scene.touch_dir == Vector2.RIGHT, "releasing action does not stop movement")
	touch(scene, 2, right, true)
	touch(scene, 0, right, false)
	check(scene.touch_dir == Vector2.RIGHT, "releasing one of two fingers on movement keeps other finger active")
	drag(scene, 2, up)
	check(scene.touch_dir == Vector2.UP, "dragging movement finger switches direction")
	drag(scene, 2, Vector2(-10, -10))
	check(scene.touch_dir == Vector2.ZERO, "dragging outside controls stops movement")
	drag(scene, 2, right)
	check(scene.touch_dir == Vector2.RIGHT, "dragging the same finger back resumes movement")
	touch(scene, 2, Vector2(-10, -10), false)
	check(scene.touch_dir == Vector2.ZERO and scene.touch_fingers.is_empty(), "releasing outside controls clears finger")
	# Establish floor contact before checking the actual jump impulse.
	scene.player.position = Vector3(0, 0.81, 0)
	scene.player.velocity = Vector3.ZERO
	scene.player.set_physics_process(true)
	for i in range(15):
		await physics_frame
	scene.player.set_physics_process(false)
	check(scene.player.is_on_floor(), "player grounded for jump check")
	touch(scene, 0, right, true)
	touch(scene, 1, jump, true)
	check(scene.player.velocity.y == scene.player.JUMP_VELOCITY and scene.touch_dir == Vector2.RIGHT, "jump and movement work simultaneously")
	scene._toggle_pause()
	check(scene.touch_dir == Vector2.ZERO and scene.touch_fingers.is_empty(), "pause clears held touches")
	scene._toggle_pause()
	touch(scene, 0, right, true)
	scene._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(scene.touch_dir == Vector2.ZERO, "focus loss clears held movement")
	scene.queue_free()
	await process_frame
	print("CHECKS COMPLETE: ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
