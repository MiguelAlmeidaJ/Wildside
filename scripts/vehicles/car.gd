extends CharacterBody2D

signal durability_changed(current: float, maximum: float)

@export var maximum_speed := 520.0
@export var reverse_speed := 230.0
@export var acceleration := 520.0
@export var braking := 760.0
@export var steering_speed := 2.3
@export var maximum_durability := 100.0
@export var illegal_to_take := true
@export var requires_ownership := false
@export var vehicle_name := "Sedan"

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


func _ready() -> void:
	add_to_group("player_vehicle")
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
		current_speed = move_toward(current_speed, 0.0, braking * delta)
		velocity = velocity.move_toward(Vector2.ZERO, braking * delta)
		move_and_slide()
		_update_engine_audio()
		return

	var throttle := Input.get_axis("move_down", "move_up")
	var steering := Input.get_axis("move_left", "move_right")
	var handbrake := Input.is_action_pressed("brake")
	var target_speed := 0.0
	if throttle > 0.0:
		target_speed = throttle * maximum_speed
	elif throttle < 0.0:
		target_speed = throttle * reverse_speed

	var rate := acceleration if throttle != 0.0 else braking
	if handbrake:
		target_speed *= 0.72
		rate = braking * 1.35
	current_speed = move_toward(current_speed, target_speed, rate * delta)

	if absf(current_speed) > 8.0:
		var speed_ratio := clampf(absf(current_speed) / maximum_speed, 0.25, 1.0)
		var drift_turn := 1.35 if handbrake else 1.0
		rotation += steering * steering_speed * drift_turn * speed_ratio * signf(current_speed) * delta

	var desired_velocity := Vector2.UP.rotated(rotation) * current_speed
	var grip := 3.5 if handbrake else 10.0
	velocity = velocity.lerp(desired_velocity, 1.0 - exp(-grip * delta))
	move_and_slide()
	_handle_collisions()
	vehicle_camera.position = vehicle_camera.position.lerp(velocity.normalized() * 95.0, 1.0 - exp(-4.0 * delta))
	_update_engine_audio()


func get_interaction_priority(_player: CharacterBody2D) -> int:
	return 55


func get_interaction_text(_player: CharacterBody2D) -> String:
	if requires_ownership:
		return "Entrar no seu veículo"
	return "Roubar veículo" if illegal_to_take and not was_taken else "Entrar no veículo"


func interact(player: CharacterBody2D) -> void:
	if requires_ownership and not GameManager.personal_vehicle_unlocked:
		return
	if is_instance_valid(driver) or durability <= 0.0:
		return
	_set_parked_collision(false)
	driver = player
	if illegal_to_take and not was_taken:
		was_taken = true
		WantedManager.add_heat(20.0, "Roubo de veículo")
	player.call("enter_vehicle", self)
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
	vehicle_camera.enabled = false
	vehicle_camera.position = Vector2.ZERO
	_set_parked_collision(true)
	exiting_driver.call("leave_vehicle", self, exit_position)


func _set_parked_collision(parked: bool) -> void:
	# O carro estacionado usa um StaticBody2D separado. Isso mantém o veículo
	# sólido para o player sem colocar dois CharacterBody2D se empurrando.
	collision_layer = 0 if parked else 4
	parked_blocker_shape.set_deferred("disabled", not parked)


func apply_damage(amount: float) -> void:
	durability = maxf(0.0, durability - amount)
	durability_changed.emit(durability, maximum_durability)
	if is_instance_valid(driver) and _damage_message_cooldown <= 0.0:
		driver.call("show_message", "Veículo: %d%%" % roundi(durability))
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
		velocity = Vector2.ZERO
		current_speed = 0.0


func _handle_collisions() -> void:
	if get_slide_collision_count() == 0:
		return
	var impact_speed := absf(current_speed)
	if impact_speed > 100.0:
		apply_damage(impact_speed * 0.035)
	for index in get_slide_collision_count():
		var collider = get_slide_collision(index).get_collider()
		if collider != null and collider.has_method("react_to_vehicle"):
			collider.call("react_to_vehicle", impact_speed, self)
	current_speed *= 0.42


func _find_safe_exit_position() -> Vector2:
	var offsets := [
		Vector2.RIGHT * 88.0,
		Vector2.LEFT * 88.0,
		Vector2.DOWN * 94.0,
		Vector2.UP * 94.0,
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
	engine_player.volume_db = -23.0 if audible else -80.0
	engine_player.pitch_scale = 0.75 + absf(current_speed) / maximum_speed * 0.85
	var frequency := 58.0 + absf(current_speed) * 0.12
	var frames := _engine_playback.get_frames_available()
	for _frame in frames:
		_engine_phase = fmod(_engine_phase + frequency / 22050.0, 1.0)
		var sample := sin(_engine_phase * TAU) * 0.22
		_engine_playback.push_frame(Vector2(sample, sample))
