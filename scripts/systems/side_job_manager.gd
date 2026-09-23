extends Node

signal objective_changed(title: String, description: String, target: Vector2, has_target: bool)
signal job_completed(reward: int, deliveries: int)

enum Stage {
	IDLE,
	PICKUP_PACKAGE,
	DELIVER_PACKAGE,
	PORT_PICKUP,
	PORT_RETURN,
}

const MARKET_POSITION := Vector2(-520, 755)
const VERA_POSITION := Vector2(-1240, 585)
const MALIK_POSITION := Vector2(2140, 1510)
const DANTE_POSITION := Vector2(2680, 1540)
const DELIVERY_REWARD := 120
const PORT_DELIVERY_REWARD := 160

var stage := Stage.IDLE
var deliveries_completed := 0


func reset_run() -> void:
	stage = Stage.IDLE
	deliveries_completed = 0
	objective_changed.emit("", "", Vector2.ZERO, false)


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


func _emit_objective() -> void:
	if stage == Stage.PICKUP_PACKAGE:
		objective_changed.emit("CORRIDA NOTURNA", "Retire a encomenda no Mercado 24H.", MARKET_POSITION, true)
	elif stage == Stage.DELIVER_PACKAGE:
		objective_changed.emit("CORRIDA NOTURNA", "Entregue a encomenda para Vera no Residencial.", VERA_POSITION, true)
	elif stage == Stage.PORT_PICKUP:
		objective_changed.emit("FRETE DO CAIS", "Pegue o manifesto com Dante no extremo sul do porto.", DANTE_POSITION, true)
	elif stage == Stage.PORT_RETURN:
		objective_changed.emit("FRETE DO CAIS", "Leve o manifesto de volta para Malik.", MALIK_POSITION, true)
	else:
		objective_changed.emit("", "", Vector2.ZERO, false)
