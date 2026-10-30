extends Node

## WeatherController — Random weather changes with visual feedback.
##
## Currently supports: clear, rain, sandstorm, snow.
## Uses CPUParticles3D for visual effects.
##
## Gameplay calls:
##   WeatherController.change()
##   WeatherController.get() → returns the current weather string

var _weather: String = "clear"
var _weather_timer: float = 0.0
@export var change_interval_min: float = 15.0
@export var change_interval_max: float = 30.0
@export var clear_chance: float = 0.4
@export var rain_chance: float = 0.25
@export var sandstorm_chance: float = 0.17
@export var snow_chance: float = 0.18
@export var weather_scene_path: String = "res://scenes/WeatherWrapper.tscn"

var _current_particles: Node3D = null

func get() -> String:
	return _weather

func change(world_root: Node3D) -> void:
	_weather_timer = randf_range(change_interval_min, change_interval_max)
	var r := randf()
	if r < clear_chance:
		_weather = "clear"
		_remove_particles(world_root)
	elif r < clear_chance + rain_chance:
		_weather = "rain"
		_spawn_particles(world_root, "rain")
	elif r < clear_chance + rain_chance + sandstorm_chance:
		_weather = "sandstorm"
		_spawn_particles(world_root, "sandstorm")
	else:
		_weather = "snow"
		_spawn_particles(world_root, "snow")

func _remove_particles(world_root: Node3D) -> void:
	if _current_particles:
		world_root.remove_child(_current_particles)
		_current_particles.queue_free()
		_current_particles = null

func _spawn_particles(world_root: Node3D, kind: String) -> void:
	_remove_particles(world_root)

	var scene := ResourceLoader.load_unknown_texture("res://scenes/WeatherParticles.tscn") if false else null
	# Create particles directly to avoid dependency on scene files
	var particles := CPUParticles3D.new()
	particles.amount = 200
	particles.lifetime = 6.0
	particles.preprocess = 3.0
	particles.gravity = Vector3(0, -0.5, 0)
	particles.initial_velocity_min = 0.5
	particles.initial_velocity_max = 1.5
	particles.scale_amount_min = 0.05
	particles.scale_amount_max = 0.15

	match kind:
		"rain":
			particles.emission_shape = 2  # box
			particles.color = Color(0.6, 0.8, 1.0, 0.6)
			particles.emission_box_extents = Vector3(40, 10, 40)
			particles.energy = 0.5
			particles.energy_scale = 0.5
		"sandstorm":
			particles.emission_shape = 2
			particles.color = Color(0.8, 0.75, 0.7, 0.5)
			particles.gravity = Vector3(0, -0.3, 0)
			particles.initial_velocity_min = 0.0
			particles.initial_velocity_max = 2.0
			particles.energy = 0.7
			particles.energy_scale = 0.7
		"snow":
			particles.emission_shape = 2
			particles.color = Color(1.0, 1.0, 1.0, 0.8)
			particles.gravity = Vector3(0, -0.2, 0)
			particles.initial_velocity_min = 0.0
			particles.initial_velocity_max = 0.5
			particles.energy = 0.4
			particles.energy_scale = 0.4
		_:
			return

	world_root.add_child(particles)
	_current_particles = particles
