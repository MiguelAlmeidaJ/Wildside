extends StaticBody2D

@export var device_price := 100
@export var pistol_price := 150
@export var ammo_pack_price := 40
@export var ammo_pack_size := 16


func _ready() -> void:
	add_to_group("interactable")


func get_interaction_priority(_player: CharacterBody2D) -> int:
	return 95


func get_interaction_text(_player: CharacterBody2D) -> String:
	if MissionManager.stage == MissionManager.Stage.BUY_DEVICE:
		return "Comprar Dispositivo Wild  $%d" % device_price
	if MissionManager.stage < MissionManager.Stage.BUY_DEVICE:
		return "Examinar Oficina Cobalto"
	if MissionManager.stage >= MissionManager.Stage.MISSION_2_COMPLETE:
		if not GameManager.pistol_unlocked:
			return "Comprar pistola  $%d" % pistol_price
		return "Comprar munição x%d  $%d" % [ammo_pack_size, ammo_pack_price]
	return "Comprar Dispositivo Wild  $%d" % device_price


func interact(player: CharacterBody2D) -> void:
	if MissionManager.stage < MissionManager.Stage.BUY_DEVICE:
		player.call("show_message", "OFICINA COBALTO: Só atendemos por indicação.")
		return

	if MissionManager.stage >= MissionManager.Stage.MISSION_2_COMPLETE:
		if not GameManager.pistol_unlocked:
			if not GameManager.spend_money(pistol_price):
				player.call("show_message", "OFICINA COBALTO: Você precisa de $%d para a pistola." % pistol_price)
				return
			GameManager.grant_pistol(8, 24)
			player.call("equip_pistol")
			player.call("show_message", "Pistola comprada • 8 no pente + 24 munições.")
			return

		if not GameManager.spend_money(ammo_pack_price):
			player.call("show_message", "OFICINA COBALTO: Dinheiro insuficiente para munição.")
			return
		GameManager.add_pistol_ammo(ammo_pack_size)
		player.call("show_message", "Munição comprada • +%d projéteis." % ammo_pack_size)
		return

	if not GameManager.spend_money(device_price):
		player.call("show_message", "OFICINA COBALTO: Dinheiro insuficiente.")
		return
	GameManager.add_capture_devices(1)
	if MissionManager.stage == MissionManager.Stage.BUY_DEVICE:
		MissionManager.bought_capture_device()
	player.call("show_message", "Você comprou 1 Dispositivo Wild por $%d." % device_price)
