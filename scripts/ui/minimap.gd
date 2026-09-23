extends Control

const WORLD_MIN := Vector2(-1800.0, -1600.0)
const WORLD_MAX := Vector2(3000.0, 2200.0)
const PADDING := 8.0

const MARKET_POSITION := Vector2(-520, 755)
const SAFEHOUSE_POSITION := Vector2(270, 510)
const GARAGE_POSITION := Vector2(1240, 760)
const WORKSHOP_POSITION := Vector2(1240, 620)
const WILD_TERMINAL_POSITION := Vector2(365, 510)
const PORT_SIGNAL_POSITION := Vector2(2740, 1215)

var main_target := Vector2.ZERO
var main_target_active := false
var side_target := Vector2.ZERO
var side_target_active := false
var event_target := Vector2.ZERO
var event_target_active := false
var _redraw_left := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_redraw_left -= delta
	if _redraw_left <= 0.0:
		_redraw_left = 0.08
		queue_redraw()


func set_main_objective(target: Vector2, active: bool) -> void:
	main_target = target
	main_target_active = active
	queue_redraw()


func set_side_objective(target: Vector2, active: bool) -> void:
	side_target = target
	side_target_active = active
	queue_redraw()


func set_event_objective(target: Vector2, active: bool) -> void:
	event_target = target
	event_target_active = active
	queue_redraw()


func _draw() -> void:
	if size.x <= 8.0 or size.y <= 8.0:
		return

	draw_rect(Rect2(Vector2.ZERO, size), Color(0.025, 0.04, 0.06, 0.96), true)
	_draw_regions()
	_draw_roads()
	_draw_pois()
	_draw_objectives()
	_draw_police()
	_draw_personal_vehicle()
	_draw_player()
	draw_rect(Rect2(Vector2(1, 1), size - Vector2(2, 2)), Color(0.28, 0.84, 0.76, 0.72), false, 2.0)


func _draw_regions() -> void:
	_draw_world_rect(Rect2(-1800, -1600, 3600, 700), Color(0.12, 0.31, 0.19, 0.78))
	_draw_world_rect(Rect2(-1800, -900, 980, 1700), Color(0.12, 0.23, 0.36, 0.7))
	_draw_world_rect(Rect2(-820, -900, 1640, 1700), Color(0.20, 0.16, 0.27, 0.68))
	_draw_world_rect(Rect2(820, -900, 980, 1700), Color(0.33, 0.21, 0.12, 0.7))
	_draw_world_rect(Rect2(-1800, 1180, 3600, 1020), Color(0.22, 0.12, 0.29, 0.72))
	_draw_world_rect(Rect2(1800, -900, 1200, 3100), Color(0.34, 0.23, 0.12, 0.76))
	_draw_world_rect(Rect2(2840, -900, 160, 3100), Color(0.08, 0.22, 0.3, 0.92))


func _draw_roads() -> void:
	var road := Color(0.23, 0.28, 0.34, 0.96)
	var edge := Color(0.48, 0.54, 0.58, 0.6)

	for segment in [
		[Vector2(-1800, 0), Vector2(2840, 0)],
		[Vector2(-1800, 1000), Vector2(2840, 1000)],
		[Vector2(0, -900), Vector2(0, 2200)],
		[Vector2(-1010, -900), Vector2(-1010, 2200)],
		[Vector2(1010, -900), Vector2(1010, 2200)],
		[Vector2(2200, -900), Vector2(2200, 2200)],
		[Vector2(1800, 1930), Vector2(2840, 1930)],
	]:
		var a := _to_map(segment[0])
		var b := _to_map(segment[1])
		draw_line(a, b, road, 12.0, true)
		draw_line(a, b, edge, 1.0, true)


func _draw_pois() -> void:
	_draw_square(_to_map(SAFEHOUSE_POSITION), 4.0, Color(0.45, 1.0, 0.78, 1.0))
	_draw_square(_to_map(MARKET_POSITION), 4.0, Color(1.0, 0.84, 0.32, 1.0))
	_draw_square(_to_map(GARAGE_POSITION), 4.0, Color(0.35, 0.92, 0.88, 1.0))
	_draw_square(_to_map(WORKSHOP_POSITION), 3.5, Color(0.76, 0.58, 1.0, 1.0))
	_draw_square(_to_map(WILD_TERMINAL_POSITION), 3.5, Color(0.72, 0.5, 1.0, 1.0))
	_draw_square(_to_map(PORT_SIGNAL_POSITION), 3.5, Color(0.95, 0.58, 0.25, 1.0))


func _draw_objectives() -> void:
	if main_target_active:
		_draw_diamond(_to_map(main_target), 5.0, Color(0.2, 0.93, 0.82, 1.0))
	if side_target_active:
		_draw_diamond(_to_map(side_target), 4.5, Color(1.0, 0.68, 0.22, 1.0))
	if event_target_active:
		_draw_diamond(_to_map(event_target), 5.5, Color(1.0, 0.36, 0.62, 1.0))

	if StreetRaceManager.state == StreetRaceManager.State.READY:
		_draw_diamond(_to_map(StreetRaceManager.START_POSITION), 5.0, Color(1.0, 0.54, 0.16, 1.0))
	elif StreetRaceManager.state == StreetRaceManager.State.RACING:
		var index := StreetRaceManager.current_checkpoint
		if index >= 0 and index < StreetRaceManager.CHECKPOINT_POSITIONS.size():
			_draw_diamond(
				_to_map(StreetRaceManager.CHECKPOINT_POSITIONS[index]),
				5.0,
				Color(1.0, 0.54, 0.16, 1.0)
			)


func _draw_police() -> void:
	if WantedManager.wanted_level <= 0:
		return
	for unit in get_tree().get_nodes_in_group("police_unit"):
		if not (unit is Node2D) or not unit.visible:
			continue
		draw_circle(_to_map(unit.global_position), 3.2, Color(1.0, 0.22, 0.22, 1.0))
	for officer in get_tree().get_nodes_in_group("law_enforcement"):
		if not (officer is Node2D) or not officer.visible:
			continue
		draw_circle(_to_map(officer.global_position), 2.4, Color(1.0, 0.38, 0.38, 1.0))


func _draw_personal_vehicle() -> void:
	if not GameManager.personal_vehicle_unlocked:
		return
	var scene := get_tree().current_scene
	if scene == null:
		return
	var vehicle: Node2D = scene.get_node_or_null("World/Entities/Vehicles/PersonalCar") as Node2D
	if not is_instance_valid(vehicle) or not vehicle.visible:
		return
	var current_vehicle: Node2D = null
	if is_instance_valid(GameManager.player):
		current_vehicle = GameManager.player.get("current_vehicle") as Node2D
	if current_vehicle == vehicle:
		return
	_draw_square(_to_map(vehicle.global_position), 3.2, Color(0.35, 0.95, 0.88, 1.0))


func _draw_player() -> void:
	if not is_instance_valid(GameManager.player):
		return

	var position := GameManager.get_controlled_position()
	var angle := 0.0
	var current_vehicle: Node2D = GameManager.player.get("current_vehicle") as Node2D
	if is_instance_valid(current_vehicle):
		angle = current_vehicle.rotation
	else:
		var facing: Vector2 = GameManager.player.get("facing_direction")
		if facing.length_squared() > 0.01:
			angle = facing.angle() + PI / 2.0

	var center: Vector2 = _to_map(position)
	var points := PackedVector2Array([
		Vector2(0, -7).rotated(angle) + center,
		Vector2(5.5, 6).rotated(angle) + center,
		Vector2(0, 3.5).rotated(angle) + center,
		Vector2(-5.5, 6).rotated(angle) + center,
	])
	draw_colored_polygon(points, Color(0.96, 1.0, 1.0, 1.0))
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), Color(0.12, 0.8, 0.72, 1.0), 1.5, true)


func _draw_world_rect(world_rect: Rect2, color: Color) -> void:
	var top_left: Vector2 = _to_map(world_rect.position)
	var bottom_right: Vector2 = _to_map(world_rect.position + world_rect.size)
	draw_rect(Rect2(top_left, bottom_right - top_left), color, true)


func _draw_square(center: Vector2, radius: float, color: Color) -> void:
	draw_rect(Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2.0), color, true)


func _draw_diamond(center: Vector2, radius: float, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(0, -radius),
		center + Vector2(radius, 0),
		center + Vector2(0, radius),
		center + Vector2(-radius, 0),
	]), color)


func _to_map(world_position: Vector2) -> Vector2:
	var usable: Vector2 = size - Vector2.ONE * PADDING * 2.0
	var normalized: Vector2 = Vector2(
		inverse_lerp(WORLD_MIN.x, WORLD_MAX.x, world_position.x),
		inverse_lerp(WORLD_MIN.y, WORLD_MAX.y, world_position.y)
	)
	normalized.x = clampf(normalized.x, 0.0, 1.0)
	normalized.y = clampf(normalized.y, 0.0, 1.0)
	return Vector2.ONE * PADDING + Vector2(normalized.x * usable.x, normalized.y * usable.y)
