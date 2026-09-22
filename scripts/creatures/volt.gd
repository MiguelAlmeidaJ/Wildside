extends CharacterBody2D

enum State { IDLE, WANDER, FLEE, FOLLOW }

@export var capture_chance := 1.0
@export var assist_range := 260.0
@export var assist_damage := 18.0
@export var assist_cooldown := 0.85
@export var ability_range := 390.0
@export var chain_range := 300.0
@export var ability_damage := 24.0
@export var ability_stun := 0.85
@export var ability_max_targets := 3
@export var ability_cooldown := 6.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var status_label: Label = $StatusLabel

var state := State.IDLE
var captured := false
var available := false
var _home := Vector2.ZERO
var _wander_target := Vector2.ZERO
var _state_timer := 1.0
var _rng := RandomNumberGenerator.new()
var _assist_cooldown_left := 0.0
var ability_cooldown_left := 0.0


func _ready() -> void:
	_home = global_position
	_rng.randomize()
	visible = false
	collision_shape.disabled = true


func _physics_process(delta: float) -> void:
	if not available and MissionManager.stage == MissionManager.Stage.CAPTURE_VOLT:
		_activate()
	if not available:
		return

	_state_timer -= delta
	_assist_cooldown_left = maxf(0.0, _assist_cooldown_left - delta)
	ability_cooldown_left = maxf(0.0, ability_cooldown_left - delta)
	if captured:
		_follow_player(delta)
		_assist_player()
	else:
		_update_wild_state(delta)
	move_and_slide()
	sprite.position.y = -5.0 + sin(Time.get_ticks_msec() * 0.007) * 2.5


func _activate() -> void:
	available = true
	visible = true
	collision_shape.set_deferred("disabled", false)
	add_to_group("interactable")
	add_to_group("capturable")
	add_to_group("wild_volt")


func get_interaction_text(_player: CharacterBody2D) -> String:
	return "Fazer carinho em Volt" if captured else "Capturar Volt  [Q]"


func interact(player: CharacterBody2D) -> void:
	if captured:
		player.call("show_message", "Volt: Tzzzt!")
	else:
		attempt_capture(player)


func attempt_capture(player: CharacterBody2D) -> void:
	if captured or not available:
		return
	if MissionManager.stage != MissionManager.Stage.CAPTURE_VOLT:
		player.call("show_message", "Volt desaparece entre as máquinas.")
		return
	if GameManager.capture_devices <= 0:
		player.call("show_message", "Você precisa de um Dispositivo Wild.")
		return

	_play_capture_pulse()
	if _rng.randf() <= capture_chance:
		GameManager.consume_capture_device()
		captured = true
		state = State.FOLLOW
		remove_from_group("capturable")
		collision_shape.set_deferred("disabled", true)
		status_label.text = "VOLT  ⚡  SEU WILD"
		player.call("show_message", "Volt capturado! O Dispositivo Wild foi consumido.")
		MissionManager.capture_volt()
	else:
		state = State.FLEE
		_state_timer = 2.0
		player.call("show_message", "Volt escapou. O dispositivo não foi consumido.")


func _update_wild_state(delta: float) -> void:
	var player_position := GameManager.get_controlled_position()
	if state != State.FLEE and global_position.distance_to(player_position) < 145.0:
		state = State.FLEE
		_state_timer = 1.3

	match state:
		State.IDLE:
			velocity = velocity.move_toward(Vector2.ZERO, 320.0 * delta)
			if _state_timer <= 0.0:
				_wander_target = _home + Vector2.from_angle(_rng.randf_range(0.0, TAU)) * _rng.randf_range(25.0, 105.0)
				state = State.WANDER
				_state_timer = 2.3
		State.WANDER:
			velocity = global_position.direction_to(_wander_target) * 72.0
			if global_position.distance_to(_wander_target) < 8.0 or _state_timer <= 0.0:
				state = State.IDLE
				_state_timer = _rng.randf_range(0.8, 2.0)
		State.FLEE:
			velocity = player_position.direction_to(global_position) * 155.0
			if _state_timer <= 0.0:
				state = State.IDLE
				_state_timer = 0.8


func _follow_player(delta: float) -> void:
	var target := GameManager.get_controlled_position() + Vector2(-58, 48)
	var distance := global_position.distance_to(target)
	if distance > 650.0:
		global_position = target
		velocity = Vector2.ZERO
	elif distance > 58.0:
		velocity = global_position.direction_to(target) * (300.0 if distance > 220.0 else 175.0)
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
		var distance := global_position.distance_to(enemy.global_position)
		if distance <= assist_range and distance < nearest_distance:
			target = enemy
			nearest_distance = distance
	if not is_instance_valid(target):
		return
	_assist_cooldown_left = assist_cooldown
	target.call("take_damage", assist_damage, self)
	sprite.modulate = Color(0.7, 1.15, 1.7)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.18)


func use_active_ability(player: CharacterBody2D) -> bool:
	if not captured:
		player.call("show_message", "Volt ainda não faz parte do seu grupo.")
		return false
	if ability_cooldown_left > 0.0:
		player.call("show_message", "Sobrecarga do Volt recarrega em %.1fs." % ability_cooldown_left)
		return false

	var first_target := _nearest_hostile_from(global_position, ability_range, [])
	if not is_instance_valid(first_target):
		player.call("show_message", "Nenhum inimigo ao alcance da Sobrecarga.")
		return false

	var targets: Array[Node2D] = [first_target]
	while targets.size() < ability_max_targets:
		var next_target := _nearest_hostile_from(targets[-1].global_position, chain_range, targets)
		if not is_instance_valid(next_target):
			break
		targets.append(next_target)

	ability_cooldown_left = ability_cooldown
	var origin := global_position
	for index in range(targets.size()):
		var target := targets[index]
		var damage := ability_damage * (1.0 - float(index) * 0.15)
		target.call("take_damage", damage, self)
		if target.has_method("apply_stun"):
			target.call("apply_stun", ability_stun)
		_draw_lightning(origin, target.global_position, index)
		origin = target.global_position

	_play_overload_animation()
	player.call("show_message", "Volt usou SOBRECARGA em %d alvo(s)!" % targets.size())
	return true


func _nearest_hostile_from(origin: Vector2, max_range: float, excluded: Array[Node2D]) -> Node2D:
	var target: Node2D
	var nearest_distance := INF
	for enemy in get_tree().get_nodes_in_group("hostile"):
		if not enemy is Node2D or not enemy.visible or not enemy.has_method("take_damage"):
			continue
		if excluded.has(enemy):
			continue
		var distance := origin.distance_to(enemy.global_position)
		if distance <= max_range and distance < nearest_distance:
			target = enemy
			nearest_distance = distance
	return target


func _draw_lightning(from_position: Vector2, to_position: Vector2, segment_index: int) -> void:
	var parent := get_parent()
	if parent == null:
		return
	var bolt := Line2D.new()
	bolt.width = 7.0 if segment_index == 0 else 5.0
	bolt.default_color = Color(0.45, 0.9, 1.0, 0.95)
	var start := parent.to_local(from_position)
	var finish := parent.to_local(to_position)
	var mid := (start + finish) * 0.5
	var perpendicular := (finish - start).orthogonal().normalized() * (18.0 if segment_index % 2 == 0 else -18.0)
	bolt.points = PackedVector2Array([start, mid + perpendicular, finish])
	parent.add_child(bolt)
	var tween := bolt.create_tween()
	tween.tween_property(bolt, "modulate:a", 0.0, 0.28)
	tween.tween_callback(bolt.queue_free)


func _play_overload_animation() -> void:
	sprite.modulate = Color(0.7, 1.25, 1.8)
	var tween := create_tween()
	tween.tween_property(sprite, "scale", Vector2.ONE * 1.3, 0.08)
	tween.tween_property(sprite, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(sprite, "modulate", Color.WHITE, 0.22)


func _play_capture_pulse() -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE * 2.3, 0.1)
	tween.parallel().tween_property(sprite, "scale", Vector2.ONE * 0.2, 0.16)
	tween.tween_property(sprite, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(sprite, "modulate", Color.WHITE, 0.2)
