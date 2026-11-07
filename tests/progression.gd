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
	manager.experience = 0
	manager.level = 1
	manager.xp_to_next_level = 100
	manager.in_interior = false
	manager.pending_snapshot.clear()

	var scene = load("res://scenes/Gameplay.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.set_process(false)
	scene.player.set_physics_process(false)

	check(manager.chapter_for_index(0) == 1, "first mission is chapter 1")
	check(manager.chapter_for_index(4) == 2, "mission 5 starts chapter 2")
	check(manager.chapter_for_index(8) == 3, "mission 9 starts chapter 3")
	check(manager.chapter_for_index(12) == 4, "mission 13 starts chapter 4")
	check(manager.chapter_for_index(16) == 5, "finishing all missions reaches chapter 5")

	check(scene.chapter_banner.visible, "chapter banner is shown on start")
	check(scene.chapter_title.text == "CAPÍTULO 1", "chapter 1 title is displayed")
	check(manager.experience == 0, "first banner does not grant xp")

	check(scene.level_label.text == "NV 1", "level label shows NV")
	check(scene.xp_label.text == "EXP 0/100", "xp label shows EXP")
	check(scene.xp_bar.max_value == 100.0 and scene.xp_bar.value == 0.0, "xp bar reflects progress")

	scene._gain_xp(10)
	check(manager.experience == 10, "xp is gained")
	check(scene.xp_bar.value == 10.0, "xp bar moves")

	scene.health = 50.0
	scene._gain_xp(95)
	check(manager.level == 2, "level up at xp threshold")
	check(scene.level_label.text == "NV 2", "level label updates")
	check(scene.health > 50.0, "level up heals slightly")

	manager.current_mission_index = 4
	manager.current_mission_progress = 0
	manager.experience = 0
	manager.level = 1
	manager.xp_to_next_level = 100
	scene._check_chapter()
	check(scene.chapter_title.text == "CAPÍTULO 2", "chapter title advances to 2")
	check(scene.chapter_subtitle.text == "A Nave Silenciosa", "chapter 2 subtitle matches the powered ship")
	check(manager.experience == 50, "advancing a chapter grants 50 xp")
	check(scene.chapter_banner.visible and scene.chapter_banner.modulate.a <= 0.01, "banner fades in from transparent")

	manager.current_mission_index = 8
	scene._check_chapter()
	check(scene.chapter_title.text == "CAPÍTULO 3", "chapter title advances to 3")

	manager.missions_complete = true
	manager.current_mission_index = manager.mission_list.size()
	scene._check_chapter()
	check(scene.chapter_title.text == "CAPÍTULO 5", "finishing the game shows chapter 5")
	var final_snapshot: Dictionary = scene._snapshot()
	manager.missions_complete = false
	manager.current_mission_index = 0
	scene._restore_snapshot(final_snapshot)
	check(manager.missions_complete and manager.current_mission_index == manager.mission_list.size(), "completed game stays completed after restoring a save")
	check(scene.mission_label.text == "Volte para casa! Ative o console da nave", "final mission message survives save/load")

	# Desfecho: agora só existe dentro da nave, no console.
	manager.missions_complete = false
	scene.player.global_position = scene.ship_position + Vector3(0, 1.4, 0)
	scene._start_ending()
	check(not scene.ending_started, "ending does not start before all missions are complete")
	manager.missions_complete = true
	scene._start_ending()
	check(not scene.ending_started, "ending cannot start from the planet exterior")
	check(not scene.ending_overlay.visible and not scene.ending_panel.visible, "ending panel stays hidden outside the ship")
	manager.missions_complete = false
	manager.current_mission_index = 0

	# Cobras noturnas: nó separado de Items, ativas só à noite.
	check(scene.snake_root != null and scene.snake_root.name == "Snakes", "snakes live in their own node")
	check(scene.snakes.size() == 5, "five night snakes are spawned")
	var animal_count := 0
	for creature in scene.items_node.get_children():
		if creature.tipo_item == "animal":
			animal_count += 1
	check(animal_count == 5, "snakes do not change the five creatures in Items")
	var snake: Node3D = scene.snakes[0]
	scene.time_of_day = 0.5
	scene.player.global_position = snake.global_position + Vector3(1.0, 0, 0)
	scene._update_snakes(0.0)
	check(not snake.active, "snakes stay hidden during the day")
	scene.time_of_day = 0.0
	scene._update_snakes(0.0)
	check(snake.active, "snakes wake up at night near the player")
	scene.damage_cooldown = 0.0
	snake.attack_timer = 0.0
	var health_before_snake: float = scene.health
	snake._process(0.1)
	check(scene.health < health_before_snake, "a night snake bites a nearby player")
	var snake_health: float = snake.health
	scene._attack_snake(snake)
	check(snake.health < snake_health, "the player can fight back against a snake")
	scene._attack_snake(snake)
	check(not snake.active and not snake.visible, "a defeated snake disappears")
	check(manager.achievements.has("Caçador de cobras"), "defeating a snake unlocks an achievement")
	snake._respawn()
	check(snake.health == snake.max_health, "snakes respawn with full health")
	scene.time_of_day = 0.5
	scene._update_snakes(0.0)
	check(not snake.active, "snakes hide again when day returns")

	# Limite do planeta: paredes invisíveis e recuperação da gravidade.
	check(scene.boundary_body != null and scene.boundary_body.get_child_count() == 4, "planet boundary has four invisible walls")
	var boundary_ok := true
	for wall in scene.boundary_body.get_children():
		if not (wall is CollisionShape3D and wall.shape is BoxShape3D):
			boundary_ok = false
	check(boundary_ok, "planet boundary uses box colliders")
	scene.last_safe_position = Vector3(6, 1, 6)
	scene.player.global_position = Vector3(6, -12, 6)
	scene._update_planet_bounds()
	check(scene.player.global_position.y > 0.0, "astronaut is pulled back before falling into the void")
	scene.last_safe_position = Vector3(6, 1, 6)
	scene.player.global_position = Vector3(80, 1, 0)
	scene._update_planet_bounds()
	check(absf(scene.player.global_position.x) <= 43.6, "astronaut cannot stay outside the planet area")

	# HUD de sobrevivência com porcentagem.
	scene.hunger = 53.4
	scene.thirst = 20.0
	scene._update_bars()
	check("53" in scene.hunger_label.text, "hunger label shows percentage")
	check(scene.thirst_label.modulate != Color.WHITE, "low thirst label is tinted")

	# Relógio e clima.
	scene.time_of_day = 0.5
	scene.weather = "clear"
	scene._update_time_label()
	check(scene.time_label.text.contains("12:00"), "clock shows noon")
	check(scene.time_label.text.begins_with("☀"), "clear weather uses sun icon")
	scene.weather = "rain"
	scene._update_time_label()
	check(scene.time_label.text.begins_with("🌧"), "rain weather uses rain icon")

	# Partículas de clima.
	check(scene.rain_fx != null and scene.snow_fx != null and scene.sand_fx != null and scene.dust_fx != null, "weather particles are created")
	scene.paused = false
	scene.game_over = false
	scene.weather = "rain"
	scene._update_weather_fx(0.0)
	check(scene.rain_fx.emitting and not scene.snow_fx.emitting, "rain particles emit only for rain")
	scene.weather = "snow"
	scene._update_weather_fx(0.0)
	check(scene.snow_fx.emitting and not scene.rain_fx.emitting, "snow particles emit only for snow")
	scene.weather = "sandstorm"
	scene._update_weather_fx(0.0)
	check(scene.sand_fx.emitting and not scene.dust_fx.emitting, "sandstorm particles emit only for sandstorm")
	scene.weather = "clear"
	scene._update_weather_fx(0.0)
	check(scene.dust_fx.emitting and not scene.sand_fx.emitting, "clear weather keeps light dust")

	# Ciclo dia/noite.
	scene.time_of_day = 0.5
	scene._update_day_night()
	var noon_energy: float = scene.sun.light_energy
	scene.time_of_day = 0.0
	scene._update_day_night()
	check(scene.sun.light_energy < noon_energy, "sun is dim at midnight")
	check(scene.moon_light.light_energy > 0.1, "moon shines at night")
	check(scene.stars_instance.visible, "stars are visible at night")
	scene.time_of_day = 0.5
	scene._update_day_night()
	check(not scene.stars_instance.visible, "stars hide during the day")

	# Bioma único com shader.
	var ground: Node = scene.get_node_or_null("BiomeGround")
	check(ground != null and ground is MeshInstance3D, "single biome ground exists")
	check(ground.material_override is ShaderMaterial, "biome ground uses the transition shader")

	# Lago intransponível.
	check(scene.lake_blocker != null and scene.lake_blocker is StaticBody3D, "lake has a solid blocker")
	check(scene.lake_collider != null and scene.lake_collider.shape is CylinderShape3D, "lake blocker is a cylinder")
	var lake_shape: CylinderShape3D = scene.lake_collider.shape
	check(lake_shape.radius >= 5.2 and lake_shape.height >= 3.0, "lake blocker covers the water and cannot be jumped over")
	check(absf(scene.lake_blocker.position.x - scene.lake_position.x) < 0.01 and absf(scene.lake_blocker.position.z - scene.lake_position.z) < 0.01, "lake blocker is centred on the lake")

	# Nave no chão: o casco exterior fica fechado e a entrada é automática.
	check(scene.ship_root != null and scene.ship_root.is_in_group("ship"), "ship exists on the ground")
	check(absf(scene.ship_root.position.y) < 0.01, "ship sits on the planet floor")
	check(scene.ship_body != null and scene.ship_body.get_child_count() >= 8, "ship has wall and floor colliders")
	check(scene.ship_root.get_node_or_null("Ramp") != null and scene.ship_root.get_node_or_null("Ramp/RampBody") != null, "ship has a walkable ramp")
	check(scene.ship_root.get_node_or_null("Airlock") != null, "ship keeps a closed airlock on the exterior")
	check(not scene._player_inside_ship(), "walking under the hull does not count as the interior")
	check(not scene._near_ship_entrance(), "player is far from the ship entrance")
	scene.player.global_position = scene.ship_position + Vector3(0, 1.05, 4.0)
	check(scene._near_ship_entrance(), "door area is detected at the top of the ramp")
	check(scene._near_ship_door(), "ship door hint appears near the entrance")
	check(not scene._near_ship_console(), "console only works inside the interior scene")
	scene.player.global_position = scene.ship_position + Vector3(6, 1.0, 12.0)
	check(not scene._near_ship_door(), "ship door hint disappears away from the ship")

	# Animais se movem, voltam para casa e não atravessam o lago.
	var animals: Array = []
	for item in scene.items_node.get_children():
		if item.tipo_item == "animal":
			animals.append(item)
	check(animals.size() == 5, "five creatures are spawned")
	var animal = animals[0]
	var animal_start: Vector3 = animal.global_position
	animal.wander_direction = Vector3(1, 0, 0)
	animal.wander_timer = 10.0
	animal._process(1.0)
	check(animal.global_position.x > animal_start.x + 0.1, "creature walks while the game runs")
	animal.global_position = animal.home_position + Vector3(animal.wander_radius + 2.0, 0, 0)
	animal.wander_direction = Vector3(1, 0, 0)
	animal.wander_timer = 10.0
	animal._process(0.5)
	var home_distance := Vector2(animal.global_position.x - animal.home_position.x, animal.global_position.z - animal.home_position.z).length()
	check(home_distance <= animal.wander_radius + 0.05, "creature stays near its home area")
	animal.global_position = Vector3(scene.lake_position.x - 6.4, animal.home_position.y, scene.lake_position.z)
	animal.wander_direction = Vector3(1, 0, 0)
	animal.wander_timer = 10.0
	for i in range(30):
		animal._process(0.1)
	var lake_distance := Vector2(animal.global_position.x - scene.lake_position.x, animal.global_position.z - scene.lake_position.z).length()
	check(lake_distance >= 6.5, "creature cannot enter the lake")
	animal.global_position = animal_start
	animal.wander_direction = Vector3.ZERO

	# Combate: criaturas revidam ou fogem, podem ferir e ser derrotadas.
	var beast: Node3D = null
	for creature in scene.items_node.get_children():
		if creature.tipo_item == "animal" and creature.available:
			beast = creature
			break
	check(beast != null, "a creature is available to fight")
	beast.temperament = "skittish"
	beast.health = beast.max_health
	beast.hit(10.0, scene.player)
	check(beast.health < beast.max_health, "attacks reduce creature health")
	check(beast.combat_state == "flee", "a skittish creature flees after being hit")
	beast.temperament = "aggressive"
	beast.health = beast.max_health
	beast.hit(10.0, scene.player)
	check(beast.combat_state == "chase", "an aggressive creature retaliates")
	beast.combat_state = "wander"
	beast.health = beast.max_health
	beast.hit(999.0, scene.player)
	check(not beast.available, "a defeated creature drops meat")
	beast._respawn()
	check(beast.available and is_equal_approx(beast.health, beast.max_health), "defeated creatures respawn with full health")

	scene.queue_free()
	await process_frame

	# --- Interior: a nave é um cenário separado ---
	manager.in_interior = true
	manager.pending_snapshot.clear()
	var inside = load("res://scenes/Gameplay.tscn").instantiate()
	root.add_child(inside)
	await process_frame
	inside.set_process(false)
	inside.player.set_physics_process(false)

	check(inside._is_interior(), "GameManager opens the ship interior scene")
	check(inside.interior_root != null and inside.interior_root.name == "ShipInterior", "interior room is built")
	check(not inside.get_node("Ground").visible, "planet ground is hidden inside the ship")
	check(inside.items_node.get_child_count() == 0, "the interior has no planet resources")
	check(inside.snake_root == null and inside.snakes.is_empty(), "no snakes spawn inside the ship")
	check(not inside._near_ship_entrance(), "the exterior entrance does not exist inside")
	check(inside._player_inside_ship(), "_player_inside_ship is true in the interior scene")
	check(inside.player.global_position.distance_to(inside.INTERIOR_SPAWN) < 0.1, "player spawns at the interior hatch")

	# Console no fundo da sala.
	inside.player.global_position = inside.console_position
	check(inside._near_ship_console(), "console interaction triggers when the player is close")
	manager.missions_complete = true
	inside._start_ending()
	check(inside.ending_started, "ending starts at the console after all missions")
	check(inside.ending_overlay.visible and inside.ending_panel.visible, "ending overlay and panel become visible")
	check(inside.ending_title.text == "DE VOLTA AO LAR", "ending title is translated")
	check(inside.ending_stats.text.contains("Missões: 16/16"), "ending shows completed missions")
	check(inside.ending_stats.text.contains("Nível"), "ending shows the player level")
	check(manager.achievements.has("Voltou para casa"), "ending unlocks the home achievement")
	check(inside.ending_stats.text.contains("Recursos"), "ending shows collected resources")
	check(inside.paused and not inside.player.is_physics_processing(), "ending pauses gameplay")
	inside._close_ending()
	check(not inside.ending_started and not inside.ending_panel.visible, "closing the ending hides the panel")
	check(not inside.paused and inside.player.is_physics_processing(), "closing the ending resumes gameplay")

	# ARIA e beliche dentro da sala.
	manager.missions_complete = false
	manager.current_mission_index = 0
	manager.current_mission_progress = 0
	inside._update_mission()
	check(inside.robot_root != null and inside.robot_root.name == "MissionRobot", "mission robot lives inside the ship")
	check(inside.bed_root != null and inside.bed_root.name == "BunkBed", "bunk bed lives inside the ship")
	check(inside.robot_root.position.distance_to(Vector3(-3.2, 0.10, -2.4)) < 0.02, "robot stands in the interior room")
	check(inside.bed_root.position.distance_to(Vector3(3.15, 0.10, 1.5)) < 0.01, "bunk bed stands in the interior room")
	inside.player.global_position = inside.robot_position
	check(inside._near_robot(), "player can reach the mission robot")
	check(inside._ship_station_nearby() == "robot", "robot is the nearest ship station")
	inside._talk_to_robot()
	check(inside.robot_panel.visible, "robot dialog opens")
	check(inside.paused and not inside.player.is_physics_processing(), "robot dialog pauses gameplay")
	check("Missão" in inside.robot_body_label.text, "robot shows the current mission")
	check(manager.achievements.has("Contato com ARIA"), "talking to ARIA unlocks an achievement")
	inside._close_robot_dialog()
	check(not inside.robot_panel.visible and not inside.paused, "closing the robot dialog resumes gameplay")

	inside.player.global_position = inside.bed_position
	check(inside._near_bed(), "player can reach the bunk bed")
	inside.time_of_day = 0.92
	var day_before_sleep: int = inside.day_count
	inside.health = 40.0
	inside._sleep_in_bed()
	check(inside.time_of_day > 0.2 and inside.time_of_day < 0.35, "sleeping wakes the player at dawn")
	check(inside.day_count == day_before_sleep + 1, "sleeping past midnight advances the day")
	check(inside.health > 40.0, "sleeping restores health")
	inside.time_of_day = 0.5
	var day_before_nap: int = inside.day_count
	inside._sleep_in_bed()
	check(inside.day_count == day_before_nap and is_equal_approx(inside.time_of_day, 0.5), "the bed cannot be used during the day")
	check(int(inside._snapshot().get("day", 0)) == inside.day_count, "day counter is stored in the save")

	# Nada de clima, sol ou estrelas dentro da nave.
	inside._update_day_night()
	check(not inside.sun.visible, "sunlight is disabled inside the ship")
	check(not is_instance_valid(inside.moon_light) or not inside.moon_light.visible, "moonlight is disabled inside the ship")
	check(not is_instance_valid(inside.stars_instance) or not inside.stars_instance.visible, "stars are disabled inside the ship")
	check(inside._is_interior() and (inside.rain_fx == null or not inside.rain_fx.emitting), "weather effects are disabled inside the ship")

	# Escotilha de saída.
	inside.player.global_position = inside.exit_hatch_position
	check(inside._near_exit_hatch(), "player can reach the exit hatch")
	check(inside._ship_station_nearby() == "hatch", "hatch is the nearest ship station")
	inside._update_hint()
	check("Sair da nave" in inside.get_node("CanvasLayer/HUD/HintLabel").text, "hint explains how to leave the ship")
	inside._exit_ship(false)
	check(not manager.in_interior and not inside._is_interior(), "leaving the hatch switches back to the planet")
	var exit_snapshot: Dictionary = manager.pending_snapshot
	check(bool(exit_snapshot.get("in_interior", true)) == false, "interior flag is saved as false on exit")
	var saved_exit: Array = exit_snapshot.get("position", [])
	check(saved_exit.size() == 3 and Vector3(saved_exit[0], saved_exit[1], saved_exit[2]).distance_to(inside.ship_position + Vector3(0, 1.05, 6.0)) < 0.01, "player leaves at the top of the ramp")
	check(manager.interior_snapshot.is_empty(), "interior snapshot is cleared after leaving")
	manager.pending_snapshot.clear()

	inside.queue_free()
	await process_frame
	print("CHECKS COMPLETE: %d failures" % failures.size())
	quit(0 if failures.is_empty() else 1)
