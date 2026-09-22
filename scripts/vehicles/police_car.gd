extends CharacterBody2D

const OFFICER_SCENE := preload("res://scenes/world/police_officer.tscn")

@export_range(1, 2) var required_level := 1
@export var chase_speed := 315.0
@export var contact_range := 720.0
@export var deploy_distance := 255.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var active := false
var officer: CharacterBody2D


func _ready() -> void:
	WantedManager.wanted_changed.connect(_on_wanted_changed)
	_set_active(false)


func _physics_process(delta: float) -> void:
	if not active:
		return

	var target := GameManager.get_controlled_position()
	var distance := global_position.distance_to(target)
	if distance <= contact_range:
		WantedManager.report_police_contact()

	var player := GameManager.player
	var player_vehicle = player.get("current_vehicle") if is_instance_valid(player) else null
	var player_on_foot := is_instance_valid(player) and not is_instance_valid(player_vehicle)

	if player_on_foot and distance <= deploy_distance:
		if not is_instance_valid(officer):
			_deploy_officer()
		velocity = velocity.move_toward(Vector2.ZERO, 900.0 * delta)
		move_and_slide()
		return

	var direction: Vector2 = global_position.direction_to(target)
	velocity = velocity.move_toward(
		direction * (chase_speed + WantedManager.wanted_level * 35.0),
		520.0 * delta
	)
	if velocity.length() > 5.0:
		rotation = lerp_angle(rotation, velocity.angle() + PI / 2.0, 1.0 - exp(-5.0 * delta))
	move_and_slide()

	for index in get_slide_collision_count():
		var collider = get_slide_collision(index).get_collider()
		if collider != null and collider.has_method("apply_damage"):
			collider.call("apply_damage", 4.0)


func _deploy_officer() -> void:
	if is_instance_valid(officer):
		return
	var parent := get_parent()
	if parent == null:
		return
	officer = OFFICER_SCENE.instantiate() as CharacterBody2D
	if not is_instance_valid(officer):
		return
	officer.call("set_source_car", self)
	parent.add_child(officer)
	officer.global_position = global_position + Vector2.RIGHT.rotated(rotation) * 58.0


func _on_wanted_changed(level: int, _heat: float) -> void:
	_set_active(level >= required_level)


func _set_active(value: bool) -> void:
	var was_active := active
	active = value
	visible = value
	collision_shape.set_deferred("disabled", not value)

	if not value:
		velocity = Vector2.ZERO
		if is_instance_valid(officer):
			officer.queue_free()
		return

	if value and not was_active:
		var target := GameManager.get_controlled_position()
		global_position = target + Vector2.from_angle(float(required_level) * 2.4) * 620.0
