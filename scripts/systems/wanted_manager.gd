extends Node

signal wanted_changed(level: int, heat: float)
signal crime_committed(description: String, heat_added: float)

const LEVEL_ONE_HEAT := 20.0
const LEVEL_TWO_HEAT := 60.0

var heat := 0.0
var wanted_level := 0
var _cooldown := 0.0


func _process(delta: float) -> void:
	if heat <= 0.0:
		return
	if _cooldown > 0.0:
		_cooldown -= delta
		return

	var old_level := wanted_level
	heat = move_toward(heat, 0.0, 5.0 * delta)
	_recalculate_level()
	if old_level != wanted_level or is_zero_approx(heat):
		wanted_changed.emit(wanted_level, heat)


func add_heat(amount: float, description: String) -> void:
	heat = clampf(heat + amount, 0.0, 99.0)
	_cooldown = 8.0
	_recalculate_level()
	crime_committed.emit(description, amount)
	wanted_changed.emit(wanted_level, heat)


func reduce_heat(amount: float) -> void:
	heat = maxf(0.0, heat - amount)
	_recalculate_level()
	wanted_changed.emit(wanted_level, heat)


func clear() -> void:
	heat = 0.0
	_cooldown = 0.0
	wanted_level = 0
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

