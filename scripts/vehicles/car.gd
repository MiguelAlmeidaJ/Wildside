extends CharacterBody2D

signal durability_changed(current: float, maximum: float)

@export var maximum_speed := 430.0
@export var reverse_speed := 185.0
@export var acceleration := 430.0
@export var braking := 690.0
@export var coast_drag := 360.0
@export var steering_low_speed := 2.55
@export var steering_high_speed := 1.05
@export var steering_response := 4.6
@export var road_grip := 14.5
@export var handbrake_grip := 2.7
@export var maximum_durability := 100.0
@export var collision_damage_multiplier := 1.0
@export var pedestrian_impact_multiplier := 1.0
@export var camera_look_ahead := 82.0
@export var illegal_to_take := true
@export var requires_ownership := false
@export var theft_heat := 24.0
@export var vehicle_name := "Sedan"
@export var vehicle_kind := "car"

@onready var vehicle_camera: Camera2D = $Camera2D
@onready var engine_player: AudioStreamPlayer2D = $EngineSound
@onready var parked_blocker_shape: CollisionShape2D = $ParkedBlocker/CollisionShape2D

var driver
var current_speed := 0.0
var durability := 100.0
var was_taken := false
var _engine_playback: AudioStreamGeneratorPlayback
var _engine_phase := 0.0
var _damage_message_cooldown := 0.0
var _steering_input := 0.0


func _ready() -> void:
	add_to_group("player_vehicle")
	add_to_group("road_vehicle")
	durability = maximum_durability
	_setup_engine_audio()

	if requires_ownership:
		GameManager.vehicle_ownership_changed.connect(_on_ownership_changed)
		_set_owned_available(GameManager.personal_vehicle_unlocked)
	else:
		add_to_group("interactable")
		_set_parked_collision(true)

	durability_changed.emit(durability, maximum_durability)


func _exit_tree() -> void:
	engine_player.stop()
	_engine_playback = null
	engine_player.stream = null


func _physics_process(delta: float) -> void:
	_damage_message_cooldown = maxf(0.0, _damage_message_cooldown - delta)
	if not is_instance_valid(driver):
		current_speed = move_toward(current_speed, 0.0, coast_drag * delta)
		velocity = velocity.move_toward(Vector2.ZERO, coast_drag * delta)
		_steering_input = move_toward(_steering_input, 0.0, steering_response * delta)
		move_and_slide()
		_update_engine_audio()
		return

	var throttle := Input.get_axis("move_down", "move_up")
	var raw_steering := Input.get_axis("move_left", "move_right")
	var handbrake := Input.is_action_pressed("brake")
	_steering_input = move_toward(_steering_input, raw_steering, steering_response * delta)

	var target_speed := 0.0
	if throttle > 0.0:
		target_speed = throttle * maximum_speed
	elif throttle < 0.0:
		target_speed = throttle * reverse_speed

	var changing_direction := (
		(current_speed > 25.0 and target_speed < -1.0)
		or (current_speed < -25.0 and target_speed > 1.0)
	)
	var rate := acceleration
	if is_zero_approx(throttle):
		rate = coast_drag
	elif changing_direction:
		rate = braking
	if handbrake:
		rate = braking * 0.75

	current_speed = move_toward(current_speed, target_speed, rate * delta)

	var speed_ratio := clampf(absf(current_speed) / maxf(1.0, maximum_speed), 0.0, 1.0)
	if absf(current_speed) > 6.0:
		# A curva fica progressivamente mais suave em alta velocidade para
		# impedir mudanças bruscas de direção que faziam o carro "soltar".
		var steering_curve := speed_ratio * speed_ratio
		var steering_strength := lerpf(steering_low_speed, steering_high_speed, steering_curve)
		if handbrake:
			steering_strength *= 1.18
		rotation += _steering_input * steering_strength * signf(current_speed) * delta

	var forward := Vector2.UP.rotated(rotation)
	var lateral := forward.orthogonal()
	var lateral_speed := velocity.dot(lateral)
	var grip := handbrake_grip if handbrake else road_grip
	var lateral_retention := exp(-grip * delta)
	velocity = forward * current_speed + lateral * lateral_speed * lateral_retention
	# Pequena assistência de estabilidade em velocidades altas. Mantém o
	# veículo arcade sem transformar a direção em trilho.
	if not handbrake and speed_ratio > 0.65:
		var stability := (speed_ratio - 0.65) / 0.35
		velocity = velocity.lerp(forward * current_speed, clampf(stability * 0.18, 0.0, 0.18))

	move_and_slide()
	_handle_collisions()

	if velocity.length() > 8.0:
		var camera_target := velocity.normalized() * camera_look_ahead
		vehicle_camera.position = vehicle_camera.position.lerp(camera_target, 1.0 - exp(-4.5 * delta))
	else:
		vehicle_camera.position = vehicle_camera.position.lerp(Vector2.ZERO, 1.0 - exp(-4.5 * delta))
	_update_engine_audio()


func get_interaction_priority(_player: CharacterBody2D) -> int:
	# Veículos vencem conversas ambientais, mas objetivos de missão e
	# carteiras de civis caídos continuam tendo prioridade maior.
	return 105


func get_interaction_text(_player: CharacterBody2D) -> String:
	if requires_ownership:
		return "Entrar no seu veículo"
	if illegal_to_take and not was_taken:
		return "Roubar %s" % _vehicle_noun()
	return "Entrar no %s" % _vehicle_noun()


func interact(player: CharacterBody2D) -> void:
	if requires_ownership and not GameManager.personal_vehicle_unlocked:
		return
	if is_instance_valid(driver) or durability <= 0.0:
		return

	_set_parked_collision(false)
	driver = player
	var theft := illegal_to_take and not was_taken
	if theft:
		was_taken = true

	player.call("enter_vehicle", self)
	if theft:
		WantedManager.add_heat(theft_heat, "Roubo de %s" % _vehicle_noun())
		GameManager.emit_noise(global_position, 320.0, "vehicle_theft", self)
		player.call("show_message", "%s roubado • a polícia foi alertada." % vehicle_name)

	vehicle_camera.enabled = true
	vehicle_camera.make_current()


func request_exit() -> void:
	if not is_instance_valid(driver):
		return
	var exit_position := _find_safe_exit_position()
	if exit_position == Vector2.INF:
		driver.call("show_message", "Não há espaço seguro para sair deste lado da rua.")
		return
	var exiting_driver = driver
	driver = null
	current_speed = 0.0
	velocity = Vector2.ZERO
	_steering_input = 0.0
	vehicle_camera.enabled = false
	vehicle_camera.position = Vector2.ZERO
	_set_parked_collision(true)
	exiting_driver.call("leave_vehicle", self, exit_position)


func _set_parked_collision(parked: bool) -> void:
	collision_layer = 0 if parked else 4
	parked_blocker_shape.set_deferred("disabled", not parked)


func apply_damage(amount: float) -> void:
	durability = maxf(0.0, durability - amount)
	durability_changed.emit(durability, maximum_durability)
	if is_instance_valid(driver) and _damage_message_cooldown <= 0.0:
		driver.call("show_message", "%s: %d%%" % [vehicle_name, roundi(durability)])
		_damage_message_cooldown = 1.5
	if durability <= 0.0:
		current_speed = 0.0


func repair_full() -> void:
	durability = maximum_durability
	durability_changed.emit(durability, maximum_durability)
	if is_instance_valid(driver):
		driver.call("show_message", "%s reparado • 100%%" % vehicle_name)


func set_durability(value: float) -> void:
	durability = clampf(value, 0.0, maximum_durability)
	durability_changed.emit(durability, maximum_durability)


func get_durability_ratio() -> float:
	if maximum_durability <= 0.0:
		return 0.0
	return durability / maximum_durability


func get_speed_kmh() -> int:
	return roundi(absf(current_speed) * 0.33)


func _on_ownership_changed(unlocked: bool) -> void:
	if requires_ownership:
		_set_owned_available(unlocked)


func _set_owned_available(value: bool) -> void:
	visible = value
	set_physics_process(value)
	if value:
		if not is_in_group("interactable"):
			add_to_group("interactable")
		_set_parked_collision(true)
	else:
		if is_in_group("interactable"):
			remove_from_group("interactable")
		collision_layer = 0
		parked_blocker_shape.set_deferred("disabled", true)
		engine_player.volume_db = -80.0
		velocity = Vector2.ZERO
		current_speed = 0.0


func _handle_collisions() -> void:
	if get_slide_collision_count() == 0:
		return
	var impact_speed := absf(current_speed)
	if impact_speed > 95.0:
		apply_damage(impact_speed * 0.032 * collision_damage_multiplier)
	for index in get_slide_collision_count():
		var collider = get_slide_collision(index).get_collider()
		if collider != null and collider.has_method("react_to_vehicle"):
			collider.call("react_to_vehicle", impact_speed * pedestrian_impact_multiplier, self)
	current_speed *= 0.48 if vehicle_kind == "truck" else 0.38


func _find_safe_exit_position() -> Vector2:
	var side_distance := 74.0 if vehicle_kind == "motorcycle" else 88.0
	var rear_distance := 104.0 if vehicle_kind == "truck" else 94.0
	var offsets := [
		Vector2.RIGHT * side_distance,
		Vector2.LEFT * side_distance,
		Vector2.DOWN * rear_distance,
		Vector2.UP * rear_distance,
	]
	var exit_shape := CapsuleShape2D.new()
	exit_shape.radius = 17.0
	exit_shape.height = 40.0
	for local_offset in offsets:
		var candidate: Vector2 = global_position + local_offset.rotated(rotation)
		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = exit_shape
		query.transform = Transform2D(0.0, candidate)
		query.collision_mask = 9
		query.exclude = [get_rid()]
		if get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty():
			return candidate
	return Vector2.INF


func _vehicle_noun() -> String:
	if vehicle_kind == "motorcycle":
		return "moto"
	if vehicle_kind == "truck":
		return "caminhão"
	return "carro"


func _setup_engine_audio() -> void:
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = 22050.0
	generator.buffer_length = 0.15
	engine_player.stream = generator
	engine_player.play()
	_engine_playback = engine_player.get_stream_playback()


func _update_engine_audio() -> void:
	if _engine_playback == null:
		return
	var audible := is_instance_valid(driver) and durability > 0.0
	engine_player.volume_db = -22.0 if audible else -80.0

	var pitch_base := 0.72
	var frequency_base := 58.0
	if vehicle_kind == "motorcycle":
		pitch_base = 1.05
		frequency_base = 82.0
	elif vehicle_kind == "truck":
		pitch_base = 0.58
		frequency_base = 44.0

	engine_player.pitch_scale = pitch_base + absf(current_speed) / maxf(1.0, maximum_speed) * 0.82
	var frequency := frequency_base + absf(current_speed) * 0.12
	var frames := _engine_playback.get_frames_available()
	for _frame in frames:
		_engine_phase = fmod(_engine_phase + frequency / 22050.0, 1.0)
		var sample := sin(_engine_phase * TAU) * 0.22
		_engine_playback.push_frame(Vector2(sample, sample))
