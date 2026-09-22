extends CharacterBody2D

@export_range(1, 2) var required_level := 1
@export var chase_speed := 315.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var active := false
var _reposition_cooldown := 0.0


func _ready() -> void:
	WantedManager.wanted_changed.connect(_on_wanted_changed)
	_set_active(false)


func _physics_process(delta: float) -> void:
	if not active:
		return
	_reposition_cooldown = maxf(0.0, _reposition_cooldown - delta)
	var target := GameManager.get_controlled_position()
	var distance := global_position.distance_to(target)
	if distance > 1050.0 and _reposition_cooldown <= 0.0:
		global_position = target + Vector2.from_angle(float(required_level) * 2.1) * 650.0
		_reposition_cooldown = 4.0
	var direction := global_position.direction_to(target)
	velocity = velocity.move_toward(direction * (chase_speed + WantedManager.wanted_level * 35.0), 520.0 * delta)
	if velocity.length() > 5.0:
		rotation = lerp_angle(rotation, velocity.angle() + PI / 2.0, 1.0 - exp(-5.0 * delta))
	move_and_slide()
	for index in get_slide_collision_count():
		var collider = get_slide_collision(index).get_collider()
		if collider != null and collider.has_method("apply_damage"):
			collider.call("apply_damage", 4.0)


func _on_wanted_changed(level: int, _heat: float) -> void:
	_set_active(level >= required_level)


func _set_active(value: bool) -> void:
	var was_active := active
	active = value
	visible = value
	collision_shape.set_deferred("disabled", not value)
	if value and not was_active:
		var target := GameManager.get_controlled_position()
		global_position = target + Vector2.from_angle(float(required_level) * 2.4) * 620.0
