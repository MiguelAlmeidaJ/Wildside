extends Node

signal money_changed(total: int)

var player: CharacterBody2D
var money := 0


func register_player(value: CharacterBody2D) -> void:
	player = value


func get_controlled_position() -> Vector2:
	if not is_instance_valid(player):
		return Vector2.ZERO
	if is_instance_valid(player.current_vehicle):
		return player.current_vehicle.global_position
	return player.global_position


func add_money(amount: int) -> void:
	money = maxi(0, money + amount)
	money_changed.emit(money)


func reset_run() -> void:
	money = 0
	money_changed.emit(money)

