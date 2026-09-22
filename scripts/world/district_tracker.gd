extends Node

@export var update_interval := 0.15

var _elapsed := 0.0


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed < update_interval:
		return
	_elapsed = 0.0

	var position := GameManager.get_controlled_position()
	GameManager.set_district(_district_for(position))


func _district_for(position: Vector2) -> String:
	if position.y < -900.0:
		return "MATA NORTE"
	if position.y >= 800.0:
		return "ZONA SUL"
	if position.x <= -800.0:
		return "BAIRRO RESIDENCIAL"
	if position.x >= 800.0:
		return "DISTRITO INDUSTRIAL"
	return "CENTRO DE WILDSIDE"
