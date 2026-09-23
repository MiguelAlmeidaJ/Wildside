extends Node

signal time_changed(hour: int, minute: int, phase: String)
signal period_changed(phase: String)

const MINUTES_PER_DAY := 1440.0
const START_MINUTES := 18.5 * 60.0

@export var game_minutes_per_real_second := 2.0

var game_minutes := START_MINUTES
var day_count := 1
var _last_minute := -1
var _last_phase := ""


func _ready() -> void:
	_emit_time(true)


func _process(delta: float) -> void:
	game_minutes += game_minutes_per_real_second * delta
	while game_minutes >= MINUTES_PER_DAY:
		game_minutes -= MINUTES_PER_DAY
		day_count += 1
	_emit_time(false)


func reset_run() -> void:
	game_minutes = START_MINUTES
	day_count = 1
	_last_minute = -1
	_last_phase = ""
	_emit_time(true)


func set_time(hour: int, minute: int = 0) -> void:
	game_minutes = float(clampi(hour, 0, 23) * 60 + clampi(minute, 0, 59))
	_last_minute = -1
	_emit_time(true)


func get_hour() -> int:
	return int(game_minutes / 60.0) % 24


func get_minute() -> int:
	return int(game_minutes) % 60


func get_phase() -> String:
	var hour := get_hour()
	if hour >= 6 and hour < 17:
		return "DIA"
	if hour >= 17 and hour < 20:
		return "ENTARDECER"
	if hour >= 20 or hour < 5:
		return "NOITE"
	return "AMANHECER"


func get_ambient_color() -> Color:
	match get_phase():
		"DIA":
			return Color(1.0, 0.99, 0.94, 1.0)
		"ENTARDECER":
			return Color(0.88, 0.78, 0.72, 1.0)
		"NOITE":
			return Color(0.56, 0.63, 0.79, 1.0)
		"AMANHECER":
			return Color(0.78, 0.75, 0.8, 1.0)
	return Color.WHITE


func get_clock_text() -> String:
	return "%02d:%02d" % [get_hour(), get_minute()]


func _emit_time(force: bool) -> void:
	var minute_value := int(game_minutes)
	var phase := get_phase()
	if force or minute_value != _last_minute:
		_last_minute = minute_value
		time_changed.emit(get_hour(), get_minute(), phase)
	if force or phase != _last_phase:
		_last_phase = phase
		period_changed.emit(phase)
