extends CharacterBody2D

@export_range(0, 3) var route_id := 0
@export var cruise_speed := 150.0
@export var vehicle_tint := Color.WHITE
@export var start_offset := 0

@onready var sprite: Sprite2D = $Sprite2D

var _points: Array[Vector2] = []
var _target_index := 0


func _ready() -> void:
	add_to_group("ambient_traffic")
	sprite.modulate = vehicle_tint
	_points = _route_points(route_id)
	if _points.is_empty():
		set_physics_process(false)
		return
	_target_index = ((start_offset % _points.size()) + _points.size()) % _points.size()
	global_position = _points[_target_index]
	_target_index = (_target_index + 1) % _points.size()


func _physics_process(delta: float) -> void:
	if _points.is_empty():
		return

	var target: Vector2 = _points[_target_index]
	var distance := global_position.distance_to(target)
	if distance < 28.0:
		_target_index = (_target_index + 1) % _points.size()
		target = _points[_target_index]

	var direction: Vector2 = global_position.direction_to(target)
	velocity = velocity.move_toward(direction * cruise_speed, 420.0 * delta)
	if velocity.length() > 5.0:
		rotation = lerp_angle(rotation, velocity.angle() + PI / 2.0, 1.0 - exp(-6.0 * delta))
	move_and_slide()


func _route_points(id: int) -> Array[Vector2]:
	match id:
		0:
			return [
				Vector2(-1650, -70), Vector2(-250, -70), Vector2(250, -70),
				Vector2(1650, -70), Vector2(1650, 70), Vector2(250, 70),
				Vector2(-250, 70), Vector2(-1650, 70)
			]
		1:
			return [
				Vector2(1650, 930), Vector2(250, 930), Vector2(-250, 930),
				Vector2(-1650, 930), Vector2(-1650, 1070), Vector2(-250, 1070),
				Vector2(250, 1070), Vector2(1650, 1070)
			]
		2:
			return [
				Vector2(-1080, -820), Vector2(-1080, 760), Vector2(-1080, 1660),
				Vector2(-940, 1660), Vector2(-940, 760), Vector2(-940, -820)
			]
		3:
			return [
				Vector2(940, 1660), Vector2(940, 760), Vector2(940, -820),
				Vector2(1080, -820), Vector2(1080, 760), Vector2(1080, 1660)
			]
	return []
