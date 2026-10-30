extends Node

## ItemSpawner — Spawns and positions the collectible items.
##
## Separation of concerns: item spawning logic moved out of Gameplay.gd
## to keep the main script focused on gameplay flow.
##
## Public API used by Gameplay:
##   spawn_items(items_node, lake_position, get_item_scene())

@export var item_scene_path: String = "res://scenes/Item.tscn"
@export var item_count: int = 30
@export var min_radius: float = 6.0
@export var max_radius: float = 26.0
@export var lake_avoid_radius: float = 6.5

func spawn_items(items_node: Node3D, lake_position: Vector3, get_item_scene := null) -> void:
	var item_scene := get_item_scene if get_item_scene != null else preload(item_scene_path)
	if item_scene == null:
		_print("ItemSpawner: cannot load scene at " + item_scene_path)
		return

	var types := ["mineral", "fruit", "plant", "crystal", "stone", "animal"]
	for i in range(item_count):
		var it := item_scene.instantiate()
		var angle := i * TAU / item_count
		var radius := min_radius + (i % 5) * 4.0
		var pos := Vector3(cos(angle) * radius, 1.0, sin(angle) * radius)

		# Avoid placing items inside the lake
		if lake_position != Vector3.ZERO:
			var to_lake := Vector2(pos.x - lake_position.x, pos.z - lake_position.z)
			if to_lake.length() < lake_avoid_radius:
				pos.z -= 14.0
				pos.x += 2.0

		it.position = pos
		var idx := i % types.size()
		it.tipo_item = types[idx]
		# Hook the collected signal
		if it.has_method("collected") or it.has_signal("collected"):
			it.collected.connect(_on_item_collected)
		items_node.add_child(it)

func _on_item_collected(type: String) -> void:
	# Override in derived classes if needed
	pass
