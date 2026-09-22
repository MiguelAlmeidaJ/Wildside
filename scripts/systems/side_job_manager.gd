extends Node

signal objective_changed(title: String, description: String, target: Vector2, has_target: bool)
signal job_completed(reward: int, deliveries: int)

enum Stage {
	IDLE,
	PICKUP_PACKAGE,
	DELIVER_PACKAGE,
}

const MARKET_POSITION := Vector2(-520, 755)
const VERA_POSITION := Vector2(-1240, 585)
const DELIVERY_REWARD := 120

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
	return "Rico: Primeiro termina a entrega para Vera."


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


func _emit_objective() -> void:
	match stage:
		Stage.PICKUP_PACKAGE:
			objective_changed.emit("CORRIDA NOTURNA", "Retire a encomenda no Mercado 24H.", MARKET_POSITION, true)
		Stage.DELIVER_PACKAGE:
			objective_changed.emit("CORRIDA NOTURNA", "Entregue a encomenda para Vera no Residencial.", VERA_POSITION, true)
		_:
			objective_changed.emit("", "", Vector2.ZERO, false)
