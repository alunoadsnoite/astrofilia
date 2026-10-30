extends CharacterBody3D

const SPEED := 6.0
const JUMP_VELOCITY := 5.0
const GRAVITY := 9.8

var score: int = 0
var suit_color: Color = Color("edf1e8")

func _ready() -> void:
	add_to_group("player")
	suit_color = {"default": Color("edf1e8"), "blue": Color("438bd1"), "red": Color("d86b62"), "green": Color("64b38c")}.get(GameManager.appearance, Color("edf1e8"))
	_build_model()

func _build_model() -> void:
	# Esconder mesh padrão
	var default_mesh := get_node_or_null("Mesh")
	if default_mesh:
		default_mesh.visible = false

	# Corpo (cilindro)
	var body := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 0.35
	bm.bottom_radius = 0.4
	bm.height = 0.9
	body.mesh = bm
	body.position = Vector3(0, 0.45, 0)
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = suit_color
	body_mat.roughness = 0.4
	body.material_override = body_mat
	body.name = "SuitBody"
	add_child(body)

	# Cabeça
	var head := MeshInstance3D.new()
	var hm := SphereMesh.new()
	hm.radius = 0.3
	hm.height = 0.6
	head.mesh = hm
	head.position = Vector3(0, 1.1, 0)
	var head_mat := StandardMaterial3D.new()
	head_mat.albedo_color = Color("f3a450")
	head.material_override = head_mat
	add_child(head)

	# Visor
	var visor := MeshInstance3D.new()
	var vm := BoxMesh.new()
	vm.size = Vector3(0.45, 0.18, 0.12)
	visor.mesh = vm
	visor.position = Vector3(0, 1.1, 0.22)
	var visor_mat := StandardMaterial3D.new()
	visor_mat.albedo_color = Color(0.1, 0.5, 0.9)
	visor_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	visor_mat.albedo_color.a = 0.7
	visor_mat.emission_enabled = true
	visor_mat.emission = Color(0.2, 0.6, 1.0)
	visor_mat.emission_energy_multiplier = 0.6
	visor.material_override = visor_mat
	add_child(visor)

	# Braço direito
	var arm_r := MeshInstance3D.new()
	var arm := CylinderMesh.new()
	arm.top_radius = 0.1
	arm.bottom_radius = 0.1
	arm.height = 0.7
	arm_r.mesh = arm
	arm_r.position = Vector3(0.45, 0.75, 0)
	arm_r.rotation_degrees = Vector3(0, 0, -30)
	var arm_mat := StandardMaterial3D.new()
	arm_mat.albedo_color = suit_color
	arm_r.material_override = arm_mat
	add_child(arm_r)

	# Mão direita
	var hand_r := MeshInstance3D.new()
	var hand := SphereMesh.new()
	hand.radius = 0.12
	hand.height = 0.24
	hand_r.mesh = hand
	hand_r.position = Vector3(0.7, 0.5, 0)
	var hand_mat := StandardMaterial3D.new()
	hand_mat.albedo_color = Color("f3a450")
	hand_r.material_override = hand_mat
	add_child(hand_r)

	# Facão na mão direita
	var blade := MeshInstance3D.new()
	var bl := BoxMesh.new()
	bl.size = Vector3(0.05, 0.5, 0.12)
	blade.mesh = bl
	blade.position = Vector3(0.7, 0.75, 0.08)
	blade.rotation_degrees = Vector3(0, 0, -20)
	var blade_mat := StandardMaterial3D.new()
	blade_mat.albedo_color = Color(0.75, 0.75, 0.8)
	blade_mat.metallic = 0.8
	blade_mat.roughness = 0.2
	blade.material_override = blade_mat
	add_child(blade)

	# Braço esquerdo
	var arm_l := MeshInstance3D.new()
	arm_l.mesh = arm
	arm_l.position = Vector3(-0.45, 0.75, 0)
	arm_l.rotation_degrees = Vector3(0, 0, 30)
	arm_l.material_override = arm_mat
	add_child(arm_l)

	# Mão esquerda
	var hand_l := MeshInstance3D.new()
	hand_l.mesh = hand
	hand_l.position = Vector3(-0.7, 0.5, 0)
	hand_l.material_override = hand_mat
	add_child(hand_l)

	# Picareta na mão esquerda
	var pick_handle := MeshInstance3D.new()
	var ph := CylinderMesh.new()
	ph.top_radius = 0.04
	ph.bottom_radius = 0.04
	ph.height = 0.7
	pick_handle.mesh = ph
	pick_handle.position = Vector3(-0.7, 0.75, 0)
	pick_handle.rotation_degrees = Vector3(0, 0, 20)
	var pick_mat := StandardMaterial3D.new()
	pick_mat.albedo_color = Color(0.5, 0.3, 0.15)
	pick_handle.material_override = pick_mat
	add_child(pick_handle)

	var pick_head := MeshInstance3D.new()
	var pk := BoxMesh.new()
	pk.size = Vector3(0.35, 0.1, 0.1)
	pick_head.mesh = pk
	pick_head.position = Vector3(-0.85, 1.05, 0)
	pick_head.rotation_degrees = Vector3(0, 0, 20)
	var pick_head_mat := StandardMaterial3D.new()
	pick_head_mat.albedo_color = Color(0.6, 0.6, 0.65)
	pick_head_mat.metallic = 0.9
	pick_head.material_override = pick_head_mat
	add_child(pick_head)

	# Câmera no peito (biólogo)
	var cam_body := MeshInstance3D.new()
	var cb := BoxMesh.new()
	cb.size = Vector3(0.25, 0.18, 0.12)
	cam_body.mesh = cb
	cam_body.position = Vector3(0.15, 0.55, 0.35)
	var cam_mat := StandardMaterial3D.new()
	cam_mat.albedo_color = Color(0.15, 0.15, 0.2)
	cam_mat.metallic = 0.5
	cam_body.material_override = cam_mat
	add_child(cam_body)

	var cam_lens := MeshInstance3D.new()
	var cl := CylinderMesh.new()
	cl.top_radius = 0.05
	cl.bottom_radius = 0.05
	cl.height = 0.08
	cam_lens.mesh = cl
	cam_lens.position = Vector3(0.15, 0.55, 0.42)
	cam_lens.rotation_degrees = Vector3(90, 0, 0)
	var lens_mat := StandardMaterial3D.new()
	lens_mat.albedo_color = Color(0.1, 0.4, 0.8)
	lens_mat.emission_enabled = true
	lens_mat.emission = Color(0.2, 0.5, 1.0)
	lens_mat.emission_energy_multiplier = 0.8
	cam_lens.material_override = lens_mat
	add_child(cam_lens)

	# Pernas
	var leg_mesh := CylinderMesh.new()
	leg_mesh.top_radius = 0.12
	leg_mesh.bottom_radius = 0.1
	leg_mesh.height = 0.6
	for x in [-0.15, 0.15]:
		var leg := MeshInstance3D.new()
		leg.mesh = leg_mesh
		leg.position = Vector3(x, -0.1, 0)
		var leg_mat := StandardMaterial3D.new()
		leg_mat.albedo_color = Color("314a60")
		leg.material_override = leg_mat
		add_child(leg)

	# Colisão (capsule) já existe no Player.tscn

var external_move: Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if external_move.length() > 0.1:
		input_dir = external_move
	var dir := Vector3(input_dir.x, 0, input_dir.y).normalized()
	if dir.length() > 0:
		velocity.x = dir.x * SPEED
		velocity.z = dir.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func add_score(points: int) -> void:
	score += points
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("set_score"):
		hud.set_score(score)

func coletar_item(tipo: String, quantidade: int = 1) -> void:
	# A coleta é registrada pelo Gameplay via sinal; aqui apenas mantemos
	# compatibilidade com itens que chamam diretamente o jogador.
	pass
