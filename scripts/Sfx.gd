extends Node

## Sfx — reprodução centralizada dos efeitos sonoros e da trilha ambiente.
## Os volumes do menu (Efeitos sonoros / Música) controlam a intensidade.

const SOUNDS := {
	"click": preload("res://assets/audio/click.wav"),
	"collect": preload("res://assets/audio/collect.wav"),
	"drink": preload("res://assets/audio/drink.wav"),
	"mission": preload("res://assets/audio/mission.wav"),
	"level": preload("res://assets/audio/levelup.wav"),
	"chapter": preload("res://assets/audio/chapter.wav"),
}

const VOICES := 5

var _players: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer
var _next: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(VOICES):
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_players.append(player)
	_start_music()

func _start_music() -> void:
	var base := preload("res://assets/audio/ambient.wav")
	if not (base is AudioStreamWAV):
		return
	var stream: AudioStreamWAV = (base as AudioStreamWAV).duplicate()
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = int(stream.get_length() * stream.mix_rate)
	_music = AudioStreamPlayer.new()
	_music.bus = "Master"
	_music.stream = stream
	_music.volume_db = -80.0
	add_child(_music)
	_music.play()

func _process(_delta: float) -> void:
	if _music == null:
		return
	var target := -80.0
	var manager := get_node_or_null("/root/GameManager")
	if manager != null and float(manager.music_volume) > 0.001:
		target = linear_to_db(float(manager.music_volume)) - 8.0
	_music.volume_db = lerpf(_music.volume_db, target, 0.08)

func play(sound: String) -> void:
	if _players.is_empty():
		return
	var stream: AudioStream = SOUNDS.get(sound)
	if stream == null:
		return
	var volume := 1.0
	var manager := get_node_or_null("/root/GameManager")
	if manager != null:
		volume = clampf(float(manager.sfx_volume), 0.0, 1.0)
	if volume <= 0.001:
		return
	var player := _players[_next]
	_next = (_next + 1) % _players.size()
	player.stream = stream
	player.volume_db = linear_to_db(volume)
	player.play()
