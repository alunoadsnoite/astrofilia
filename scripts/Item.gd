extends Area3D

signal collected(type: String)

@export var points: int = 10
@export var item_type: String = "mineral"  # mineral, fruit, plant, crystal, stone

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		if body.has_method("add_score"):
			body.add_score(points)
		collected.emit(item_type)
		queue_free()
