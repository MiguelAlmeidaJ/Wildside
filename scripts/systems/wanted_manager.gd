extends Node

signal wanted_changed(level: int, heat: float)
signal crime_committed(description: String, heat_added: float)
signal pursuit_state_changed(seen: bool)

const LEVEL_ONE_HEAT := 20.0
const LEVEL_TWO_HEAT := 60.0

var heat := 0.0
var wanted_level := 0
var _cooldown := 0.0
var _gunshot_report_cooldown := 0.0
var _police_contact_left := 0.0
var _vehicle_swap_cooldown := 0.0
var _last_vehicle_id := 0
var is_visible_to_police := false


func _process(delta: float) -> void:
	_gunshot_report_cooldown = maxf(0.0, _gunshot_report_cooldown - delta)
	_vehicle_swap_cooldown = maxf(0.0, _vehicle_swap_cooldown - delta)
	_police_contact_left = maxf(0.0, _police_contact_left - delta)

	var seen_now := _police_contact_left > 0.0 and wanted_level > 0
	if seen_now != is_visible_to_police:
		is_visible_to_police = seen_now
		pursuit_state_changed.emit(is_visible_to_police)

	if heat <= 0.0:
		return
	if _cooldown > 0.0:
		_cooldown -= delta
		return
	if is_visible_to_police:
		return

	var old_level := wanted_level
	heat = move_toward(heat, 0.0, 10.0 * delta)
	_recalculate_level()
	if old_level != wanted_level or is_zero_approx(heat):
		wanted_changed.emit(wanted_level, heat)


func add_heat(amount: float, description: String) -> void:
	heat = clampf(heat + amount, 0.0, 99.0)
	_cooldown = 8.0
	_recalculate_level()
	crime_committed.emit(description, amount)
	wanted_changed.emit(wanted_level, heat)


func report_gunshot(reported: bool) -> bool:
	if not reported or _gunshot_report_cooldown > 0.0:
		return false
	_gunshot_report_cooldown = 2.5
	add_heat(20.0, "Disparo reportado")
	return true


func report_police_contact(duration: float = 0.75) -> void:
	if wanted_level <= 0:
		return
	_police_contact_left = maxf(_police_contact_left, duration)
	if not is_visible_to_police:
		is_visible_to_police = true
		pursuit_state_changed.emit(true)


func notify_vehicle_change(vehicle: Node2D) -> bool:
	if not is_instance_valid(vehicle):
		return false
	var vehicle_id := vehicle.get_instance_id()
	if _last_vehicle_id == 0:
		_last_vehicle_id = vehicle_id
		return false
	if vehicle_id == _last_vehicle_id:
		return false
	_last_vehicle_id = vehicle_id
	if wanted_level <= 0 or _vehicle_swap_cooldown > 0.0:
		return false
	_vehicle_swap_cooldown = 5.0
	reduce_heat(15.0)
	return true


func reduce_heat(amount: float) -> void:
	heat = maxf(0.0, heat - amount)
	_recalculate_level()
	wanted_changed.emit(wanted_level, heat)


func clear() -> void:
	heat = 0.0
	_cooldown = 0.0
	_gunshot_report_cooldown = 0.0
	_police_contact_left = 0.0
	_vehicle_swap_cooldown = 0.0
	_last_vehicle_id = 0
	wanted_level = 0
	if is_visible_to_police:
		is_visible_to_police = false
		pursuit_state_changed.emit(false)
	wanted_changed.emit(wanted_level, heat)


func reset_run() -> void:
	clear()


func _recalculate_level() -> void:
	if heat >= LEVEL_TWO_HEAT:
		wanted_level = 2
	elif heat >= LEVEL_ONE_HEAT:
		wanted_level = 1
	else:
		wanted_level = 0

