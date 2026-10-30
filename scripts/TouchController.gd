extends Node

## TouchController — Manages virtual joystick / touch buttons.
##
## Handles:
##   - Independent finger tracking for movement and actions
##   - Converting finger states to player movement
##   - Controlled by Gameplay; connected to buttons via signals
##
## State exposed to Gameplay:
##   touch_dir (Vector2), touch_left/right/up/down (bools)

@onready var touch_controls: Control = null
@onready var left_button: Button = null
@onready var right_button: Button = null
@onready var up_button: Button = null
@onready var down_button: Button = null
@onready var jump_button: Button = null
@onready var interact_button: Button = null

var touch_left := false
var touch_right := false
var touch_up := false
var touch_down := false
var touch_dir: Vector2 = Vector2.ZERO
var touch_fingers: Dictionary = {}
var _paused := false
var _game_over := false

func setup(root: Node3D) -> void:
	var tc := root.get_node_or_null("CanvasLayer/TouchControls")
	if tc == null:
		_print("TouchController: TouchControls node not found")
		return
	touch_controls = tc
	left_button = touch_controls.get_node_or_null("DPad/LeftButton")
	right_button = touch_controls.get_node_or_null("DPad/RightButton")
	up_button = touch_controls.get_node_or_null("DPad/UpButton")
	down_button = touch_controls.get_node_or_null("DPad/DownButton")
	jump_button = touch_controls.get_node_or_null("JumpButton")
	interact_button = touch_controls.get_node_or_null("InteractButton")
	if not all([left_button, right_button, up_button, down_button, jump_button, interact_button]):
		_print("TouchController: some buttons not found")
		return

	for btn in [left_button, right_button, up_button, down_button, jump_button, interact_button]:
		btn.mouse_filter = Control.MOUSE_FILTER_IGNORE

	left_button.button_down.connect(_on_left_down)
	left_button.button_up.connect(_on_left_up)
	right_button.button_down.connect(_on_right_down)
	right_button.button_up.connect(_on_right_up)
	up_button.button_down.connect(_on_up_down)
	up_button.button_up.connect(_on_up_up)
	down_button.button_down.connect(_on_down_down)
	down_button.button_up.connect(_on_down_up)
	jump_button.pressed.connect(_on_jump_pressed)
	interact_button.pressed.connect(_on_interact_pressed)

	get_tree().connect("node_removed", self, "_on_node_removed")

func _on_node_removed(node: Node) -> void:
	if node == touch_controls:
		_clear()

func _on_left_down() -> void:
	touch_left = true
	_refresh_dir()

func _on_left_up() -> void:
	touch_left = false
	_refresh_dir()

func _on_right_down() -> void:
	touch_right = true
	_refresh_dir()

func _on_right_up() -> void:
	touch_right = false
	_refresh_dir()

func _on_up_down() -> void:
	touch_up = true
	_refresh_dir()

func _on_up_up() -> void:
	touch_up = false
	_refresh_dir()

func _on_down_down() -> void:
	touch_down = true
	_refresh_dir()

func _on_down_up() -> void:
	touch_down = false
	_refresh_dir()

func _on_jump_pressed() -> void:
	if not _paused and not _game_over:
		_jump()

func _on_interact_pressed() -> void:
	if not _paused and not _game_over:
		_interact()

func _clear() -> void:
	touch_fingers.clear()
	touch_left = false
	touch_right = false
	touch_up = false
	touch_down = false
	_refresh_dir()
	if is_instance_valid(player):
		player.external_move = Vector2.ZERO

func _refresh_dir() -> void:
	var x := (1.0 if touch_right else 0.0) - (1.0 if touch_left else 0.0)
	var y := (1.0 if touch_down else 0.0) - (1.0 if touch_up else 0.0)
	touch_dir = Vector2(x, y)

## External call from Gameplay to update player input
func update_player_move(player_node: CharacterBody3D, speed: float) -> void:
	if _paused or _game_over:
		return
	if player_node and player_node.is_connected("physics_process", self, "_update_move"):
		# Process directly
		_update_move(player_node, delta)
	else:
		# Called each physics frame
		pass

var _delta_cache: float = 0.0

func _update_move(player_node: CharacterBody3D, delta: float) -> void:
	if not player_node.is_on_floor():
		return
	var dir := Vector3(touch_dir.x, 0, touch_dir.y).normalized()
	if dir.length() > 0:
		player_node.velocity.x = dir.x * speed
		player_node.velocity.z = dir.z * speed
	else:
		player_node.velocity.x = move_toward(player_node.velocity.x, 0, speed)
		player_node.velocity.z = move_toward(player_node.velocity.z, 0, speed)
	player_node.move_and_slide()

## Called by Gameplay when paused changes
func set_paused(paused: bool) -> void:
	_paused = paused
	if paused:
		_clear()

func set_game_over(game_over: bool) -> void:
	_game_over = game_over

func _jump() -> void:
	# Called by button; overridden by Gameplay for specific height
	pass

func _interact() -> void:
	# Called by button; overridden by Gameplay for specific logic
	pass
