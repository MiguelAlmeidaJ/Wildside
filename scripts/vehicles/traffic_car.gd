extends CharacterBody2D

@export_range(0, 4) var route_id := 0
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
	if get_slide_collision_count() > 0:
		velocity *= 0.18


func _route_points(id: int) -> Array[Vector2]:
	var points: Array[Vector2] = []
	match id:
		0:
			points = [
				Vector2(-1650, -80), Vector2(-250, -80), Vector2(250, -80),
				Vector2(1650, -80), Vector2(1650, 120), Vector2(250, 120),
				Vector2(-250, 120), Vector2(-1650, 120)
			]
		1:
			points = [
				Vector2(1650, 875), Vector2(250, 875), Vector2(-250, 875),
				Vector2(-1650, 875), Vector2(-1650, 1125), Vector2(-250, 1125),
				Vector2(250, 1125), Vector2(1650, 1125)
			]
		2:
			points = [
				Vector2(-1120, -820), Vector2(-1120, 760), Vector2(-1120, 1660),
				Vector2(-880, 1660), Vector2(-880, 760), Vector2(-880, -820)
			]
		3:
			points = [
				Vector2(870, 1660), Vector2(870, 760), Vector2(870, -820),
				Vector2(1150, -820), Vector2(1150, 760), Vector2(1150, 1660)
			]
		4:
			points = [
				Vector2(1850, -80), Vector2(2700, -80), Vector2(2700, 120),
				Vector2(2250, 120), Vector2(2250, 875), Vector2(2700, 875),
				Vector2(2700, 1125), Vector2(2250, 1125), Vector2(2250, 1850),
				Vector2(2050, 1850), Vector2(2050, 1125), Vector2(1850, 1125),
				Vector2(1850, 875), Vector2(2050, 875), Vector2(2050, 120),
				Vector2(1850, 120)
			]
	return points
