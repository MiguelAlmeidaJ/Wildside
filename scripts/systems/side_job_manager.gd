extends Node

signal objective_changed(title: String, description: String, target: Vector2, has_target: bool)
signal job_completed(reward: int, deliveries: int)

enum Stage {
	IDLE,
	PICKUP_PACKAGE,
	DELIVER_PACKAGE,
	PORT_PICKUP,
	PORT_RETURN,
	HOT_CARGO_STEAL,
	HOT_CARGO_ESCAPE,
	HOT_CARGO_DELIVER,
}

const MARKET_POSITION := Vector2(-520, 755)
const VERA_POSITION := Vector2(-1240, 585)
const MALIK_POSITION := Vector2(2070, 1215)
const DANTE_POSITION := Vector2(2720, 1745)
const NIKA_POSITION := Vector2(1450, 760)
const HOT_CARGO_POSITION := Vector2(2600, 2130)
const CHOP_SHOP_POSITION := Vector2(1450, 1125)
const HOT_CARGO_TRUCK_PATH := "World/Entities/Vehicles/HotCargoTruck"

const DELIVERY_REWARD := 120
const PORT_DELIVERY_REWARD := 160
const HOT_CARGO_BASE_REWARD := 220
const HOT_CARGO_CONDITION_BONUS := 280

var stage := Stage.IDLE
var deliveries_completed := 0
var hot_cargo_completed := 0


func _ready() -> void:
	WantedManager.wanted_changed.connect(_on_wanted_changed)


func reset_run() -> void:
	stage = Stage.IDLE
	deliveries_completed = 0
	hot_cargo_completed = 0
	objective_changed.emit("", "", Vector2.ZERO, false)
	call_deferred("_deactivate_hot_cargo_vehicle")


func talk_to_rico() -> String:
	if stage == Stage.IDLE:
		stage = Stage.PICKUP_PACKAGE
		_emit_objective()
		return "Rico: Quer dinheiro rápido? Pega uma encomenda no Mercado 24H e leva para Vera no Residencial. Sem perguntas."
	if stage == Stage.PICKUP_PACKAGE:
		return "Rico: O pacote ainda está no Mercado 24H."
	return "Rico: Primeiro termina a entrega que já está fazendo."


func pickup_package() -> bool:
	if stage != Stage.PICKUP_PACKAGE:
		return false
	stage = Stage.DELIVER_PACKAGE
	_emit_objective()
	return true


func talk_to_vera() -> String:
	if stage != Stage.DELIVER_PACKAGE:
		return "Vera: A cidade sempre avisa quando algo ruim vem."
	deliveries_completed += 1
	stage = Stage.IDLE
	GameManager.add_money(DELIVERY_REWARD)
	job_completed.emit(DELIVERY_REWARD, deliveries_completed)
	objective_changed.emit("", "", Vector2.ZERO, false)
	return "Vera: Era isso mesmo. Obrigada. O Rico já deve ter separado sua parte.  +$%d" % DELIVERY_REWARD


func talk_to_malik() -> String:
	if stage == Stage.IDLE:
		stage = Stage.PORT_PICKUP
		_emit_objective()
		return "Malik: Se quer trabalho limpo, pega o manifesto com Dante no fim do cais e traz de volta. Os guindastes estão parados, então vai a pé."
	if stage == Stage.PORT_PICKUP:
		return "Malik: Dante está no extremo sul do Porto Ferrugem. Ele tem o manifesto."
	if stage == Stage.PORT_RETURN:
		deliveries_completed += 1
		stage = Stage.IDLE
		GameManager.add_money(PORT_DELIVERY_REWARD)
		job_completed.emit(PORT_DELIVERY_REWARD, deliveries_completed)
		objective_changed.emit("", "", Vector2.ZERO, false)
		return "Malik: Perfeito. Papel entregue, turno salvo. Aqui está sua parte.  +$%d" % PORT_DELIVERY_REWARD
	return "Malik: Termine a entrega que já começou antes de pegar outro frete."


func talk_to_dante() -> String:
	if stage == Stage.PORT_PICKUP:
		stage = Stage.PORT_RETURN
		_emit_objective()
		return "Dante: Está aqui. Leva esse manifesto para Malik antes que a troca de turno comece."
	if stage == Stage.PORT_RETURN:
		return "Dante: O manifesto já está com você. Volta para o Malik."
	return "Dante: Hoje o cais está lento. Quando Malik mandar alguém, eu entrego a papelada."


func talk_to_nika() -> String:
	if MissionManager.stage < MissionManager.Stage.ANOMALY_4_COMPLETE:
		return "Nika: Ainda não confio em você o bastante para esse tipo de serviço."
	if WantedManager.wanted_level > 0:
		return "Nika: Some com essa polícia primeiro. Eu não trabalho com sirene na porta."
	if StreetRaceManager.state != StreetRaceManager.State.IDLE:
		return "Nika: Termina sua corrida antes de pegar serviço comigo."

	if stage == Stage.IDLE:
		stage = Stage.HOT_CARGO_STEAL
		_activate_hot_cargo_vehicle()
		_emit_objective()
		return "Nika: Tem um Atlas com lacre vermelho no extremo sul do porto. Tira ele de lá, perde a polícia e leva inteiro para o desmanche."
	if stage == Stage.HOT_CARGO_STEAL:
		return "Nika: O caminhão está no cais sul, com lacre vermelho. Não traz ninguém seguindo você."
	if stage == Stage.HOT_CARGO_ESCAPE:
		return "Nika: Ainda estão no seu rastro. Some do radar antes de vir para cá."
	if stage == Stage.HOT_CARGO_DELIVER:
		return "Nika: O desmanche está esperando no Industrial. Quanto mais inteiro o Atlas chegar, maior seu pagamento."
	return "Nika: Você já está ocupado com outra entrega."


func notify_job_vehicle_entered(vehicle: Node, job_id: String) -> void:
	if job_id != "hot_cargo" or stage != Stage.HOT_CARGO_STEAL:
		return
	if vehicle != _hot_cargo_truck():
		return

	stage = Stage.HOT_CARGO_ESCAPE
	WantedManager.add_heat(60.0, "Roubo de carga protegida")
	GameManager.emit_noise(vehicle.global_position, 420.0, "vehicle_theft", vehicle)
	_emit_objective()

	if is_instance_valid(GameManager.player):
		GameManager.player.call("show_message", "CARGA QUENTE • duas estrelas • perca a polícia sem destruir o caminhão.")


func notify_job_vehicle_destroyed(vehicle: Node, job_id: String) -> void:
	if job_id != "hot_cargo":
		return
	if vehicle != _hot_cargo_truck():
		return
	if stage != Stage.HOT_CARGO_ESCAPE and stage != Stage.HOT_CARGO_DELIVER:
		return
	_fail_hot_cargo("O Atlas foi destruído. Nika cancelou o serviço.")


func deliver_hot_cargo(player: CharacterBody2D) -> String:
	if stage != Stage.HOT_CARGO_DELIVER:
		return "DESMANCHE: Nenhuma carga esperada agora."

	var truck: Node2D = _hot_cargo_truck() as Node2D
	if not is_instance_valid(truck):
		_fail_hot_cargo("A carga desapareceu antes da entrega.")
		return "DESMANCHE: O caminhão sumiu."

	if is_instance_valid(truck.get("driver")):
		return "DESMANCHE: Estacione e saia do caminhão antes de entregar."
	if truck.global_position.distance_to(CHOP_SHOP_POSITION) > 190.0:
		return "DESMANCHE: Traga o Atlas marcado até o pátio."

	var durability: float = float(truck.get("durability"))
	var maximum: float = maxf(1.0, float(truck.get("maximum_durability")))
	var condition: float = clampf(durability / maximum, 0.0, 1.0)
	var reward: int = HOT_CARGO_BASE_REWARD + roundi(float(HOT_CARGO_CONDITION_BONUS) * condition)

	GameManager.add_money(reward)
	deliveries_completed += 1
	hot_cargo_completed += 1
	stage = Stage.IDLE
	job_completed.emit(reward, deliveries_completed)
	objective_changed.emit("", "", Vector2.ZERO, false)
	_deactivate_hot_cargo_vehicle()

	return "DESMANCHE: %d%% de integridade. Pagamento liberado.  +$%d" % [roundi(condition * 100.0), reward]


func _on_wanted_changed(level: int, _heat: float) -> void:
	if stage == Stage.HOT_CARGO_ESCAPE and level == 0:
		stage = Stage.HOT_CARGO_DELIVER
		_emit_objective()
		if is_instance_valid(GameManager.player):
			GameManager.player.call("show_message", "RASTRO PERDIDO • leve o Atlas ao desmanche no Distrito Industrial.")


func _activate_hot_cargo_vehicle() -> void:
	var truck: Node = _hot_cargo_truck()
	if not is_instance_valid(truck):
		return
	truck.call("reset_job_vehicle", HOT_CARGO_POSITION, PI / 2.0)


func _deactivate_hot_cargo_vehicle() -> void:
	var truck: Node = _hot_cargo_truck()
	if is_instance_valid(truck):
		truck.call("set_job_available", false)


func _fail_hot_cargo(message: String) -> void:
	stage = Stage.IDLE
	objective_changed.emit("", "", Vector2.ZERO, false)
	WantedManager.reduce_heat(20.0)
	call_deferred("_deactivate_hot_cargo_vehicle")
	if is_instance_valid(GameManager.player):
		GameManager.player.call("show_message", message)


func _hot_cargo_truck() -> Node:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	return scene.get_node_or_null(HOT_CARGO_TRUCK_PATH)


func _emit_objective() -> void:
	if stage == Stage.PICKUP_PACKAGE:
		objective_changed.emit("CORRIDA NOTURNA", "Retire a encomenda no Mercado 24H.", MARKET_POSITION, true)
	elif stage == Stage.DELIVER_PACKAGE:
		objective_changed.emit("CORRIDA NOTURNA", "Entregue a encomenda para Vera no Residencial.", VERA_POSITION, true)
	elif stage == Stage.PORT_PICKUP:
		objective_changed.emit("FRETE DO CAIS", "Pegue o manifesto com Dante no extremo sul do porto.", DANTE_POSITION, true)
	elif stage == Stage.PORT_RETURN:
		objective_changed.emit("FRETE DO CAIS", "Leve o manifesto de volta para Malik.", MALIK_POSITION, true)
	elif stage == Stage.HOT_CARGO_STEAL:
		objective_changed.emit("CARGA QUENTE", "Roube o Atlas Cargo com lacre vermelho no Porto Ferrugem.", HOT_CARGO_POSITION, true)
	elif stage == Stage.HOT_CARGO_ESCAPE:
		objective_changed.emit("CARGA QUENTE", "Perca a polícia mantendo o caminhão vivo.", Vector2.ZERO, false)
	elif stage == Stage.HOT_CARGO_DELIVER:
		objective_changed.emit("CARGA QUENTE", "Leve o Atlas ao desmanche. Integridade maior = pagamento maior.", CHOP_SHOP_POSITION, true)
	else:
		objective_changed.emit("", "", Vector2.ZERO, false)
