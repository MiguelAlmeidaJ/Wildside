extends Node2D

const CITY_RECT := Rect2(-1200.0, -900.0, 2400.0, 1800.0)
const BUILDINGS := [
	[Rect2(-1120.0, -820.0, 780.0, 540.0), Color("#355070")],
	[Rect2(340.0, -820.0, 780.0, 540.0), Color("#6d597a")],
	[Rect2(-1120.0, 280.0, 780.0, 540.0), Color("#b56576")],
	[Rect2(340.0, 280.0, 780.0, 540.0), Color("#52796f")],
]


func _ready() -> void:
	for index in BUILDINGS.size():
		_create_building(BUILDINGS[index][0], BUILDINGS[index][1], index)

	_create_obstacle(Vector2(-270, -105), Color("#f6bd60"))
	_create_obstacle(Vector2(275, 105), Color("#84a59d"))
	_create_obstacle(Vector2(-265, 205), Color("#f28482"))
	_create_world_boundaries()
	queue_redraw()


func _draw() -> void:
	# Grass and the two main avenues.
	draw_rect(CITY_RECT, Color("#77a464"))
	draw_rect(Rect2(-1200, -180, 2400, 360), Color("#303945"))
	draw_rect(Rect2(-220, -900, 440, 1800), Color("#303945"))

	# Sidewalks around the blocks.
	var sidewalk := Color("#aeb7bd")
	draw_rect(Rect2(-1200, -280, 980, 100), sidewalk)
	draw_rect(Rect2(220, -280, 980, 100), sidewalk)
	draw_rect(Rect2(-1200, 180, 980, 100), sidewalk)
	draw_rect(Rect2(220, 180, 980, 100), sidewalk)
	draw_rect(Rect2(-340, -900, 120, 620), sidewalk)
	draw_rect(Rect2(220, -900, 120, 620), sidewalk)
	draw_rect(Rect2(-340, 280, 120, 620), sidewalk)
	draw_rect(Rect2(220, 280, 120, 620), sidewalk)

	# Dashed lane markings.
	var line_color := Color("#f7d774")
	for x in range(-1150, 1151, 120):
		if abs(x) > 250:
			draw_rect(Rect2(x, -5, 65, 10), line_color)
	for y in range(-850, 851, 120):
		if abs(y) > 210:
			draw_rect(Rect2(-5, y, 10, 65), line_color)

	# Crosswalks make the intersection readable at driving speed.
	for offset in range(-140, 141, 40):
		draw_rect(Rect2(offset, -205, 22, 55), Color("#e9ecef"))
		draw_rect(Rect2(offset, 150, 22, 55), Color("#e9ecef"))
		draw_rect(Rect2(-245, offset, 55, 22), Color("#e9ecef"))
		draw_rect(Rect2(190, offset, 55, 22), Color("#e9ecef"))


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
	var inner := half - Vector2(30, 30)
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
	_create_boundary(Vector2(0, -1630), Vector2(2460, 60))
	_create_boundary(Vector2(0, 930), Vector2(2460, 60))
	_create_boundary(Vector2(-1230, -350), Vector2(60, 2560))
	_create_boundary(Vector2(1230, -350), Vector2(60, 2560))


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
