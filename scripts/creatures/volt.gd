extends CharacterBody2D

enum State { IDLE, WANDER, FLEE, FOLLOW }

@export var capture_chance := 1.0

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
	if captured:
		_follow_player(delta)
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


func _play_capture_pulse() -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE * 2.3, 0.1)
	tween.parallel().tween_property(sprite, "scale", Vector2.ONE * 0.2, 0.16)
	tween.tween_property(sprite, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(sprite, "modulate", Color.WHITE, 0.2)
