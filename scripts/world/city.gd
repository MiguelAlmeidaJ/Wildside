extends Node2D

const CITY_RECT := Rect2(-1800.0, -900.0, 3600.0, 2700.0)
const BUILDINGS := [
	[Rect2(-1720.0, -820.0, 420.0, 540.0), Color("#355070")],
	[Rect2(-720.0, -820.0, 400.0, 540.0), Color("#6d597a")],
	[Rect2(320.0, -820.0, 400.0, 540.0), Color("#52796f")],
	[Rect2(1300.0, -820.0, 420.0, 540.0), Color("#8e4f5f")],
	[Rect2(-1720.0, 280.0, 420.0, 440.0), Color("#4a6fa5")],
	[Rect2(-720.0, 280.0, 400.0, 440.0), Color("#7f5539")],
	[Rect2(320.0, 280.0, 400.0, 440.0), Color("#588157")],
	[Rect2(1300.0, 280.0, 420.0, 440.0), Color("#73513e")],
	[Rect2(-1720.0, 1280.0, 420.0, 440.0), Color("#5c677d")],
	[Rect2(-720.0, 1280.0, 400.0, 440.0), Color("#6741a8")],
	[Rect2(320.0, 1280.0, 400.0, 440.0), Color("#386641")],
	[Rect2(1300.0, 1280.0, 420.0, 440.0), Color("#9b5b22")],
]

const ROAD_COLOR := Color("#252d38")
const ROAD_EDGE_COLOR := Color("#44515e")
const SIDEWALK_COLOR := Color("#9aa5ac")
const SIDEWALK_EDGE := Color("#c5cdd1")
const LANE_COLOR := Color("#e8c65e")
const WINDOW_COLOR := Color("#f6d98d")


func _ready() -> void:
	for index in range(BUILDINGS.size()):
		_create_building(BUILDINGS[index][0], BUILDINGS[index][1], index)

	_create_obstacle(Vector2(-520, -95), Color("#f6bd60"))
	_create_obstacle(Vector2(520, 95), Color("#84a59d"))
	_create_obstacle(Vector2(-1010, 520), Color("#f28482"))
	_create_obstacle(Vector2(1010, 1450), Color("#90be6d"))

	_create_city_props()
	_create_district_signs()
	_create_world_boundaries()
	queue_redraw()


func _draw() -> void:
	draw_rect(CITY_RECT, Color("#5d8558"))

	# Cada distrito recebe um tom discreto para ficar reconhecível até sem HUD.
	draw_rect(Rect2(-1800, -900, 980, 1700), Color(0.12, 0.24, 0.38, 0.24))
	draw_rect(Rect2(-820, -900, 1640, 1700), Color(0.24, 0.18, 0.32, 0.17))
	draw_rect(Rect2(820, -900, 980, 1700), Color(0.39, 0.24, 0.12, 0.24))
	draw_rect(Rect2(-1800, 1180, 3600, 620), Color(0.22, 0.12, 0.30, 0.25))

	# Ruas principais.
	draw_rect(Rect2(-1800, -180, 3600, 360), ROAD_COLOR)
	draw_rect(Rect2(-1800, 820, 3600, 360), ROAD_COLOR)
	draw_rect(Rect2(-220, -900, 440, 2700), ROAD_COLOR)
	draw_rect(Rect2(-1200, -900, 380, 2700), ROAD_COLOR)
	draw_rect(Rect2(820, -900, 380, 2700), ROAD_COLOR)

	# Bordas do asfalto ajudam a separar rua/calçada.
	draw_rect(Rect2(-1800, -188, 3600, 8), ROAD_EDGE_COLOR)
	draw_rect(Rect2(-1800, 180, 3600, 8), ROAD_EDGE_COLOR)
	draw_rect(Rect2(-1800, 812, 3600, 8), ROAD_EDGE_COLOR)
	draw_rect(Rect2(-1800, 1180, 3600, 8), ROAD_EDGE_COLOR)

	# Calçadas horizontais.
	for y in [-280, 180, 720, 1180]:
		draw_rect(Rect2(-1800, y, 3600, 100), SIDEWALK_COLOR)
		draw_line(Vector2(-1800, y), Vector2(1800, y), SIDEWALK_EDGE, 3.0)

	# Calçadas verticais.
	for x in [-1300, -820, -320, 220, 720, 1200]:
		draw_rect(Rect2(x, -900, 100, 2700), SIDEWALK_COLOR)
		draw_line(Vector2(x, -900), Vector2(x, 1800), SIDEWALK_EDGE, 3.0)

	# Faixas tracejadas.
	for x in range(-1750, 1751, 120):
		draw_rect(Rect2(x, -5, 65, 10), LANE_COLOR)
		draw_rect(Rect2(x, 995, 65, 10), LANE_COLOR)

	for y in range(-850, 1751, 120):
		draw_rect(Rect2(-5, y, 10, 65), LANE_COLOR)
		draw_rect(Rect2(-1015, y, 10, 65), LANE_COLOR)
		draw_rect(Rect2(1005, y, 10, 65), LANE_COLOR)

	# Estacionamentos e marcações industriais.
	_draw_parking_rows(Vector2(-1510, 865), 4, Vector2.RIGHT)
	_draw_parking_rows(Vector2(1280, 865), 4, Vector2.RIGHT)
	_draw_parking_rows(Vector2(1280, -135), 4, Vector2.RIGHT)

	for y in range(-760, -250, 65):
		draw_line(Vector2(1275, y), Vector2(1330, y + 28), Color(0.94, 0.62, 0.22, 0.55), 7.0)

	_draw_crosswalk(Vector2.ZERO)
	_draw_crosswalk(Vector2(0, 1000))
	_draw_crosswalk(Vector2(-1010, 0))
	_draw_crosswalk(Vector2(1010, 0))


func _draw_parking_rows(start: Vector2, count: int, direction: Vector2) -> void:
	for index in range(count):
		var origin := start + direction * float(index) * 92.0
		draw_line(origin, origin + Vector2(0, 105), Color(0.8, 0.84, 0.87, 0.52), 4.0)


func _draw_crosswalk(center: Vector2) -> void:
	var crosswalk_color := Color("#dfe5e8")
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

	var half := rect.size / 2.0
	var shadow := Polygon2D.new()
	shadow.position = Vector2(13, 15)
	shadow.polygon = _rect_polygon(half)
	shadow.color = Color(0.03, 0.04, 0.06, 0.35)
	body.add_child(shadow)

	var roof := Polygon2D.new()
	roof.polygon = _rect_polygon(half)
	roof.color = color
	roof.z_index = 1
	body.add_child(roof)

	var inner := half - Vector2(24, 24)
	var inset := Polygon2D.new()
	inset.polygon = _rect_polygon(inner)
	inset.color = color.lightened(0.10)
	inset.z_index = 2
	body.add_child(inset)

	# Claraboias, caixas d'água e exaustores dão volume ao topo dos prédios.
	for row in range(2):
		for col in range(3):
			var window := Polygon2D.new()
			window.position = Vector2(-inner.x + 65 + col * 105, -inner.y + 62 + row * 105)
			window.polygon = PackedVector2Array([
				Vector2(-23, -15), Vector2(23, -15), Vector2(23, 15), Vector2(-23, 15)
			])
			window.color = WINDOW_COLOR.darkened(0.25 + float((index + row + col) % 3) * 0.12)
			window.z_index = 3
			body.add_child(window)

	var utility := Polygon2D.new()
	utility.position = Vector2(inner.x - 66, -inner.y + 62)
	utility.polygon = PackedVector2Array([
		Vector2(-28, -24), Vector2(28, -24), Vector2(28, 24), Vector2(-28, 24)
	])
	utility.color = Color("#39434d")
	utility.z_index = 3
	body.add_child(utility)

	# Fachada/entrada na borda inferior.
	var entrance := Polygon2D.new()
	entrance.position = Vector2(0, half.y - 18)
	entrance.polygon = PackedVector2Array([
		Vector2(-46, -20), Vector2(46, -20), Vector2(46, 20), Vector2(-46, 20)
	])
	entrance.color = Color("#18222e")
	entrance.z_index = 4
	body.add_child(entrance)

	var awning := Line2D.new()
	awning.position = Vector2(0, half.y - 42)
	awning.points = PackedVector2Array([Vector2(-58, 0), Vector2(58, 0)])
	awning.width = 12.0
	awning.default_color = _awning_color(index)
	awning.z_index = 4
	body.add_child(awning)

	var outline := Line2D.new()
	outline.points = PackedVector2Array([
		Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
		Vector2(half.x, half.y), Vector2(-half.x, half.y)
	])
	outline.closed = true
	outline.width = 8.0
	outline.default_color = Color("#202a36")
	outline.z_index = 5
	body.add_child(outline)
	add_child(body)


func _awning_color(index: int) -> Color:
	var colors: Array[Color] = [
		Color("#4dd0c0"), Color("#e2b45f"), Color("#df6f7b"),
		Color("#6ba6e8"), Color("#9f7aea"), Color("#78b86b")
	]
	return colors[index % colors.size()]


func _rect_polygon(half: Vector2) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
		Vector2(half.x, half.y), Vector2(-half.x, half.y)
	])


func _create_city_props() -> void:
	var lamps := [
		Vector2(-420, -240), Vector2(420, -240), Vector2(-420, 240), Vector2(420, 240),
		Vector2(-1420, -240), Vector2(-600, 240), Vector2(600, 720), Vector2(1420, 720),
		Vector2(-1420, 1180), Vector2(-600, 1180), Vector2(600, 1180), Vector2(1420, 1180),
		Vector2(-1260, 520), Vector2(760, 500), Vector2(1240, 520)
	]
	for position in lamps:
		_create_lamp(position)

	var benches := [
		Vector2(-470, 245), Vector2(455, 245), Vector2(-1480, 745),
		Vector2(-610, 745), Vector2(610, 1210), Vector2(-510, 1210)
	]
	for position in benches:
		_create_bench(position)

	var planters := [
		Vector2(-730, 235), Vector2(730, 235), Vector2(-730, 1215),
		Vector2(730, 1215), Vector2(-1280, 760)
	]
	for position in planters:
		_create_planter(position)

	var dumpsters := [
		Vector2(1260, -255), Vector2(1560, -255), Vector2(1260, 755),
		Vector2(-790, 1260), Vector2(-1280, 1260)
	]
	for position in dumpsters:
		_create_dumpster(position)

	for position in [Vector2(1370, -230), Vector2(1450, -230), Vector2(1530, -230)]:
		_create_cone(position)

	_create_container(Vector2(1510, -250), Color("#b45f3c"))
	_create_container(Vector2(1510, 760), Color("#355f7d"))
	_create_container(Vector2(1350, 760), Color("#657843"))


func _create_lamp(at: Vector2) -> void:
	var node := Node2D.new()
	node.position = at
	node.z_index = 4

	var glow := Polygon2D.new()
	glow.polygon = PackedVector2Array([
		Vector2(0, -42), Vector2(32, -12), Vector2(0, 18), Vector2(-32, -12)
	])
	glow.color = Color(1.0, 0.82, 0.42, 0.18)
	node.add_child(glow)

	var pole := Line2D.new()
	pole.points = PackedVector2Array([Vector2(0, 5), Vector2(0, -33)])
	pole.width = 5.0
	pole.default_color = Color("#27323d")
	node.add_child(pole)

	var bulb := Polygon2D.new()
	bulb.position = Vector2(0, -36)
	bulb.polygon = PackedVector2Array([
		Vector2(0, -7), Vector2(7, 0), Vector2(0, 7), Vector2(-7, 0)
	])
	bulb.color = Color("#ffd878")
	node.add_child(bulb)
	add_child(node)


func _create_bench(at: Vector2) -> void:
	var node := StaticBody2D.new()
	node.position = at
	node.z_index = 4
	node.collision_layer = 1
	node.collision_mask = 0
	_add_rect_collision(node, Vector2(72, 28))

	for y in [-8.0, 8.0]:
		var slat := Line2D.new()
		slat.points = PackedVector2Array([Vector2(-32, y), Vector2(32, y)])
		slat.width = 8.0
		slat.default_color = Color("#704d35")
		node.add_child(slat)
	add_child(node)


func _create_planter(at: Vector2) -> void:
	var node := StaticBody2D.new()
	node.position = at
	node.z_index = 4
	node.collision_layer = 1
	node.collision_mask = 0
	_add_rect_collision(node, Vector2(42, 42))

	var pot := Polygon2D.new()
	pot.polygon = PackedVector2Array([
		Vector2(-18, -10), Vector2(18, -10), Vector2(14, 16), Vector2(-14, 16)
	])
	pot.color = Color("#7f6654")
	node.add_child(pot)

	var crown := Polygon2D.new()
	crown.position = Vector2(0, -18)
	crown.polygon = PackedVector2Array([
		Vector2(0, -20), Vector2(18, -8), Vector2(16, 12), Vector2(0, 20),
		Vector2(-16, 12), Vector2(-18, -8)
	])
	crown.color = Color("#3e8050")
	node.add_child(crown)
	add_child(node)


func _create_dumpster(at: Vector2) -> void:
	var node := StaticBody2D.new()
	node.position = at
	node.z_index = 4
	node.collision_layer = 1
	node.collision_mask = 0
	_add_rect_collision(node, Vector2(62, 42))

	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-28, -18), Vector2(28, -18), Vector2(25, 18), Vector2(-25, 18)
	])
	body.color = Color("#35544a")
	node.add_child(body)

	var lid := Line2D.new()
	lid.points = PackedVector2Array([Vector2(-30, -20), Vector2(30, -20)])
	lid.width = 6.0
	lid.default_color = Color("#182f2b")
	node.add_child(lid)
	add_child(node)


func _create_cone(at: Vector2) -> void:
	var node := Node2D.new()
	node.position = at
	node.z_index = 4
	var cone := Polygon2D.new()
	cone.polygon = PackedVector2Array([
		Vector2(0, -15), Vector2(11, 13), Vector2(-11, 13)
	])
	cone.color = Color("#f08b32")
	node.add_child(cone)
	var stripe := Line2D.new()
	stripe.points = PackedVector2Array([Vector2(-7, 4), Vector2(7, 4)])
	stripe.width = 4.0
	stripe.default_color = Color("#f5eee4")
	node.add_child(stripe)
	add_child(node)


func _create_container(at: Vector2, color: Color) -> void:
	var node := StaticBody2D.new()
	node.position = at
	node.z_index = 3
	node.collision_layer = 1
	node.collision_mask = 0
	_add_rect_collision(node, Vector2(106, 52))
	var box := Polygon2D.new()
	box.polygon = PackedVector2Array([
		Vector2(-52, -24), Vector2(52, -24), Vector2(52, 24), Vector2(-52, 24)
	])
	box.color = color
	node.add_child(box)
	for x in [-35.0, -12.0, 12.0, 35.0]:
		var rib := Line2D.new()
		rib.points = PackedVector2Array([Vector2(x, -21), Vector2(x, 21)])
		rib.width = 3.0
		rib.default_color = color.darkened(0.22)
		node.add_child(rib)
	add_child(node)


func _add_rect_collision(body: StaticBody2D, size: Vector2) -> void:
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)


func _create_district_signs() -> void:
	_create_sign(Vector2(-1530, 210), "RESIDENCIAL", Color("#75a9db"))
	_create_sign(Vector2(-130, 210), "CENTRO", Color("#8fe1cf"))
	_create_sign(Vector2(1260, 210), "INDUSTRIAL", Color("#e2a761"))
	_create_sign(Vector2(-120, 1210), "ZONA SUL", Color("#bc8be8"))

	_create_shop_sign(Vector2(-675, 675), "MERCADO 24H", Color("#ffd46a"))
	_create_shop_sign(Vector2(335, 675), "ARCADE", Color("#79d8ff"))
	_create_shop_sign(Vector2(1315, 675), "COBALTO", Color("#6df1d7"))
	_create_shop_sign(Vector2(-675, 1690), "NOITE ALTA", Color("#d69bff"))


func _create_sign(at: Vector2, text_value: String, accent: Color) -> void:
	var label := Label.new()
	label.position = at
	label.z_index = 5
	label.text = text_value
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", accent)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(label)


func _create_shop_sign(at: Vector2, text_value: String, accent: Color) -> void:
	var plate := Polygon2D.new()
	plate.position = at + Vector2(46, 10)
	plate.z_index = 5
	plate.polygon = PackedVector2Array([
		Vector2(-50, -15), Vector2(50, -15), Vector2(50, 15), Vector2(-50, 15)
	])
	plate.color = Color(0.04, 0.06, 0.09, 0.88)
	add_child(plate)

	var label := Label.new()
	label.position = at
	label.z_index = 6
	label.text = text_value
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", accent)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(label)


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
