extends Node

signal money_changed(total: int)
signal district_changed(name: String)
signal capture_devices_changed(total: int)
signal weapon_changed(unlocked: bool, magazine: int, reserve: int)

var player: CharacterBody2D
var money := 0
var current_district := ""
var capture_devices := 0
var pistol_unlocked := false
var pistol_magazine := 0
var pistol_reserve := 0


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


func grant_pistol(magazine_size: int = 8, initial_reserve: int = 24) -> bool:
	if pistol_unlocked:
		return false
	pistol_unlocked = true
	pistol_magazine = magazine_size
	pistol_reserve = maxi(0, initial_reserve)
	weapon_changed.emit(pistol_unlocked, pistol_magazine, pistol_reserve)
	return true


func add_pistol_ammo(amount: int) -> void:
	pistol_reserve = maxi(0, pistol_reserve + amount)
	weapon_changed.emit(pistol_unlocked, pistol_magazine, pistol_reserve)


func consume_pistol_round() -> bool:
	if not pistol_unlocked or pistol_magazine <= 0:
		return false
	pistol_magazine -= 1
	weapon_changed.emit(pistol_unlocked, pistol_magazine, pistol_reserve)
	return true


func reload_pistol(magazine_size: int = 8) -> int:
	if not pistol_unlocked or pistol_reserve <= 0 or pistol_magazine >= magazine_size:
		return 0
	var needed := magazine_size - pistol_magazine
	var moved := mini(needed, pistol_reserve)
	pistol_magazine += moved
	pistol_reserve -= moved
	weapon_changed.emit(pistol_unlocked, pistol_magazine, pistol_reserve)
	return moved


func set_district(name: String) -> void:
	if name == current_district:
		return
	current_district = name
	district_changed.emit(name)


func reset_run() -> void:
	money = 0
	current_district = ""
	capture_devices = 0
	pistol_unlocked = false
	pistol_magazine = 0
	pistol_reserve = 0
	money_changed.emit(money)
	capture_devices_changed.emit(capture_devices)
	weapon_changed.emit(pistol_unlocked, pistol_magazine, pistol_reserve)

