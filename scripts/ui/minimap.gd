extends Control

const STATIC_LAYER_SCRIPT := preload("res://scripts/ui/minimap_static.gd")

const WORLD_MIN := Vector2(-2700.0, -1600.0)
const WORLD_MAX := Vector2(3000.0, 2200.0)
const PADDING := 8.0
const DYNAMIC_REDRAW_INTERVAL := 0.16

var main_target := Vector2.ZERO
var main_target_active := false
var side_target := Vector2.ZERO
var side_target_active := false
var event_target := Vector2.ZERO
var event_target_active := false
var _redraw_left := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var static_layer := STATIC_LAYER_SCRIPT.new() as Control
	static_layer.name = "StaticLayer"
	static_layer.z_index = -1
	static_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(static_layer)
	static_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return

	_redraw_left -= delta
	if _redraw_left <= 0.0:
		_redraw_left = DYNAMIC_REDRAW_INTERVAL
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

	_draw_objectives()
	_draw_police()
	_draw_personal_vehicle()
	_draw_player()
	draw_rect(Rect2(Vector2(1, 1), size - Vector2(2, 2)), Color(0.28, 0.84, 0.76, 0.72), false, 2.0)


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
			_draw_diamond(_to_map(StreetRaceManager.CHECKPOINT_POSITIONS[index]), 5.0, Color(1.0, 0.54, 0.16, 1.0))


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
		if officer.is_in_group("military_unit"):
			_draw_diamond(_to_map(officer.global_position), 4.0, Color(1.0, 0.62, 0.22, 1.0))
		else:
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

	var center := _to_map(position)
	var points := PackedVector2Array([
		Vector2(0, -7).rotated(angle) + center,
		Vector2(5.5, 6).rotated(angle) + center,
		Vector2(0, 3.5).rotated(angle) + center,
		Vector2(-5.5, 6).rotated(angle) + center,
	])
	draw_colored_polygon(points, Color(0.96, 1.0, 1.0, 1.0))
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), Color(0.12, 0.8, 0.72, 1.0), 1.5, true)


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
	var usable := size - Vector2.ONE * PADDING * 2.0
	var normalized := Vector2(
		inverse_lerp(WORLD_MIN.x, WORLD_MAX.x, world_position.x),
		inverse_lerp(WORLD_MIN.y, WORLD_MAX.y, world_position.y)
	)
	normalized.x = clampf(normalized.x, 0.0, 1.0)
	normalized.y = clampf(normalized.y, 0.0, 1.0)
	return Vector2.ONE * PADDING + Vector2(normalized.x * usable.x, normalized.y * usable.y)
