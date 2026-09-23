extends CharacterBody2D

const OFFICER_SCENE := preload("res://scenes/world/police_officer.tscn")

@export_range(1, 5) var required_level := 1
@export var chase_speed := 270.0
@export var contact_range := 650.0
@export var deploy_distance := 235.0
@export var ram_damage := 4.0
@export var response_delay := 3.0
@export var spawn_min_distance := 900.0
@export var spawn_max_distance := 1180.0
@export var acceleration := 390.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var active := false
var responding := false
var response_left := 0.0
var officer: CharacterBody2D


func _ready() -> void:
	add_to_group("police_unit")
	WantedManager.wanted_changed.connect(_on_wanted_changed)
	_hide_unit()


func _physics_process(delta: float) -> void:
	if responding:
		response_left = maxf(0.0, response_left - delta)
		if response_left <= 0.0:
			_finish_response()
		return

	if not active:
		return

	if WantedManager.wanted_level < required_level:
		_cancel_response()
		return

	var target := GameManager.get_controlled_position()
	var distance := global_position.distance_to(target)
	if distance <= contact_range:
		WantedManager.report_police_contact()

	var player: CharacterBody2D = GameManager.player
	var player_vehicle = player.get("current_vehicle") if is_instance_valid(player) else null
	var player_on_foot := is_instance_valid(player) and not is_instance_valid(player_vehicle)

	if player_on_foot and distance <= deploy_distance:
		if not is_instance_valid(officer):
			_deploy_officer()
		velocity = velocity.move_toward(Vector2.ZERO, 720.0 * delta)
		move_and_slide()
		return

	var direction: Vector2 = global_position.direction_to(target)
	var level_bonus := float(maxi(0, WantedManager.wanted_level - 1)) * 8.0
	var target_speed := chase_speed + level_bonus
	velocity = velocity.move_toward(direction * target_speed, acceleration * delta)
	if velocity.length() > 5.0:
		rotation = lerp_angle(rotation, velocity.angle() + PI / 2.0, 1.0 - exp(-4.0 * delta))
	move_and_slide()

	for index in get_slide_collision_count():
		var collider = get_slide_collision(index).get_collider()
		if collider != null and collider.has_method("apply_damage"):
			collider.call("apply_damage", ram_damage + float(required_level - 1) * 0.8)


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
	officer.call("set_response_level", required_level)
	parent.add_child(officer)
	officer.global_position = global_position + Vector2.RIGHT.rotated(rotation) * 58.0


func _on_wanted_changed(level: int, _heat: float) -> void:
	if level >= required_level:
		if not active and not responding:
			_begin_response()
	else:
		_cancel_response()


func _begin_response() -> void:
	active = false
	responding = true
	response_left = response_delay + float(required_level - 1) * 0.55
	visible = false
	collision_shape.set_deferred("disabled", true)
	velocity = Vector2.ZERO


func _finish_response() -> void:
	if WantedManager.wanted_level < required_level:
		_cancel_response()
		return

	responding = false
	active = true
	global_position = _find_spawn_position(GameManager.get_controlled_position())
	var target := GameManager.get_controlled_position()
	var direction := global_position.direction_to(target)
	if direction != Vector2.ZERO:
		rotation = direction.angle() + PI / 2.0
	velocity = direction * minf(chase_speed * 0.45, 125.0)
	visible = true
	collision_shape.set_deferred("disabled", false)


func _cancel_response() -> void:
	active = false
	responding = false
	response_left = 0.0
	_hide_unit()
	if is_instance_valid(officer):
		officer.queue_free()


func _hide_unit() -> void:
	visible = false
	collision_shape.set_deferred("disabled", true)
	velocity = Vector2.ZERO


func _find_spawn_position(target: Vector2) -> Vector2:
	var distance := lerpf(spawn_min_distance, spawn_max_distance, float(required_level - 1) / 4.0)
	var best_position := target
	var best_distance := -1.0
	var base_angle := PI + float(required_level) * 1.17

	for step in range(8):
		var angle := base_angle + float(step) * (TAU / 8.0)
		var candidate := target + Vector2.from_angle(angle) * distance
		candidate.x = clampf(candidate.x, -1680.0, 2880.0)
		candidate.y = clampf(candidate.y, -1480.0, 2100.0)
		var candidate_distance := candidate.distance_to(target)
		if candidate_distance > best_distance:
			best_distance = candidate_distance
			best_position = candidate

	if best_distance < spawn_min_distance * 0.72:
		# Nos cantos do mapa, prioriza o lado oposto em vez de nascer perto.
		var center := Vector2(600.0, 300.0)
		var away := center.direction_to(target)
		if away == Vector2.ZERO:
			away = Vector2.RIGHT
		best_position = target - away * spawn_min_distance
		best_position.x = clampf(best_position.x, -1680.0, 2880.0)
		best_position.y = clampf(best_position.y, -1480.0, 2100.0)

	return best_position
