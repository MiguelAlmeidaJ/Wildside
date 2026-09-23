extends CharacterBody2D

@export var max_health := 70.0
@export var move_speed := 125.0
@export var aggro_range := 360.0
@export var attack_range := 66.0
@export var attack_damage := 12.0
@export var attack_cooldown := 0.9
@export var reward := 35
@export var active_after_anomaly_2 := true
@export var activation_stage := -1
@export var mission_key := "industrial"

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var health_label: Label = $HealthLabel

var health := 70.0
var active := false
var dead := false
var _home := Vector2.ZERO
var _attack_cooldown_left := 0.0
var _knockback := Vector2.ZERO
var _stun_left := 0.0
var _investigate_position := Vector2.ZERO
var _investigate_left := 0.0


func _ready() -> void:
	_home = global_position
	health = max_health
	add_to_group("hostile")
	add_to_group("damageable")
	GameManager.noise_emitted.connect(_on_noise_emitted)
	if mission_key == "blackout" or mission_key == "world_event" or activation_stage >= 0:
		_set_active(false)
	else:
		_set_active(not active_after_anomaly_2)


func _physics_process(delta: float) -> void:
	if dead:
		return
	if not active:
		if mission_key == "blackout" and MissionManager.stage == MissionManager.Stage.CLEAR_BLACKOUT:
			_set_active(true)
		elif mission_key != "blackout" and activation_stage >= 0 and MissionManager.stage == activation_stage:
			_set_active(true)
		elif mission_key != "blackout" and activation_stage < 0 and active_after_anomaly_2 and (
			MissionManager.stage == MissionManager.Stage.MISSION_2_COMPLETE
			or MissionManager.stage == MissionManager.Stage.CLEAR_RAIDERS
		):
			_set_active(true)
	if not active:
		return

	_attack_cooldown_left = maxf(0.0, _attack_cooldown_left - delta)
	_stun_left = maxf(0.0, _stun_left - delta)
	_investigate_left = maxf(0.0, _investigate_left - delta)
	_knockback = _knockback.move_toward(Vector2.ZERO, 700.0 * delta)

	if _stun_left > 0.0:
		velocity = _knockback
		move_and_slide()
		return

	var player := GameManager.player
	if not is_instance_valid(player) or is_instance_valid(player.current_vehicle):
		velocity = _knockback
		move_and_slide()
		return

	var distance := global_position.distance_to(player.global_position)
	if distance <= attack_range:
		velocity = _knockback
		if _attack_cooldown_left <= 0.0:
			_attack_cooldown_left = attack_cooldown
			player.call("take_damage", attack_damage, self)
			_play_attack_animation()
	elif distance <= aggro_range:
		var direction := global_position.direction_to(player.global_position)
		velocity = direction * move_speed + _knockback
		if velocity.length() > 1.0:
			sprite.rotation = direction.angle() + PI / 2.0
	elif _investigate_left > 0.0:
		var investigate_distance := global_position.distance_to(_investigate_position)
		if investigate_distance > 24.0:
			var investigate_direction := global_position.direction_to(_investigate_position)
			velocity = investigate_direction * (move_speed * 0.9) + _knockback
			sprite.rotation = investigate_direction.angle() + PI / 2.0
		else:
			velocity = _knockback
			_investigate_left = 0.0
	else:
		var home_distance := global_position.distance_to(_home)
		if home_distance > 24.0:
			var direction_home := global_position.direction_to(_home)
			velocity = direction_home * (move_speed * 0.6) + _knockback
			sprite.rotation = direction_home.angle() + PI / 2.0
		else:
			velocity = _knockback

	move_and_slide()


func take_damage(amount: float, source: Node2D = null) -> void:
	if dead or not active or amount <= 0.0:
		return
	health = maxf(0.0, health - amount)
	_update_health_label()

	if is_instance_valid(source):
		var direction := source.global_position.direction_to(global_position)
		_knockback = direction * 185.0

	sprite.modulate = Color(1.7, 0.65, 0.65)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.14)

	if health <= 0.0:
		_die()


func apply_knockback(direction: Vector2, strength: float) -> void:
	if dead or not active:
		return
	_knockback = direction.normalized() * strength


func apply_stun(duration: float) -> void:
	if dead or not active:
		return
	_stun_left = maxf(_stun_left, duration)
	sprite.modulate = Color(0.72, 0.9, 1.55)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, minf(duration, 0.5))


func _on_noise_emitted(position: Vector2, radius: float, kind: String, source: Node2D) -> void:
	if dead or not active or kind != "gunshot":
		return
	if source == self or global_position.distance_to(position) > radius:
		return
	_investigate_position = position
	_investigate_left = 5.0


func react_to_vehicle(impact_speed: float, vehicle: Node2D) -> void:
	if dead or not active or impact_speed < 70.0:
		return
	take_damage(impact_speed * 0.12, vehicle)


func _die() -> void:
	dead = true
	remove_from_group("hostile")
	remove_from_group("damageable")
	velocity = Vector2.ZERO
	collision_shape.set_deferred("disabled", true)
	health_label.hide()

	var tween := create_tween()
	tween.tween_property(sprite, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_BACK)
	tween.tween_callback(hide)

	GameManager.add_money(reward)
	match mission_key:
		"blackout":
			MissionManager.blackout_raider_defeated()
		"world_event":
			WorldEventManager.enemy_defeated()
		_:
			MissionManager.raider_defeated()
	if is_instance_valid(GameManager.player):
		GameManager.player.call("show_message", "Inimigo derrotado  •  +$%d" % reward)


func activate_world_event(position: Vector2) -> void:
	mission_key = "world_event"
	active_after_anomaly_2 = false
	activation_stage = -1
	dead = false
	health = max_health
	_home = position
	global_position = position
	_attack_cooldown_left = 0.0
	_knockback = Vector2.ZERO
	_stun_left = 0.0
	_investigate_left = 0.0
	sprite.scale = Vector2.ONE
	sprite.modulate = Color.WHITE
	if not is_in_group("hostile"):
		add_to_group("hostile")
	if not is_in_group("damageable"):
		add_to_group("damageable")
	_set_active(true)


func deactivate_world_event() -> void:
	if mission_key != "world_event":
		return
	dead = false
	velocity = Vector2.ZERO
	_knockback = Vector2.ZERO
	_stun_left = 0.0
	_investigate_left = 0.0
	health = max_health
	sprite.scale = Vector2.ONE
	sprite.modulate = Color.WHITE
	_set_active(false)


func _set_active(value: bool) -> void:
	active = value
	visible = value
	collision_shape.set_deferred("disabled", not value)
	health_label.visible = value
	if value:
		_update_health_label()


func _update_health_label() -> void:
	health_label.text = "RAIDER  %d/%d" % [roundi(health), roundi(max_health)]


func _play_attack_animation() -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.12, 0.88), 0.08)
	tween.tween_property(sprite, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK)
