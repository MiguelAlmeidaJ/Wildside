extends CharacterBody2D

@export_range(4, 5) var required_level := 4
@export var response_slot := 0
@export var max_health := 125.0
@export var move_speed := 185.0
@export var attack_range := 540.0
@export var preferred_range := 300.0
@export var shot_damage := 12.0
@export var shot_cooldown := 0.82
@export var response_delay := 5.8
@export var spawn_min_distance := 1050.0
@export var spawn_max_distance := 1320.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var health_label: Label = $HealthLabel

var health := 125.0
var active := false
var responding := false
var dead := false
var response_left := 0.0
var _shot_cooldown_left := 0.0
var _stun_left := 0.0
var _knockback := Vector2.ZERO
var _player_provoked := false
var _crime_cooldown := 0.0


func _ready() -> void:
	add_to_group("military_unit")
	add_to_group("law_enforcement")
	add_to_group("hostile")
	add_to_group("damageable")
	health = max_health
	WantedManager.wanted_changed.connect(_on_wanted_changed)
	_set_dormant()


func _physics_process(delta: float) -> void:
	_shot_cooldown_left = maxf(0.0, _shot_cooldown_left - delta)
	_stun_left = maxf(0.0, _stun_left - delta)
	_crime_cooldown = maxf(0.0, _crime_cooldown - delta)
	_knockback = _knockback.move_toward(Vector2.ZERO, 680.0 * delta)

	if responding:
		response_left = maxf(0.0, response_left - delta)
		if response_left <= 0.0:
			_finish_response()
		return

	if not active or dead:
		return

	if WantedManager.wanted_level < required_level:
		_set_dormant()
		return

	var player: CharacterBody2D = GameManager.player
	if not is_instance_valid(player):
		return

	var target_position := GameManager.get_controlled_position()
	var distance := global_position.distance_to(target_position)
	if distance <= attack_range + 150.0:
		WantedManager.report_police_contact(1.0)

	if _stun_left > 0.0:
		velocity = _knockback
		move_and_slide()
		return

	var has_los := _has_line_of_sight(target_position)
	if distance <= attack_range and has_los:
		var direction := global_position.direction_to(target_position)
		if distance < preferred_range * 0.72:
			velocity = velocity.move_toward(-direction * move_speed * 0.45 + _knockback, 620.0 * delta)
		else:
			velocity = velocity.move_toward(_knockback, 760.0 * delta)
		sprite.rotation = direction.angle() + PI / 2.0
		if _shot_cooldown_left <= 0.0:
			_shot_cooldown_left = shot_cooldown
			_fire_at_player(player, target_position)
	else:
		var direction := global_position.direction_to(target_position)
		velocity = velocity.move_toward(direction * move_speed + _knockback, 620.0 * delta)
		if velocity.length() > 2.0:
			sprite.rotation = velocity.angle() + PI / 2.0

	move_and_slide()


func take_damage(amount: float, source: Node2D = null) -> void:
	if not active or dead or amount <= 0.0:
		return

	if _is_player_aggression(source):
		_player_provoked = true
		if _crime_cooldown <= 0.0:
			_crime_cooldown = 1.3
			WantedManager.report_military_assault()

	health = maxf(0.0, health - amount)
	_update_health_label()

	if is_instance_valid(source):
		_knockback = source.global_position.direction_to(global_position) * 150.0

	sprite.modulate = Color(1.5, 0.62, 0.58)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.14)

	if health <= 0.0:
		_die()


func react_to_vehicle(impact_speed: float, vehicle: Node2D) -> void:
	if not active or dead or impact_speed < 65.0:
		return
	take_damage(clampf((impact_speed - 40.0) * 0.34, 8.0, 72.0), vehicle)


func apply_stun(duration: float) -> void:
	if not active or dead:
		return
	_stun_left = maxf(_stun_left, duration)


func apply_knockback(direction: Vector2, strength: float) -> void:
	if not active or dead:
		return
	_knockback = direction.normalized() * minf(strength, 190.0)


func _fire_at_player(player: CharacterBody2D, target_position: Vector2) -> void:
	_draw_tracer(target_position)
	var vehicle: Node2D = player.get("current_vehicle") as Node2D
	if is_instance_valid(vehicle) and vehicle.has_method("apply_damage"):
		vehicle.call("apply_damage", shot_damage * 0.72)
	else:
		player.call("take_damage", shot_damage, self)


func _has_line_of_sight(target_position: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(global_position, target_position)
	query.collision_mask = 1
	query.exclude = [get_rid()]
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	return hit.is_empty()


func _draw_tracer(target_position: Vector2) -> void:
	var parent: Node2D = get_parent() as Node2D
	if parent == null:
		return
	var tracer := Line2D.new()
	tracer.width = 2.5
	tracer.default_color = Color(1.0, 0.68, 0.28, 0.95)
	tracer.points = PackedVector2Array([
		parent.to_local(global_position),
		parent.to_local(target_position),
	])
	parent.add_child(tracer)
	var tween := tracer.create_tween()
	tween.tween_property(tracer, "modulate:a", 0.0, 0.11)
	tween.tween_callback(tracer.queue_free)


func _die() -> void:
	if dead:
		return
	dead = true
	active = false
	velocity = Vector2.ZERO
	collision_shape.set_deferred("disabled", true)
	health_label.hide()

	if _player_provoked:
		WantedManager.report_military_killed()

	if is_instance_valid(GameManager.player):
		GameManager.player.call("show_message", "MILITAR ABATIDO • reforços foram acionados.")

	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(0.35, 0.38, 0.32, 0.9), 0.12)
	tween.parallel().tween_property(sprite, "scale", Vector2(0.9, 0.72), 0.16)
	tween.tween_interval(0.7)
	tween.tween_callback(_schedule_reinforcement)


func _schedule_reinforcement() -> void:
	visible = false
	sprite.scale = Vector2.ONE
	sprite.modulate = Color.WHITE
	if WantedManager.wanted_level >= required_level:
		dead = false
		health = max_health
		responding = true
		response_left = response_delay + 3.0 + float(response_slot) * 0.6
		_update_health_label()
	else:
		_set_dormant()


func _on_wanted_changed(level: int, _heat: float) -> void:
	if level < required_level:
		_set_dormant()
	elif not active and not responding and not dead:
		_begin_response()


func _begin_response() -> void:
	active = false
	responding = true
	dead = false
	response_left = response_delay + float(response_slot) * 0.7
	health = max_health
	_player_provoked = false
	_shot_cooldown_left = 0.0
	_stun_left = 0.0
	_knockback = Vector2.ZERO
	visible = false
	collision_shape.set_deferred("disabled", true)
	_update_health_label()


func _finish_response() -> void:
	if WantedManager.wanted_level < required_level:
		_set_dormant()
		return
	responding = false
	active = true
	health = max_health
	global_position = _find_spawn_position(GameManager.get_controlled_position())
	visible = true
	collision_shape.set_deferred("disabled", false)
	health_label.show()
	_update_health_label()


func _set_dormant() -> void:
	active = false
	responding = false
	dead = false
	response_left = 0.0
	health = max_health
	velocity = Vector2.ZERO
	_player_provoked = false
	visible = false
	collision_shape.set_deferred("disabled", true)
	health_label.hide()
	sprite.scale = Vector2.ONE
	sprite.modulate = Color.WHITE


func _find_spawn_position(target: Vector2) -> Vector2:
	var anchors: Array[Vector2] = [
		Vector2(-2250, -720),
		Vector2(-2250, 1600),
		Vector2(-1010, -720),
		Vector2(-1010, 1600),
		Vector2(1010, -720),
		Vector2(1010, 1600),
		Vector2(2320, -720),
		Vector2(2320, 1600),
	]
	var preferred := lerpf(spawn_min_distance, spawn_max_distance, float(response_slot) / 2.0)
	var best_position := anchors[0]
	var best_score := INF
	for candidate in anchors:
		var distance := candidate.distance_to(target)
		if distance < spawn_min_distance * 0.82:
			continue
		var score := absf(distance - preferred)
		if score < best_score:
			best_score = score
			best_position = candidate

	if best_score == INF:
		var farthest := -1.0
		for candidate in anchors:
			var distance := candidate.distance_to(target)
			if distance > farthest:
				farthest = distance
				best_position = candidate
	return best_position


func _is_player_aggression(source: Node2D) -> bool:
	if not is_instance_valid(source):
		return false
	if source == GameManager.player:
		return true
	return source.is_in_group("player_vehicle")


func _update_health_label() -> void:
	health_label.text = "MILITAR  %d/%d" % [roundi(health), roundi(max_health)]
