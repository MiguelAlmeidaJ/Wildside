extends CharacterBody2D

@export var max_health := 180.0
@export var move_speed := 145.0
@export var aggro_range := 520.0
@export var attack_range := 72.0
@export var attack_damage := 18.0
@export var attack_cooldown := 0.9
@export var capture_threshold := 0.35

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var status_label: Label = $StatusLabel

var health := 180.0
var active := false
var weakened := false
var captured := false
var _attack_cooldown_left := 0.0
var _pulse_time := 0.0


func _ready() -> void:
	health = max_health
	_set_active(false)


func _physics_process(delta: float) -> void:
	if captured:
		return

	if not active and MissionManager.stage == MissionManager.Stage.CAPTURE_MURNO:
		_set_active(true)

	if not active:
		return

	_attack_cooldown_left = maxf(0.0, _attack_cooldown_left - delta)
	_pulse_time += delta
	sprite.scale = Vector2.ONE * (1.0 + sin(_pulse_time * 5.0) * 0.025)

	if weakened:
		velocity = velocity.move_toward(Vector2.ZERO, 700.0 * delta)
		move_and_slide()
		return

	var player := GameManager.player
	if not is_instance_valid(player):
		return

	var target_position := GameManager.get_controlled_position()
	var distance := global_position.distance_to(target_position)

	var player_vehicle = player.get("current_vehicle")
	if distance <= attack_range and not is_instance_valid(player_vehicle):
		velocity = velocity.move_toward(Vector2.ZERO, 850.0 * delta)
		if _attack_cooldown_left <= 0.0:
			_attack_cooldown_left = attack_cooldown
			player.call("take_damage", attack_damage, self)
			_play_attack_animation()
	elif distance <= aggro_range:
		var direction: Vector2 = global_position.direction_to(target_position)
		velocity = velocity.move_toward(direction * move_speed, 520.0 * delta)
		if velocity.length() > 2.0:
			sprite.rotation = direction.angle() + PI / 2.0
	else:
		velocity = velocity.move_toward(Vector2.ZERO, 480.0 * delta)

	move_and_slide()


func get_interaction_priority(_player: CharacterBody2D) -> int:
	return 80 if weakened else 5


func get_interaction_text(_player: CharacterBody2D) -> String:
	if weakened:
		return "Capturar Murno  [Q]"
	return "Murno está agressivo"


func interact(player: CharacterBody2D) -> void:
	if weakened:
		attempt_capture(player)
	else:
		player.call("show_message", "Murno repele o dispositivo. Enfraqueça-o primeiro.")


func take_damage(amount: float, _source: Node2D = null) -> void:
	if not active or weakened or captured or amount <= 0.0:
		return

	health = maxf(0.0, health - amount)
	_update_status()

	sprite.modulate = Color(1.35, 0.72, 1.5)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.16)

	if health <= max_health * capture_threshold:
		_enter_weakened_state()


func apply_knockback(direction: Vector2, strength: float) -> void:
	if not active or weakened or captured:
		return
	velocity += direction.normalized() * minf(strength, 220.0)


func apply_stun(_duration: float) -> void:
	if not active or weakened or captured:
		return
	_attack_cooldown_left = maxf(_attack_cooldown_left, 0.8)


func attempt_capture(player: CharacterBody2D) -> void:
	if captured:
		return
	if MissionManager.stage != MissionManager.Stage.CAPTURE_MURNO:
		player.call("show_message", "Murno não pode ser capturado agora.")
		return
	if not weakened:
		player.call("show_message", "Murno ainda está forte demais para o dispositivo.")
		return
	if GameManager.capture_devices <= 0:
		player.call("show_message", "Você precisa de um Dispositivo Wild.")
		return

	GameManager.consume_capture_device()
	captured = true
	active = false
	remove_from_group("hostile")
	remove_from_group("damageable")
	remove_from_group("capturable")
	collision_shape.set_deferred("disabled", true)
	status_label.text = "MURNO  ◆  RESERVA"
	player.call("show_message", "Murno capturado! Como seu grupo está cheio, ele foi enviado para a reserva.")
	MissionManager.capture_murno()

	var tween := create_tween()
	tween.tween_property(sprite, "scale", Vector2.ZERO, 0.32).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.28)
	tween.tween_callback(hide)


func _enter_weakened_state() -> void:
	weakened = true
	health = maxf(1.0, health)
	velocity = Vector2.ZERO
	remove_from_group("hostile")
	add_to_group("capturable")
	status_label.text = "MURNO  ◆  ENFRAQUECIDO  [Q]"
	sprite.modulate = Color(0.78, 0.68, 0.95)
	if is_instance_valid(GameManager.player):
		GameManager.player.call("show_message", "Murno está enfraquecido! Aproxime-se e pressione Q.")


func _set_active(value: bool) -> void:
	active = value
	visible = value
	collision_shape.set_deferred("disabled", not value)
	if value:
		if not is_in_group("hostile"):
			add_to_group("hostile")
		if not is_in_group("damageable"):
			add_to_group("damageable")
		status_label.show()
		_update_status()
	else:
		status_label.hide()


func _update_status() -> void:
	if weakened:
		status_label.text = "MURNO  ◆  ENFRAQUECIDO  [Q]"
	else:
		status_label.text = "MURNO  ◆  %d/%d" % [roundi(health), roundi(max_health)]


func _play_attack_animation() -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.28, 0.78), 0.09)
	tween.tween_property(sprite, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)
