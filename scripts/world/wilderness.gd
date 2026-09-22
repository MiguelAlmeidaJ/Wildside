extends Node2D


func _ready() -> void:
	var trees := [
		Vector2(-1080, -1510), Vector2(-890, -1370), Vector2(-690, -1515),
		Vector2(-475, -1320), Vector2(480, -1350), Vector2(680, -1510),
		Vector2(895, -1340), Vector2(1080, -1510), Vector2(-1030, -1080),
		Vector2(-760, -1160), Vector2(760, -1130), Vector2(1040, -1040),
	]
	for tree_position in trees:
		_create_tree(tree_position)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-1200, -1600, 2400, 700), Color("#315b3b"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-215, -900), Vector2(215, -900), Vector2(350, -1600), Vector2(-330, -1600)
	]), Color("#8b7d58"))
	for y in range(-1570, -920, 90):
		var sway := sin(float(y) * 0.025) * 55.0
		draw_circle(Vector2(sway, y), 7.0, Color("#d4bb72"))
	# A subtle anomaly ring around Nib's clearing.
	draw_arc(Vector2(0, -1310), 165.0, 0.0, TAU, 64, Color(0.55, 0.35, 0.9, 0.35), 9.0)


func _create_tree(at: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = at
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 28.0
	collision.shape = shape
	body.add_child(collision)
	var crown := Polygon2D.new()
	crown.polygon = PackedVector2Array([
		Vector2(0, -48), Vector2(36, -24), Vector2(42, 18), Vector2(18, 43),
		Vector2(-22, 40), Vector2(-43, 12), Vector2(-34, -28)
	])
	crown.color = Color("#173f2a")
	body.add_child(crown)
	var center := Polygon2D.new()
	center.polygon = PackedVector2Array([
		Vector2(0, -31), Vector2(27, -10), Vector2(20, 26), Vector2(-18, 27), Vector2(-28, -8)
	])
	center.color = Color("#2f6d43")
	center.z_index = 1
	body.add_child(center)
	add_child(body)

