extends Node

signal money_changed(total: int)
signal district_changed(name: String)
signal capture_devices_changed(total: int)
signal weapon_changed(unlocked: bool, magazine: int, reserve: int)
signal noise_emitted(position: Vector2, radius: float, kind: String, source: Node2D)
signal inventory_changed(medkits: int, snacks: int, energy_drinks: int)
signal store_state_changed(opened: bool, title: String)

var player: CharacterBody2D
var money := 0
var current_district := ""
var capture_devices := 0
var pistol_unlocked := false
var pistol_magazine := 0
var pistol_reserve := 0
var medkits := 0
var snacks := 0
var energy_drinks := 0
var store_open := false
var active_store := ""


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
	inventory_changed.emit(medkits, snacks, energy_drinks)
	store_state_changed.emit(false, "")
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


func emit_noise(position: Vector2, radius: float, kind: String, source: Node2D) -> void:
	noise_emitted.emit(position, radius, kind, source)


func add_item(item_id: String, amount: int = 1) -> void:
	if amount <= 0:
		return
	match item_id:
		"medkit":
			medkits += amount
		"snack":
			snacks += amount
		"energy":
			energy_drinks += amount
		_:
			return
	inventory_changed.emit(medkits, snacks, energy_drinks)


func consume_item(item_id: String) -> bool:
	match item_id:
		"medkit":
			if medkits <= 0:
				return false
			medkits -= 1
		"snack":
			if snacks <= 0:
				return false
			snacks -= 1
		"energy":
			if energy_drinks <= 0:
				return false
			energy_drinks -= 1
		_:
			return false
	inventory_changed.emit(medkits, snacks, energy_drinks)
	return true


func open_store(store_id: String, title: String) -> void:
	active_store = store_id
	store_open = true
	store_state_changed.emit(true, title)


func close_store() -> void:
	if not store_open:
		return
	store_open = false
	active_store = ""
	store_state_changed.emit(false, "")


func purchase_store_slot(slot: int) -> String:
	if not store_open or active_store != "market24":
		return ""
	var item_id := ""
	var item_name := ""
	var price := 0
	match slot:
		1:
			item_id = "snack"
			item_name = "Lanche"
			price = 15
		2:
			item_id = "medkit"
			item_name = "Kit médico"
			price = 60
		3:
			item_id = "energy"
			item_name = "Energético"
			price = 35
		_:
			return ""
	if not spend_money(price):
		return "Dinheiro insuficiente."
	add_item(item_id, 1)
	return "%s comprado por $%d." % [item_name, price]


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
	medkits = 0
	snacks = 0
	energy_drinks = 0
	store_open = false
	active_store = ""
	money_changed.emit(money)
	capture_devices_changed.emit(capture_devices)
	weapon_changed.emit(pistol_unlocked, pistol_magazine, pistol_reserve)

