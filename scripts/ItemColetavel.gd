extends Area3D

signal collected(type: String)

# Tipo do item coletável
@export var tipo_item: String = "mineral"
@export var quantidade: int = 1
@export var mensagem_coleta: String = "Coletado!"

# Referência visual
@onready var mesh = get_node_or_null("MeshInstance3D")
@onready var label = get_node_or_null("Label3D")

func _ready() -> void:
	if label:
		label.text = mensagem_coleta
		label.visible = false
	body_entered.connect(_on_body_entered)

func _on_body_entered(body) -> void:
	if body.has_method("coletar_item"):
		body.coletar_item(tipo_item, quantidade)
	if body.has_method("add_score"):
		body.add_score(10)
	collected.emit(tipo_item)
	if label:
		label.visible = true
		await get_tree().create_timer(1.0).timeout
	queue_free()

func _process(delta: float) -> void:
	if mesh:
		mesh.rotation.y += 1.0 * delta
