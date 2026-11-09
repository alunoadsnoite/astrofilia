extends SceneTree

# Host mínimo para validar o botão "Procurar salas no Wi-Fi" do menu.

const PORT := 7933
const SEED := 555777

var net: Node

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	net = root.get_node("Net")
	var err: Error = net.host(PORT, SEED, "Host", "collector", "default")
	if err != OK:
		print("FAIL host não abriu a sala")
		quit(1)
		return
	print("PASS host abriu a sala para descoberta")

	var deadline := Time.get_ticks_msec() + 15000
	while net.player_count() < 2 and Time.get_ticks_msec() < deadline:
		await create_timer(0.1).timeout
	if net.player_count() < 2:
		print("FAIL cliente não entrou")
		quit(1)
		return
	print("PASS cliente entrou pela descoberta")

	deadline = Time.get_ticks_msec() + 15000
	while net.player_count() >= 2 and Time.get_ticks_msec() < deadline:
		await create_timer(0.1).timeout
	print("SIMPLE HOST COMPLETE")
	quit(0)
