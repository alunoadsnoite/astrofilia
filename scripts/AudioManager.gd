extends Node

## AudioManager — Centralized sound playback.
## Usage:
##   GameManager or any node with access to the autoload calls
##   AudioManager.play("collect")  → plays a sound by name
##   AudioManager.set_sfx_volume(0.5)
##
## Sounds are simple WAV generators included as .wav files. Godot imports
## them as AudioStream resources automatically.
@export var sfx_volume: float = 1.0 set = set_sfx_volume
@export var music_volume: float = 1.0 set = set_music_volume

const SOUND_PATHS := {
	"collect": "res://audio/collect.wav",
	"drink": "res://audio/drink.wav",
	"jump": "res://audio/jump.wav",
	"pickup": "res://audio/pickup.wav",
	"menu_click": "res://audio/menu_click.wav",
	"gameover": "res://audio/gameover.wav",
	"success": "res://audio/success.wav",
}

var _loaded := {}  # name -> AudioStream

func _ready() -> void:
	# Preload all sound files so we don't load them at runtime
	for key in SOUND_PATHS:
		if FileAccess.file_exists(ProjectSettings.globalize_path(SOUND_PATHS[key])):
			_loaded[key] = load(SOUND_PATHS[key])
		else:
			_print("AudioManager: missing sound " + SOUND_PATHS[key])

func _set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)

func _set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)

## Play a sound effect by name. Silently ignores missing sounds.
func play(name: String, volume: float = 1.0) -> void:
	if not name in _loaded:
		return
	var stream := _loaded[name]
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = 20.0 * math.log(clipf(volume, 0.0, 1.0)) / math.log(10.0)
	player.max_bus_audio_level = 1.0
	player.play()
	add_child(player)
	# Auto-free after a short timeout so we don't leak nodes
	var t := Timer.new()
	t.wait_time = 0.5
	t.one_shot = true
	t.timeout.connect(func():
		if is_instance_valid(player):
			player.queue_free()
	)
	add_child(t)
	# Keep reference to timer so it's not GC'd
	set_instance_variable("_audio_timer", t)
