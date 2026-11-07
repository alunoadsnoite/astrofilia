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
	manager.in_interior = false
	var scene = load("res://scenes/Gameplay.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.set_process(false)
	scene.player.set_physics_process(false)
	scene.touch_controls.show()

	var center: Vector2 = scene.joystick_base.get_global_rect().get_center()
	var radius: float = scene._joystick_radius()
	var action: Vector2 = scene.interact_button.get_global_rect().get_center()
	var jump: Vector2 = scene.jump_button.get_global_rect().get_center()
	check(radius > 20.0, "joystick has a usable radius")

	# 360°: cada direção do círculo vira um vetor de movimento.
	scene.player.position = scene.items_node.get_child(0).position
	touch(scene, 0, center + Vector2(radius, 0), true)
	check(scene.touch_dir.x > 0.95 and absf(scene.touch_dir.y) < 0.05, "joystick points east at full tilt")
	touch(scene, 0, center + Vector2(cos(0.7), sin(0.7)) * radius, true)
	check(scene.touch_dir.distance_to(Vector2(cos(0.7), sin(0.7))) < 0.02, "joystick supports arbitrary 360 degree angles")
	touch(scene, 0, center + Vector2(0, radius), true)
	check(scene.touch_dir.y > 0.95 and absf(scene.touch_dir.x) < 0.05, "joystick points south")
	touch(scene, 0, center + Vector2(0, -radius), true)
	check(scene.touch_dir.y < -0.95 and absf(scene.touch_dir.x) < 0.05, "joystick points north")

	# Meia inclinação produz meia velocidade (movimento analógico).
	touch(scene, 0, center + Vector2(radius * 0.5, 0), true)
	var half: float = scene.touch_dir.length()
	check(half > 0.3 and half < 0.6, "joystick tilt controls analog speed")
	touch(scene, 0, center, true)
	check(scene.touch_dir == Vector2.ZERO, "joystick deadzone ignores the centre")
	touch(scene, 0, center + Vector2(radius, 0), true)

	# Segundo dedo no botão de ação: coleta sem parar a caminhada.
	touch(scene, 1, action, true)
	check(scene.inventory.mineral == 1 and scene.touch_dir.x > 0.95, "second thumb acts while the joystick keeps moving")
	touch(scene, 1, action, false)
	check(scene.touch_dir.x > 0.95, "releasing the action does not stop movement")

	# Arrastar para fora da base continua controlando a direção.
	drag(scene, 0, center + Vector2(radius * 2.4, radius * 0.4))
	check(scene.touch_dir.x > 0.9 and scene.touch_dir.length() <= 1.001, "dragging beyond the base clamps to full speed")
	check(scene.touch_dir.distance_to(Vector2(2.4, 0.4).normalized()) < 0.02, "dragging beyond the base keeps the joystick angle")

	# Um segundo dedo no joystick é ignorado enquanto o primeiro controla.
	touch(scene, 2, center + Vector2(0, -radius), true)
	check(scene.touch_dir.x > 0.9, "second finger on the joystick cannot steal control")
	check(scene.joystick_index == 0, "joystick stays bound to the first finger")
	touch(scene, 2, center + Vector2(0, -radius), false)
	touch(scene, 0, center, false)
	check(scene.touch_dir == Vector2.ZERO and scene.touch_fingers.is_empty(), "releasing the joystick clears movement")

	# Estabelece contato com o chão antes de checar o impulso de salto.
	scene.player.position = Vector3(0, 0.81, 0)
	scene.player.velocity = Vector3.ZERO
	scene.player.set_physics_process(true)
	for i in range(15):
		await physics_frame
	scene.player.set_physics_process(false)
	check(scene.player.is_on_floor(), "player grounded for jump check")
	touch(scene, 0, center + Vector2(-radius, 0), true)
	touch(scene, 1, jump, true)
	check(scene.player.velocity.y == scene.player.JUMP_VELOCITY and scene.touch_dir.x < -0.95, "jump and analog movement work simultaneously")

	scene._toggle_pause()
	check(scene.touch_dir == Vector2.ZERO and scene.touch_fingers.is_empty(), "pause clears held touches")
	scene._toggle_pause()
	touch(scene, 0, center + Vector2(radius, 0), true)
	scene._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(scene.touch_dir == Vector2.ZERO and scene.joystick_index == -1, "focus loss clears the joystick")

	scene.queue_free()
	await process_frame
	print("CHECKS COMPLETE: ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
