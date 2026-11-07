extends Node

# Gerenciador de rede do Astrofilia: multiplayer online por IP usando ENet.
#
# Topologia em estrela: o host (id 1) é a autoridade da sessão. Todos os RPCs
# vivem neste autoload, então o caminho dos nós é idêntico em todos os pares.
# O host recebe o estado dos clientes, aplica localmente e retransmite para os
# demais; clientes nunca falam diretamente entre si.

signal join_ok()
signal join_failed(reason: String)
signal session_ended(reason: String)
signal peer_joined(id: int, info: Dictionary)
signal peer_left(id: int)
# Estado de um jogador: posição, rotação, local (0 = planeta, 1 = interior)
# e velocidade no plano. Emitido para jogadores remotos.
signal remote_state(id: int, pos: Vector3, rot_y: float, loc: int, speed: float)
# Disponibilidade de um recurso do mundo (coletado/renascido).
signal item_state(index: int, available: bool, cooldown: float)
# Estado autoritativo das cobras, enviado pelo host.
signal snake_state(states: Array)
# Pedido de dano em cobra (host aplica).
signal snake_hit_requested(index: int, damage: float, attacker_id: int)
signal snake_killed(index: int, attacker_id: int)

const DEFAULT_PORT := 7911
const MAX_PLAYERS := 4

var in_session := false
var is_host := false
var connecting := false
var world_seed := 1
var peers: Dictionary = {}
var local_name := "Astronauta"
var local_role := "collector"
var local_appearance := "default"
var local_port := DEFAULT_PORT

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func local_id() -> int:
	if not in_session:
		return 1
	return multiplayer.get_unique_id()

func player_count() -> int:
	return peers.size()

func address_hint() -> String:
	# Endereço que o host deve compartilhar com os convidados.
	if not is_host:
		return ""
	var best := ""
	for addr in IP.get_local_addresses():
		var text := String(addr)
		if text.contains(":") or text.begins_with("127.") or text.begins_with("169.254."):
			continue
		if text.begins_with("192.168."):
			return "%s:%d" % [text, local_port]
		if best == "":
			best = text
		elif text.begins_with("10.") and not best.begins_with("10."):
			best = text
	if best == "":
		best = "127.0.0.1"
	return "%s:%d" % [best, local_port]

# --- Criar/entrar/limpar ---
func host(port: int, seed_value: int, p_name: String, p_role: String, p_appearance: String) -> Error:
	leave()
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_PLAYERS - 1)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	in_session = true
	is_host = true
	connecting = false
	world_seed = seed_value
	local_port = port
	local_name = p_name.left(24)
	local_role = p_role
	local_appearance = p_appearance
	peers.clear()
	peers[1] = {"name": local_name, "role": local_role, "appearance": local_appearance}
	return OK

func join(ip: String, port: int, p_name: String, p_role: String, p_appearance: String) -> Error:
	leave()
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(ip, port)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	connecting = true
	in_session = false
	is_host = false
	local_port = port
	local_name = p_name.left(24)
	local_role = p_role
	local_appearance = p_appearance
	peers.clear()
	return OK

func leave() -> void:
	# Marca a saída antes de fechar para que server_disconnected seja ignorado.
	in_session = false
	is_host = false
	connecting = false
	peers.clear()
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null

func cancel_connect() -> void:
	leave()

# --- Registro de jogadores ---
@rpc("any_peer", "call_remote", "reliable")
func register_player(p_name: String, p_role: String, p_appearance: String) -> void:
	if not multiplayer.is_server():
		return
	var id := multiplayer.get_remote_sender_id()
	if id <= 1:
		return
	var info := {
		"name": String(p_name).left(24),
		"role": String(p_role),
		"appearance": String(p_appearance),
	}
	peers[id] = info
	_welcome.rpc_id(id, world_seed, peers, id)
	_notify_peer_joined.rpc(id, info)
	peer_joined.emit(id, info)

@rpc("authority", "call_remote", "reliable")
func _welcome(seed_value: int, peer_list: Dictionary, assigned_id: int) -> void:
	world_seed = seed_value
	peers = peer_list.duplicate(true)
	in_session = true
	is_host = false
	connecting = false
	join_ok.emit()

@rpc("authority", "call_remote", "reliable")
func _notify_peer_joined(id: int, info: Dictionary) -> void:
	peers[id] = info
	peer_joined.emit(id, info)

@rpc("authority", "call_remote", "reliable")
func _notify_peer_left(id: int) -> void:
	peers.erase(id)
	peer_left.emit(id)

func _on_peer_connected(_id: int) -> void:
	# O servidor espera o register_player do cliente.
	pass

func _on_peer_disconnected(id: int) -> void:
	if not in_session:
		return
	if peers.has(id):
		peers.erase(id)
		peer_left.emit(id)
	if is_host:
		_notify_peer_left.rpc(id)

func _on_connected_to_server() -> void:
	register_player.rpc_id(1, local_name, local_role, local_appearance)

func _on_connection_failed() -> void:
	var was_connecting := connecting
	in_session = false
	connecting = false
	multiplayer.multiplayer_peer = null
	peers.clear()
	if was_connecting:
		join_failed.emit("Não foi possível conectar. Confira o IP, a porta e se o host está com a sala aberta.")

func _on_server_disconnected() -> void:
	if not in_session and not connecting:
		return
	var was_inside := in_session
	var was_connecting := connecting
	in_session = false
	connecting = false
	peers.clear()
	multiplayer.multiplayer_peer = null
	if was_inside:
		session_ended.emit("O host encerrou a sessão.")
	elif was_connecting:
		join_failed.emit("A conexão foi encerrada antes de entrar na sala.")

# --- Estado dos jogadores ---
func send_state(pos: Vector3, rot_y: float, loc: int, speed: float) -> void:
	if not in_session:
		return
	if multiplayer.is_server():
		_broadcast_state(1, pos, rot_y, loc, speed)
	else:
		_upstream_state.rpc_id(1, pos, rot_y, loc, speed)

func _broadcast_state(sender_id: int, pos: Vector3, rot_y: float, loc: int, speed: float) -> void:
	for pid in peers.keys():
		var target := int(pid)
		if target == 1 or target == sender_id:
			continue
		_downstream_state.rpc_id(target, sender_id, pos, rot_y, loc, speed)

@rpc("any_peer", "call_remote", "unreliable")
func _upstream_state(pos: Vector3, rot_y: float, loc: int, speed: float) -> void:
	if not multiplayer.is_server():
		return
	var id := multiplayer.get_remote_sender_id()
	remote_state.emit(id, pos, rot_y, loc, speed)
	_broadcast_state(id, pos, rot_y, loc, speed)

@rpc("authority", "call_remote", "unreliable")
func _downstream_state(sender_id: int, pos: Vector3, rot_y: float, loc: int, speed: float) -> void:
	remote_state.emit(sender_id, pos, rot_y, loc, speed)

# --- Recursos do mundo ---
func broadcast_item(index: int, available: bool, cooldown: float) -> void:
	if not in_session:
		return
	if multiplayer.is_server():
		item_state.emit(index, available, cooldown)
		_item_down.rpc(index, available, cooldown)
	else:
		_item_up.rpc_id(1, index, available, cooldown)

@rpc("any_peer", "call_remote", "reliable")
func _item_up(index: int, available: bool, cooldown: float) -> void:
	if not multiplayer.is_server():
		return
	item_state.emit(index, available, cooldown)
	_item_down.rpc(index, available, cooldown)

@rpc("authority", "call_remote", "reliable")
func _item_down(index: int, available: bool, cooldown: float) -> void:
	item_state.emit(index, available, cooldown)

# --- Cobras (host autoritativo) ---
func broadcast_snakes(states: Array) -> void:
	if not in_session or not multiplayer.is_server():
		return
	snake_state.emit(states)
	_snake_down.rpc(states)

@rpc("authority", "call_remote", "unreliable")
func _snake_down(states: Array) -> void:
	snake_state.emit(states)

func request_snake_hit(index: int, damage: float) -> void:
	if not in_session:
		return
	if multiplayer.is_server():
		snake_hit_requested.emit(index, damage, multiplayer.get_unique_id())
	else:
		_snake_hit_up.rpc_id(1, index, damage)

@rpc("any_peer", "call_remote", "reliable")
func _snake_hit_up(index: int, damage: float) -> void:
	if not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	snake_hit_requested.emit(index, damage, sender)

func notify_snake_killed(index: int, attacker_id: int) -> void:
	if not in_session or not multiplayer.is_server():
		return
	_snake_killed.rpc(index, attacker_id)

@rpc("authority", "call_remote", "reliable")
func _snake_killed(index: int, attacker_id: int) -> void:
	snake_killed.emit(index, attacker_id)
