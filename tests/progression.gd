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
	manager.missions_complete = false

	# Desfecho: só ativa com todas as missões concluídas e no console da nave.
	var ending_return_pos: Vector3 = scene.player.global_position
	var console_pos: Vector3 = scene.ship_position + Vector3(0, 1.2, -3.85)
	scene.player.global_position = console_pos
	manager.missions_complete = false
	scene._start_ending()
	check(not scene.ending_started, "ending does not start before all missions are complete")
	check(not scene.ending_overlay.visible and not scene.ending_panel.visible, "ending panel stays hidden before completion")
	manager.missions_complete = true
	check(scene._player_inside_ship(), "player can reach the ship console")
	check(scene._near_ship_console(), "console interaction triggers when the player is close")
	scene._start_ending()
	check(scene.ending_started, "ending starts at the console after all missions")
	check(scene.ending_overlay.visible and scene.ending_panel.visible, "ending overlay and panel become visible")
	check(scene.ending_title.text == "DE VOLTA AO LAR", "ending title is translated")
	check(scene.ending_stats.text.contains("Missões: 16/16"), "ending shows completed missions")
	check(scene.ending_stats.text.contains("Nível"), "ending shows the player level")
	check(manager.achievements.has("Voltou para casa"), "ending unlocks the home achievement")
	check(scene.ending_stats.text.contains("Recursos"), "ending shows collected resources")
	check(scene.paused and not scene.player.is_physics_processing(), "ending pauses gameplay")
	scene._close_ending()
	check(not scene.ending_started and not scene.ending_panel.visible, "closing the ending hides the panel")
	check(not scene.paused and scene.player.is_physics_processing(), "closing the ending resumes gameplay")
	scene.player.global_position = scene.ship_position + Vector3(0, 1.4, 0)
	scene._update_hint()
	check("console" in scene.get_node("CanvasLayer/HUD/HintLabel").text.to_lower(), "hint points to the console after completion")
	manager.missions_complete = false
	scene.player.global_position = ending_return_pos

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
	scene.player.global_position = ending_return_pos

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

	# Nave no chão, com porta, rampa, interior e teto que some para a câmera.
	check(scene.ship_root != null and scene.ship_root.is_in_group("ship"), "ship exists on the ground")
	check(absf(scene.ship_root.position.y) < 0.01, "ship sits on the planet floor")
	check(scene.ship_body != null and scene.ship_body.get_child_count() >= 8, "ship has wall and floor colliders")
	check(scene.ship_root.get_node_or_null("Ramp") != null and scene.ship_root.get_node_or_null("Ramp/RampBody") != null, "ship has a walkable ramp")
	check(scene.ship_roof != null and scene.ship_roof.name == "ShipRoof", "ship roof is a separate node")
	check(not scene._player_inside_ship(), "player starts outside the ship")
	var old_player_pos: Vector3 = scene.player.global_position
	scene.player.global_position = scene.ship_position + Vector3(0, 1.4, 0)
	check(scene._player_inside_ship(), "player can stand inside the ship")
	scene._update_ship_interior(0.4)
	scene._update_ship_interior(0.4)
	check(scene.ship_roof.transparency > 0.4, "ship roof fades out while the player is inside")
	scene._update_hint()
	check("Interior da nave" in scene.get_node("CanvasLayer/HUD/HintLabel").text, "hint explains the empty ship interior")
	scene.player.global_position = scene.ship_position + Vector3(0, 1.0, 12.0)
	for i in range(8):
		scene._update_ship_interior(0.4)
	check(scene.ship_roof.transparency < 0.2, "ship roof becomes solid again after leaving")
	check(scene._near_ship_door() == false, "ship door hint only appears near the entrance")
	scene.player.global_position = old_player_pos

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
	# Devolve a criatura ao ponto inicial para não afetar outros testes.
	animal.global_position = animal_start
	animal.wander_direction = Vector3.ZERO

	print("CHECKS COMPLETE: %d failures" % failures.size())
	quit()
