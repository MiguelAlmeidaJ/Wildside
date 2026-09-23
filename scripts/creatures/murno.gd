extends CharacterBody2D

@export var max_health := 180.0
@export var move_speed := 145.0
@export var aggro_range := 520.0
@export var attack_range := 72.0
@export var attack_damage := 18.0
@export var attack_cooldown := 0.9
@export var capture_threshold := 0.35
@export var assist_range := 260.0
@export var assist_damage := 14.0
@export var assist_cooldown := 1.0
@export var ability_range := 330.0
@export var ability_damage := 30.0
@export var ability_stun := 1.2
@export var ability_cooldown := 8.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var status_label: Label = $StatusLabel

var health := 180.0
var active := false
var weakened := false
var captured := false
var _attack_cooldown_left := 0.0
var _assist_cooldown_left := 0.0
var ability_cooldown_left := 0.0
var _pulse_time := 0.0


func _ready() -> void:
	add_to_group("wild_murno")
	health = max_health
	_set_active(false)


func _physics_process(delta: float) -> void:
	_attack_cooldown_left = maxf(0.0, _attack_cooldown_left - delta)
	_assist_cooldown_left = maxf(0.0, _assist_cooldown_left - delta)
	ability_cooldown_left = maxf(0.0, ability_cooldown_left - delta)
	_pulse_time += delta

	if captured:
		_sync_team_state()
		if GameManager.is_wild_active("murno"):
			_follow_player(delta)
			_assist_player()
			move_and_slide()
			sprite.position.y = -5.0 + sin(_pulse_time * 4.5) * 2.2
		else:
			velocity = Vector2.ZERO
		return

	if not active and MissionManager.stage == MissionManager.Stage.CAPTURE_MURNO:
		_set_active(true)

	if not active:
		return

	sprite.scale = Vector2.ONE * (1.0 + sin(_pulse_time * 5.0) * 0.025)

	if weakened:
		velocity = velocity.move_toward(Vector2.ZERO, 700.0 * delta)
		move_and_slide()
		return

	var player: CharacterBody2D = GameManager.player
	if not is_instance_valid(player):
		return

	var target_position: Vector2 = GameManager.get_controlled_position()
	var distance: float = global_position.distance_to(target_position)
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
	if captured:
		return 8
	return 80 if weakened else 5


func get_interaction_text(_player: CharacterBody2D) -> String:
	if captured:
		return "Fazer carinho em Murno"
	if weakened:
		return "Capturar Murno  [Q]"
	return "Murno está agressivo"


func interact(player: CharacterBody2D) -> void:
	if captured:
		player.call("show_message", "Murno: ...")
	elif weakened:
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
	GameManager.register_captured_wild("murno")
	if is_in_group("hostile"):
		remove_from_group("hostile")
	if is_in_group("damageable"):
		remove_from_group("damageable")
	if is_in_group("capturable"):
		remove_from_group("capturable")
	collision_shape.set_deferred("disabled", true)
	status_label.text = "MURNO  ◆  RESERVA"
	player.call("show_message", "Murno capturado! A equipe está cheia, então ele foi enviado para a reserva.")
	MissionManager.capture_murno()

	var tween := create_tween()
	tween.tween_property(sprite, "scale", Vector2.ZERO, 0.32).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.28)
	tween.tween_callback(_finish_capture_hide)


func restore_captured() -> void:
	captured = true
	active = false
	weakened = true
	if not GameManager.is_wild_captured("murno"):
		GameManager.register_captured_wild("murno")
	if is_in_group("hostile"):
		remove_from_group("hostile")
	if is_in_group("damageable"):
		remove_from_group("damageable")
	if is_in_group("capturable"):
		remove_from_group("capturable")
	collision_shape.set_deferred("disabled", true)
	sprite.scale = Vector2.ONE
	sprite.modulate = Color.WHITE
	_sync_team_state()


func use_active_ability(player: CharacterBody2D) -> bool:
	if not captured:
		player.call("show_message", "Murno ainda não foi capturado.")
		return false
	if not GameManager.is_wild_active("murno"):
		player.call("show_message", "Murno está na reserva. Troque sua equipe no apartamento.")
		return false
	if ability_cooldown_left > 0.0:
		player.call("show_message", "Eclipse do Murno recarrega em %.1fs." % ability_cooldown_left)
		return false

	var targets: Array[Node2D] = []
	for enemy in get_tree().get_nodes_in_group("hostile"):
		if not enemy is Node2D or not enemy.visible or not enemy.has_method("take_damage"):
			continue
		if global_position.distance_to(enemy.global_position) <= ability_range:
			targets.append(enemy)

	if targets.is_empty():
		player.call("show_message", "Nenhum inimigo ao alcance do Eclipse.")
		return false

	ability_cooldown_left = ability_cooldown
	for target in targets:
		target.call("take_damage", ability_damage, self)
		if target.has_method("apply_stun"):
			target.call("apply_stun", ability_stun)

	_play_eclipse_effect()
	player.call("show_message", "Murno usou ECLIPSE em %d alvo(s)!" % targets.size())
	return true


func _follow_player(delta: float) -> void:
	var slot: int = maxi(0, GameManager.get_wild_slot("murno"))
	var target: Vector2 = GameManager.get_controlled_position() + Vector2(60, 58)
	if is_instance_valid(GameManager.player) and GameManager.player.has_method("get_companion_anchor"):
		target = GameManager.player.call("get_companion_anchor", slot) as Vector2
	var distance: float = global_position.distance_to(target)
	if distance > 650.0:
		global_position = target
		velocity = Vector2.ZERO
	elif distance > 60.0:
		velocity = global_position.direction_to(target) * (290.0 if distance > 220.0 else 170.0)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, 520.0 * delta)


func _assist_player() -> void:
	if _assist_cooldown_left > 0.0:
		return
	var target: Node2D
	var nearest_distance := INF
	for enemy in get_tree().get_nodes_in_group("hostile"):
		if not enemy is Node2D or not enemy.visible or not enemy.has_method("take_damage"):
			continue
		var distance: float = global_position.distance_to(enemy.global_position)
		if distance <= assist_range and distance < nearest_distance:
			target = enemy
			nearest_distance = distance
	if not is_instance_valid(target):
		return
	_assist_cooldown_left = assist_cooldown
	target.call("take_damage", assist_damage, self)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(1.2, 0.85, 1.5), 0.08)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.16)


func _sync_team_state() -> void:
	var team_active := GameManager.is_wild_active("murno")
	visible = team_active
	status_label.visible = team_active
	collision_shape.set_deferred("disabled", true)
	if team_active:
		if not is_in_group("interactable"):
			add_to_group("interactable")
		status_label.text = "MURNO  ◆  SEU WILD"
		sprite.scale = Vector2.ONE
		sprite.modulate = Color.WHITE
	elif is_in_group("interactable"):
		remove_from_group("interactable")


func _finish_capture_hide() -> void:
	sprite.scale = Vector2.ONE
	sprite.modulate = Color.WHITE
	_sync_team_state()


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


func _play_eclipse_effect() -> void:
	var parent: Node2D = get_parent() as Node2D
	if parent == null:
		return
	var ring := Line2D.new()
	var points := PackedVector2Array()
	for index in range(25):
		var angle := TAU * float(index) / 24.0
		points.append(parent.to_local(global_position) + Vector2.from_angle(angle) * ability_range)
	ring.points = points
	ring.width = 8.0
	ring.default_color = Color(0.58, 0.38, 0.92, 0.88)
	parent.add_child(ring)
	var tween := ring.create_tween()
	tween.tween_property(ring, "modulate:a", 0.0, 0.4)
	tween.tween_callback(ring.queue_free)
