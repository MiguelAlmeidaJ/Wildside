extends CharacterBody2D

@export var move_speed := 205.0
@export var arrest_range := 46.0
@export var arrest_time := 1.45
@export var contact_range := 520.0
@export var max_health := 90.0
@export var melee_damage := 8.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var health_label: Label = $HealthLabel

var source_car: Node2D
var response_level := 1
var arrest_progress := 0.0
var returning_to_car := false
var health := 90.0
var dead := false
var _stun_left := 0.0
var _knockback := Vector2.ZERO
var _player_provoked := false
var _crime_cooldown := 0.0


func _ready() -> void:
	add_to_group("law_enforcement")
	add_to_group("damageable")
	health = max_health
	_update_health_label()
	WantedManager.wanted_changed.connect(_on_wanted_changed)


func set_source_car(value: Node2D) -> void:
	source_car = value


func set_response_level(value: int) -> void:
	response_level = clampi(value, 1, 5)
	move_speed = 205.0 + float(response_level - 1) * 18.0
	arrest_time = maxf(0.78, 1.45 - float(response_level - 1) * 0.12)
	contact_range = 520.0 + float(response_level - 1) * 55.0
	max_health = 90.0 + float(response_level - 1) * 8.0
	health = max_health
	_update_health_label()


func _physics_process(delta: float) -> void:
	if dead:
		return

	_crime_cooldown = maxf(0.0, _crime_cooldown - delta)
	_stun_left = maxf(0.0, _stun_left - delta)
	_knockback = _knockback.move_toward(Vector2.ZERO, 650.0 * delta)

	if WantedManager.wanted_level <= 0:
		_clear_arrest_progress()
		queue_free()
		return

	if _stun_left > 0.0:
		velocity = _knockback
		move_and_slide()
		return

	var player: CharacterBody2D = GameManager.player
	if not is_instance_valid(player):
		return

	var player_vehicle: Node2D = player.get("current_vehicle") as Node2D
	if is_instance_valid(player_vehicle):
		returning_to_car = true
		_return_to_car(delta)
		return

	returning_to_car = false
	var distance := global_position.distance_to(player.global_position)
	if distance <= contact_range:
		WantedManager.report_police_contact()

	if distance <= arrest_range:
		velocity = _knockback
		arrest_progress = minf(arrest_time, arrest_progress + delta)
		player.call("set_arrest_progress", arrest_progress / arrest_time, self)
		if arrest_progress >= arrest_time:
			player.call("arrest_by_police", self)
			arrest_progress = 0.0
			return
	else:
		_clear_arrest_progress()
		var direction: Vector2 = global_position.direction_to(player.global_position)
		velocity = velocity.move_toward(direction * move_speed + _knockback, 700.0 * delta)
		if velocity.length() > 2.0:
			sprite.rotation = velocity.angle() + PI / 2.0

	move_and_slide()


func take_damage(amount: float, source: Node2D = null) -> void:
	if dead or amount <= 0.0:
		return

	if _is_player_aggression(source):
		_player_provoked = true
		if _crime_cooldown <= 0.0:
			_crime_cooldown = 1.4
			WantedManager.report_police_assault()

	if not is_in_group("hostile"):
		add_to_group("hostile")

	health = maxf(0.0, health - amount)
	_update_health_label()

	if is_instance_valid(source):
		_knockback = source.global_position.direction_to(global_position) * 175.0

	sprite.modulate = Color(1.65, 0.62, 0.62)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.16)

	if health <= 0.0:
		_die()


func react_to_vehicle(impact_speed: float, vehicle: Node2D) -> void:
	if dead or impact_speed < 55.0:
		return
	var damage := clampf((impact_speed - 35.0) * 0.42, 8.0, 88.0)
	take_damage(damage, vehicle)


func apply_stun(duration: float) -> void:
	if dead:
		return
	_stun_left = maxf(_stun_left, duration)


func apply_knockback(direction: Vector2, strength: float) -> void:
	if dead:
		return
	_knockback = direction.normalized() * minf(strength, 220.0)


func _die() -> void:
	if dead:
		return
	dead = true
	_clear_arrest_progress()
	velocity = Vector2.ZERO
	if is_in_group("hostile"):
		remove_from_group("hostile")
	if is_in_group("damageable"):
		remove_from_group("damageable")
	collision_shape.set_deferred("disabled", true)
	health_label.hide()

	if _player_provoked:
		WantedManager.report_police_killed()

	if is_instance_valid(source_car) and source_car.has_method("notify_officer_down"):
		source_car.call("notify_officer_down", self)

	if is_instance_valid(GameManager.player):
		GameManager.player.call("show_message", "POLICIAL ABATIDO • nível de procura aumentado.")

	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(0.45, 0.45, 0.48, 0.9), 0.12)
	tween.parallel().tween_property(sprite, "scale", Vector2(0.92, 0.72), 0.16)
	tween.tween_interval(0.8)
	tween.tween_callback(queue_free)


func _return_to_car(delta: float) -> void:
	_clear_arrest_progress()
	if not is_instance_valid(source_car):
		queue_free()
		return

	var distance := global_position.distance_to(source_car.global_position)
	if distance <= 58.0:
		queue_free()
		return

	var direction: Vector2 = global_position.direction_to(source_car.global_position)
	velocity = velocity.move_toward(direction * move_speed + _knockback, 700.0 * delta)
	if velocity.length() > 2.0:
		sprite.rotation = velocity.angle() + PI / 2.0
	move_and_slide()


func _clear_arrest_progress() -> void:
	if arrest_progress <= 0.0:
		return
	arrest_progress = 0.0
	if is_instance_valid(GameManager.player):
		GameManager.player.call("set_arrest_progress", 0.0, self)


func _is_player_aggression(source: Node2D) -> bool:
	if not is_instance_valid(source):
		return false
	if source == GameManager.player:
		return true
	return source.is_in_group("player_vehicle")


func _update_health_label() -> void:
	health_label.text = "POLÍCIA  %d/%d" % [roundi(health), roundi(max_health)]


func _on_wanted_changed(level: int, _heat: float) -> void:
	if level <= 0 and not dead:
		_clear_arrest_progress()
		queue_free()
