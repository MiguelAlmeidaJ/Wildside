extends Node

signal money_changed(total: int)
signal district_changed(name: String)
signal capture_devices_changed(total: int)

var player: CharacterBody2D
var money := 0
var current_district := ""
var capture_devices := 0


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


func spend_money(amount: int) -> bool:
	if amount <= 0 or money < amount:
		return false
	money -= amount
	money_changed.emit(money)
	return true


func add_capture_devices(amount: int) -> void:
	capture_devices = maxi(0, capture_devices + amount)
	capture_devices_changed.emit(capture_devices)


func consume_capture_device() -> bool:
	if capture_devices <= 0:
		return false
	capture_devices -= 1
	capture_devices_changed.emit(capture_devices)
	return true


func set_district(name: String) -> void:
	if name == current_district:
		return
	current_district = name
	district_changed.emit(name)


func reset_run() -> void:
	money = 0
	current_district = ""
	capture_devices = 0
	money_changed.emit(money)
	capture_devices_changed.emit(capture_devices)

