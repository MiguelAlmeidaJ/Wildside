extends StaticBody2D

const PERSONAL_VEHICLE_PRICE := 350
const REPAIR_RATE := 0.8
const REPAIR_MIN := 20
const REPAIR_MAX := 80

@onready var sign_glow: Polygon2D = $SignGlow

var _time := 0.0


func _ready() -> void:
	add_to_group("interactable")


func _process(delta: float) -> void:
	_time += delta
	sign_glow.modulate.a = 0.5 + sin(_time * 2.8) * 0.16


func get_interaction_priority(_player: CharacterBody2D) -> int:
	return 112


func get_interaction_text(_player: CharacterBody2D) -> String:
	var vehicle := _nearest_vehicle()
	if is_instance_valid(vehicle) and _vehicle_needs_repair(vehicle):
		return "Reparar veículo • Garagem Cobalto"
	if not GameManager.personal_vehicle_unlocked:
		return "Comprar veículo próprio • $%d" % PERSONAL_VEHICLE_PRICE
	return "Usar Garagem Cobalto"


func interact(player: CharacterBody2D) -> void:
	if WantedManager.wanted_level > 0:
		player.call("show_message", "GARAGEM COBALTO: Volte quando a polícia esquecer seu rosto.")
		return

	var vehicle := _nearest_vehicle()
	if is_instance_valid(vehicle) and _vehicle_needs_repair(vehicle):
		var maximum := float(vehicle.get("maximum_durability"))
		var current := float(vehicle.get("durability"))
		var missing := maxf(0.0, maximum - current)
		var price := clampi(ceili(missing * REPAIR_RATE), REPAIR_MIN, REPAIR_MAX)
		if not GameManager.spend_money(price):
			player.call("show_message", "GARAGEM COBALTO: Reparo custa $%d. Dinheiro insuficiente." % price)
			return
		vehicle.call("repair_full")
		player.call("show_message", "GARAGEM COBALTO: Veículo reparado por $%d." % price)
		return

	if not GameManager.personal_vehicle_unlocked:
		if not GameManager.spend_money(PERSONAL_VEHICLE_PRICE):
			player.call("show_message", "GARAGEM COBALTO: O carro custa $%d." % PERSONAL_VEHICLE_PRICE)
			return
		GameManager.unlock_personal_vehicle()
		player.call("show_message", "SEU PRIMEIRO CARRO • estacionado ao lado da garagem. Entrar nele não gera procura.")
		return

	player.call("show_message", "GARAGEM COBALTO: Seu carro está pronto. Traga um veículo danificado para reparar.")


func _nearest_vehicle() -> Node2D:
	var nearest: Node2D
	var nearest_distance := INF
	for candidate in get_tree().get_nodes_in_group("player_vehicle"):
		if not candidate is Node2D or not candidate.visible:
			continue
		var distance := global_position.distance_squared_to(candidate.global_position)
		if distance <= 250.0 * 250.0 and distance < nearest_distance:
			nearest = candidate
			nearest_distance = distance
	return nearest


func _vehicle_needs_repair(vehicle: Node2D) -> bool:
	var maximum := float(vehicle.get("maximum_durability"))
	var current := float(vehicle.get("durability"))
	return current < maximum - 0.5
