extends CharacterBody2D

enum State { IDLE, WANDER, FLEE, FOLLOW }

@export var capture_chance := 0.75
@export var assist_range := 210.0
@export var assist_damage := 10.0
@export var assist_cooldown := 1.2
@export var ability_range := 300.0
@export var ability_damage := 38.0
@export var ability_knockback := 360.0
@export var ability_cooldown := 4.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var status_label: Label = $StatusLabel

var state := State.IDLE
var captured := false
var _home := Vector2.ZERO
var _wander_target := Vector2.ZERO
var _state_timer := 1.0
var _attempts := 0
var _rng := RandomNumberGenerator.new()
var _assist_cooldown_left := 0.0
var ability_cooldown_left := 0.0


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("capturable")
	add_to_group("wild_nib")
	_home = global_position
	_rng.randomize()


func _physics_process(delta: float) -> void:
	_state_timer -= delta
	_assist_cooldown_left = maxf(0.0, _assist_cooldown_left - delta)
	ability_cooldown_left = maxf(0.0, ability_cooldown_left - delta)
	if captured:
		_follow_player(delta)
		_assist_player()
	else:
		_update_wild_state(delta)
	move_and_slide()
	sprite.position.y = -5.0 + sin(Time.get_ticks_msec() * 0.006) * 2.0


func get_interaction_priority(_player: CharacterBody2D) -> int:
	return 8 if captured else 70


func get_interaction_text(_player: CharacterBody2D) -> String:
	return "Fazer carinho em Nib" if captured else "Tentar capturar Nib  [Q]"


func interact(player: CharacterBody2D) -> void:
	if captured:
		player.call("show_message", "Nib: Bli-bli!")
	else:
		attempt_capture(player)


func attempt_capture(player: CharacterBody2D) -> void:
	if captured:
		return
	if MissionManager.stage != MissionManager.Stage.CAPTURE_NIB:
		player.call("show_message", "Nib está arisco. Talvez alguma pista explique como capturá-lo.")
		return
	_attempts += 1
	var chance := minf(0.98, capture_chance + float(_attempts - 1) * 0.15)
	_play_capture_pulse()
	if _rng.randf() <= chance:
		captured = true
		state = State.FOLLOW
		remove_from_group("capturable")
		collision_shape.set_deferred("disabled", true)
		status_label.text = "NIB  ♥  SEU WILD"
		player.call("show_message", "Nib capturado! Ele agora seguirá você.")
		MissionManager.capture_nib()
	else:
		state = State.FLEE
		_state_timer = 2.0
		player.call("show_message", "Nib escapou do dispositivo. Tente outra vez!")


func _update_wild_state(_delta: float) -> void:
	var player_position := GameManager.get_controlled_position()
	if state != State.FLEE and global_position.distance_to(player_position) < 135.0:
		state = State.FLEE
		_state_timer = 1.4

	match state:
		State.IDLE:
			velocity = velocity.move_toward(Vector2.ZERO, 300.0 * _delta)
			if _state_timer <= 0.0:
				_wander_target = _home + Vector2.from_angle(_rng.randf_range(0.0, TAU)) * _rng.randf_range(20.0, 90.0)
				state = State.WANDER
				_state_timer = 2.5
		State.WANDER:
			velocity = global_position.direction_to(_wander_target) * 55.0
			if global_position.distance_to(_wander_target) < 8.0 or _state_timer <= 0.0:
				state = State.IDLE
				_state_timer = _rng.randf_range(1.0, 2.5)
		State.FLEE:
			velocity = player_position.direction_to(global_position) * 125.0
			if _state_timer <= 0.0:
				state = State.IDLE
				_state_timer = 1.0


func _follow_player(delta: float) -> void:
	var target := GameManager.get_controlled_position() + Vector2(55, 45)
	if is_instance_valid(GameManager.player) and GameManager.player.has_method("get_companion_anchor"):
		target = GameManager.player.call("get_companion_anchor", 0)
	var distance := global_position.distance_to(target)
	if distance > 650.0:
		global_position = target
		velocity = Vector2.ZERO
	elif distance > 55.0:
		velocity = global_position.direction_to(target) * (280.0 if distance > 220.0 else 165.0)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, 500.0 * delta)


func _assist_player() -> void:
	if _assist_cooldown_left > 0.0:
		return
	var target: Node2D
	var nearest_distance := INF
	for enemy in get_tree().get_nodes_in_group("hostile"):
		if not enemy is Node2D or not enemy.visible or not enemy.has_method("take_damage"):
			continue
		var distance := global_position.distance_to(enemy.global_position)
		if distance <= assist_range and distance < nearest_distance:
			target = enemy
			nearest_distance = distance
	if not is_instance_valid(target):
		return
	_assist_cooldown_left = assist_cooldown
	target.call("take_damage", assist_damage, self)
	var tween := create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.16, 0.86), 0.08)
	tween.tween_property(sprite, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK)


func use_active_ability(player: CharacterBody2D) -> bool:
	if not captured:
		player.call("show_message", "Nib ainda não faz parte do seu grupo.")
		return false
	if ability_cooldown_left > 0.0:
		player.call("show_message", "Impacto do Nib recarrega em %.1fs." % ability_cooldown_left)
		return false

	var target := _nearest_hostile(ability_range)
	if not is_instance_valid(target):
		player.call("show_message", "Nenhum inimigo ao alcance do Impacto.")
		return false

	ability_cooldown_left = ability_cooldown
	target.call("take_damage", ability_damage, self)
	if target.has_method("apply_knockback"):
		target.call("apply_knockback", global_position.direction_to(target.global_position), ability_knockback)
	_draw_ability_trail(target.global_position)
	_play_impact_animation()
	player.call("show_message", "Nib usou IMPACTO!")
	return true


func _nearest_hostile(max_range: float) -> Node2D:
	var target: Node2D
	var nearest_distance := INF
	for enemy in get_tree().get_nodes_in_group("hostile"):
		if not enemy is Node2D or not enemy.visible or not enemy.has_method("take_damage"):
			continue
		var distance := global_position.distance_to(enemy.global_position)
		if distance <= max_range and distance < nearest_distance:
			target = enemy
			nearest_distance = distance
	return target


func _draw_ability_trail(target_position: Vector2) -> void:
	var parent := get_parent()
	if parent == null:
		return
	var trail := Line2D.new()
	trail.width = 12.0
	trail.default_color = Color(0.65, 0.45, 1.0, 0.9)
	trail.points = PackedVector2Array([
		parent.to_local(global_position),
		parent.to_local(target_position),
	])
	parent.add_child(trail)
	var tween := trail.create_tween()
	tween.tween_property(trail, "modulate:a", 0.0, 0.22)
	tween.tween_callback(trail.queue_free)


func _play_impact_animation() -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.35, 0.72), 0.07)
	tween.tween_property(sprite, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)


func _play_capture_pulse() -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE * 2.2, 0.1)
	tween.parallel().tween_property(sprite, "scale", Vector2.ONE * 0.25, 0.18)
	tween.tween_property(sprite, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(sprite, "modulate", Color.WHITE, 0.2)

