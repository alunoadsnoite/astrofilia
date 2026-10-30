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
	check(scene.mission_label.text == "Volte para casa!", "final mission message survives save/load")
	manager.missions_complete = false

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

	print("CHECKS COMPLETE: %d failures" % failures.size())
	quit()
