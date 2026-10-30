extends Node

## BiomeFactory — Procedural generation of the three biomes.
##
## Handles:
##   - Base patches (desert, forest, snow)
##   - Scenery patches (variation)
##   - Trees, rocks, ice, flowers
##   - Biome name labels
##
## Gameplay calls:
##   BiomeFactory.create(biomes_data, world_root, scenery_rng, lake_position)

@export var biome_scene_path: String = "res://scenes/Item.tscn"

func create(biomes: Array, world_root: Node3D, scenery_rng: RandomNumberGenerator, lake_position: Vector3) -> void:
	for b in biomes:
		var center := b.center
		var size := b.size
		var color := b.color
		var label_color := b.label_color
		var prop := b.prop

		# Base patch
		_biome_patch(center, size, color, world_root, 0.02, 0.95)

		# Variation patches
		for k in range(4):
			var dsize := Vector2(
				scenery_rng.randf_range(4.0, 8.0),
				scenery_rng.randf_range(4.0, 8.0)
			)
			var dpos := Vector3(
				center.x + scenery_rng.randf_range(-size.x * 0.5 + dsize.x * 0.5, size.x * 0.5 - dsize.x * 0.5),
				0.0,
				center.z + scenery_rng.randf_range(-size.y * 0.5 + dsize.y * 0.5, size.y * 0.5 - dsize.y * 0.5)
			)
			_biome_patch(dpos, dsize, color.darkened(scenery_rng.randf_range(0.04, 0.14)), world_root, 0.03, 0.95)

		# Enlaces
		match prop:
			"rock":
				_spawn_rocks(center, size, scenery_rng, world_root)
			"tree":
				_spawn_trees(center, size, scenery_rng, world_root, lake_position)
			"snow":
				_spawn_ice(center, size, scenery_rng, world_root)

		# Biome label
		var label := Label3D.new()
		label.text = b.name
		label.position = center + Vector3(0, 3.2, 0)
		label.font_size = 56
		label.outline_size = 10
		label.modulate = label_color
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		world_root.add_child(label)

func _biome_patch(center: Vector3, size: Vector2, color: Color, world_root: Node3D, y: float, roughness: float) -> void:
	var patch := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = size
	pm.subdivide_width = 2
	pm.subdivide_depth = 2
	patch.mesh = pm
	patch.position = Vector3(center.x, y, center.z)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	patch.material_override = mat
	world_root.add_child(patch)
