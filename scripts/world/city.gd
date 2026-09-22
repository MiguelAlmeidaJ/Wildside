extends Node2D

const CITY_RECT := Rect2(-1800.0, -900.0, 3600.0, 2700.0)
const BUILDINGS := [
	[Rect2(-1720.0, -820.0, 420.0, 540.0), Color("#355070")],
	[Rect2(-720.0, -820.0, 400.0, 540.0), Color("#6d597a")],
	[Rect2(320.0, -820.0, 400.0, 540.0), Color("#52796f")],
	[Rect2(1300.0, -820.0, 420.0, 540.0), Color("#b56576")],
	[Rect2(-1720.0, 280.0, 420.0, 440.0), Color("#4a6fa5")],
	[Rect2(-720.0, 280.0, 400.0, 440.0), Color("#7f5539")],
	[Rect2(320.0, 280.0, 400.0, 440.0), Color("#588157")],
	[Rect2(1300.0, 280.0, 420.0, 440.0), Color("#9c6644")],
	[Rect2(-1720.0, 1280.0, 420.0, 440.0), Color("#5c677d")],
	[Rect2(-720.0, 1280.0, 400.0, 440.0), Color("#7b2cbf")],
	[Rect2(320.0, 1280.0, 400.0, 440.0), Color("#386641")],
	[Rect2(1300.0, 1280.0, 420.0, 440.0), Color("#bc6c25")],
]

const ROAD_COLOR := Color("#303945")
const SIDEWALK_COLOR := Color("#aeb7bd")
const LANE_COLOR := Color("#f7d774")


func _ready() -> void:
	for index in range(BUILDINGS.size()):
		_create_building(BUILDINGS[index][0], BUILDINGS[index][1], index)

	_create_obstacle(Vector2(-520, -95), Color("#f6bd60"))
	_create_obstacle(Vector2(520, 95), Color("#84a59d"))
	_create_obstacle(Vector2(-1010, 520), Color("#f28482"))
	_create_obstacle(Vector2(1010, 1450), Color("#90be6d"))
	_create_world_boundaries()
	queue_redraw()


func _draw() -> void:
	draw_rect(CITY_RECT, Color("#77a464"))

	# Duas avenidas horizontais e três eixos verticais.
	draw_rect(Rect2(-1800, -180, 3600, 360), ROAD_COLOR)
	draw_rect(Rect2(-1800, 820, 3600, 360), ROAD_COLOR)
	draw_rect(Rect2(-220, -900, 440, 2700), ROAD_COLOR)
	draw_rect(Rect2(-1200, -900, 380, 2700), ROAD_COLOR)
	draw_rect(Rect2(820, -900, 380, 2700), ROAD_COLOR)

	# Calçadas horizontais.
	draw_rect(Rect2(-1800, -280, 3600, 100), SIDEWALK_COLOR)
	draw_rect(Rect2(-1800, 180, 3600, 100), SIDEWALK_COLOR)
	draw_rect(Rect2(-1800, 720, 3600, 100), SIDEWALK_COLOR)
	draw_rect(Rect2(-1800, 1180, 3600, 100), SIDEWALK_COLOR)

	# Calçadas verticais.
	for x in [-1300, -820, -320, 220, 720, 1200]:
		draw_rect(Rect2(x, -900, 100, 2700), SIDEWALK_COLOR)

	# Faixas tracejadas das avenidas.
	for x in range(-1750, 1751, 120):
		draw_rect(Rect2(x, -5, 65, 10), LANE_COLOR)
		draw_rect(Rect2(x, 995, 65, 10), LANE_COLOR)

	for y in range(-850, 1751, 120):
		draw_rect(Rect2(-5, y, 10, 65), LANE_COLOR)
		draw_rect(Rect2(-1015, y, 10, 65), LANE_COLOR)
		draw_rect(Rect2(1005, y, 10, 65), LANE_COLOR)

	_draw_crosswalk(Vector2.ZERO)
	_draw_crosswalk(Vector2(0, 1000))
	_draw_crosswalk(Vector2(-1010, 0))
	_draw_crosswalk(Vector2(1010, 0))


func _draw_crosswalk(center: Vector2) -> void:
	var crosswalk_color := Color("#e9ecef")
	for offset in range(-140, 141, 40):
		draw_rect(Rect2(center.x + offset, center.y - 205, 22, 55), crosswalk_color)
		draw_rect(Rect2(center.x + offset, center.y + 150, 22, 55), crosswalk_color)
		draw_rect(Rect2(center.x - 245, center.y + offset, 55, 22), crosswalk_color)
		draw_rect(Rect2(center.x + 190, center.y + offset, 55, 22), crosswalk_color)


func _create_building(rect: Rect2, color: Color, index: int) -> void:
	var body := StaticBody2D.new()
	body.name = "Building%d" % (index + 1)
	body.position = rect.position + rect.size / 2.0
	body.collision_layer = 1
	body.collision_mask = 0

	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = rect.size
	shape.shape = rectangle
	body.add_child(shape)

	var roof := Polygon2D.new()
	var half := rect.size / 2.0
	roof.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
		Vector2(half.x, half.y), Vector2(-half.x, half.y)
	])
	roof.color = color
	body.add_child(roof)

	var inset := Polygon2D.new()
	var inner := half - Vector2(26, 26)
	inset.polygon = PackedVector2Array([
		Vector2(-inner.x, -inner.y), Vector2(inner.x, -inner.y),
		Vector2(inner.x, inner.y), Vector2(-inner.x, inner.y)
	])
	inset.color = color.lightened(0.12)
	inset.z_index = 1
	body.add_child(inset)

	var outline := Line2D.new()
	outline.points = PackedVector2Array([
		Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
		Vector2(half.x, half.y), Vector2(-half.x, half.y)
	])
	outline.closed = true
	outline.width = 8.0
	outline.default_color = Color("#202a36")
	outline.z_index = 2
	body.add_child(outline)
	add_child(body)


func _create_obstacle(at: Vector2, color: Color) -> void:
	var body := StaticBody2D.new()
	body.position = at
	body.collision_layer = 1
	body.collision_mask = 0

	var collision := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 18.0
	collision.shape = circle
	body.add_child(collision)

	var marker := Polygon2D.new()
	marker.polygon = PackedVector2Array([
		Vector2(0, -22), Vector2(16, -16), Vector2(22, 0), Vector2(16, 16),
		Vector2(0, 22), Vector2(-16, 16), Vector2(-22, 0), Vector2(-16, -16)
	])
	marker.color = color
	body.add_child(marker)
	add_child(body)


func _create_world_boundaries() -> void:
	_create_boundary(Vector2(0, -1630), Vector2(3660, 60))
	_create_boundary(Vector2(0, 1830), Vector2(3660, 60))
	_create_boundary(Vector2(-1830, 100), Vector2(60, 3460))
	_create_boundary(Vector2(1830, 100), Vector2(60, 3460))


func _create_boundary(at: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = at
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	collision.shape = rectangle
	body.add_child(collision)
	add_child(body)
