extends Control

const WORLD_MIN := Vector2(-2700.0, -1600.0)
const WORLD_MAX := Vector2(3000.0, 2200.0)
const PADDING := 8.0

const MARKET_POSITION := Vector2(-520, 755)
const SAFEHOUSE_POSITION := Vector2(270, 510)
const HOSPITAL_POSITION := Vector2(-1510, 760)
const GARAGE_POSITION := Vector2(1240, 760)
const WORKSHOP_POSITION := Vector2(1240, 620)
const WILD_TERMINAL_POSITION := Vector2(365, 510)
const PORT_SIGNAL_POSITION := Vector2(2740, 1215)
const CHOP_SHOP_POSITION := Vector2(1450, 1125)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	if size.x <= 8.0 or size.y <= 8.0:
		return

	draw_rect(Rect2(Vector2.ZERO, size), Color(0.025, 0.04, 0.06, 0.96), true)
	_draw_regions()
	_draw_roads()
	_draw_pois()


func _draw_regions() -> void:
	_draw_world_rect(Rect2(-2700, -1600, 4500, 700), Color(0.12, 0.31, 0.19, 0.78))
	_draw_world_rect(Rect2(-2700, -900, 900, 3100), Color(0.14, 0.25, 0.30, 0.74))
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
		[Vector2(-2700, 0), Vector2(2840, 0)],
		[Vector2(-2700, 1000), Vector2(2840, 1000)],
		[Vector2(0, -900), Vector2(0, 2200)],
		[Vector2(-2250, -900), Vector2(-2250, 2200)],
		[Vector2(-1010, -900), Vector2(-1010, 2200)],
		[Vector2(1010, -900), Vector2(1010, 2200)],
		[Vector2(2320, -900), Vector2(2320, 2200)],
		[Vector2(1800, 1930), Vector2(2840, 1930)],
	]:
		var a := _to_map(segment[0])
		var b := _to_map(segment[1])
		draw_line(a, b, road, 12.0, true)
		draw_line(a, b, edge, 1.0, true)


func _draw_pois() -> void:
	_draw_square(_to_map(SAFEHOUSE_POSITION), 4.0, Color(0.45, 1.0, 0.78, 1.0))
	_draw_square(_to_map(HOSPITAL_POSITION), 4.0, Color(1.0, 0.34, 0.38, 1.0))
	_draw_square(_to_map(MARKET_POSITION), 4.0, Color(1.0, 0.84, 0.32, 1.0))
	_draw_square(_to_map(GARAGE_POSITION), 4.0, Color(0.35, 0.92, 0.88, 1.0))
	_draw_square(_to_map(WORKSHOP_POSITION), 3.5, Color(0.76, 0.58, 1.0, 1.0))
	_draw_square(_to_map(WILD_TERMINAL_POSITION), 3.5, Color(0.72, 0.5, 1.0, 1.0))
	_draw_square(_to_map(PORT_SIGNAL_POSITION), 3.5, Color(0.95, 0.58, 0.25, 1.0))
	_draw_square(_to_map(CHOP_SHOP_POSITION), 3.5, Color(1.0, 0.42, 0.24, 1.0))


func _draw_world_rect(world_rect: Rect2, color: Color) -> void:
	var top_left := _to_map(world_rect.position)
	var bottom_right := _to_map(world_rect.position + world_rect.size)
	draw_rect(Rect2(top_left, bottom_right - top_left), color, true)


func _draw_square(center: Vector2, radius: float, color: Color) -> void:
	draw_rect(Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2.0), color, true)


func _to_map(world_position: Vector2) -> Vector2:
	var usable := size - Vector2.ONE * PADDING * 2.0
	var normalized := Vector2(
		inverse_lerp(WORLD_MIN.x, WORLD_MAX.x, world_position.x),
		inverse_lerp(WORLD_MIN.y, WORLD_MAX.y, world_position.y)
	)
	normalized.x = clampf(normalized.x, 0.0, 1.0)
	normalized.y = clampf(normalized.y, 0.0, 1.0)
	return Vector2.ONE * PADDING + Vector2(normalized.x * usable.x, normalized.y * usable.y)
