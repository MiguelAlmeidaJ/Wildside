extends StaticBody2D

@export var device_price := 100


func _ready() -> void:
	add_to_group("interactable")


func get_interaction_text(_player: CharacterBody2D) -> String:
	if MissionManager.stage == MissionManager.Stage.BUY_DEVICE:
		return "Comprar Dispositivo Wild  $%d" % device_price
	if MissionManager.stage >= MissionManager.Stage.BUY_DEVICE:
		return "Comprar Dispositivo Wild  $%d" % device_price
	return "Examinar Oficina Cobalto"


func interact(player: CharacterBody2D) -> void:
	if MissionManager.stage < MissionManager.Stage.BUY_DEVICE:
		player.call("show_message", "OFICINA COBALTO: Só atendemos por indicação.")
		return
	if not GameManager.spend_money(device_price):
		player.call("show_message", "OFICINA COBALTO: Dinheiro insuficiente.")
		return
	GameManager.add_capture_devices(1)
	if MissionManager.stage == MissionManager.Stage.BUY_DEVICE:
		MissionManager.bought_capture_device()
	player.call("show_message", "Você comprou 1 Dispositivo Wild por $%d." % device_price)
