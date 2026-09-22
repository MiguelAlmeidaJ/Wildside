extends CharacterBody2D

signal prompt_changed(text: String)
signal message_requested(text: String)

enum MotionState { IDLE, WALK, RUN }

@export var walk_speed := 230.0
@export var run_speed := 360.0
@export var acceleration := 1500.0
@export var deceleration := 1900.0
@export var camera_look_ahead := 72.0
@export var interaction_fallback_range := 128.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var player_camera: Camera2D = $Camera2D
@onready var interaction_area: Area2D = $InteractionArea

var current_vehicle
var motion_state := MotionState.IDLE
var _focused_interactable: Node2D
var _animation_time := 0.0
var _last_prompt := ""


func _ready() -> void:
	add_to_group("player")
	GameManager.register_player(self)
	player_camera.make_current()


func _physics_process(delta: float) -> void:
	if is_instance_valid(current_vehicle):
		global_position = current_vehicle.global_position
		_update_prompt()
		return

	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var running := Input.is_action_pressed("run") and direction != Vector2.ZERO
	var target_speed := run_speed if running else walk_speed
	var target_velocity := direction * target_speed
	var change_rate := acceleration if direction != Vector2.ZERO else deceleration
	velocity = velocity.move_toward(target_velocity, change_rate * delta)

	if direction != Vector2.ZERO:
		sprite.rotation = direction.angle() + PI / 2.0
		motion_state = MotionState.RUN if running else MotionState.WALK
	else:
		motion_state = MotionState.IDLE

	move_and_slide()
	_update_visual_animation(delta)
	_update_camera_look_ahead(delta)
	_update_prompt()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if is_instance_valid(current_vehicle):
			current_vehicle.call("request_exit")
		else:
			_focused_interactable = _find_nearest_interactable()
			if is_instance_valid(_focused_interactable):
				_focused_interactable.call("interact", self)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("capture") and not is_instance_valid(current_vehicle):
		var creature := _nearest_capturable()
		if is_instance_valid(creature):
			creature.call("attempt_capture", self)
		else:
			show_message("Nenhum Wild ao alcance.")
		get_viewport().set_input_as_handled()


func enter_vehicle(vehicle: CharacterBody2D) -> void:
	current_vehicle = vehicle
	velocity = Vector2.ZERO
	sprite.hide()
	interaction_area.set_deferred("monitoring", false)
	collision_shape.set_deferred("disabled", true)
	player_camera.enabled = false
	show_message("Motor ligado • Espaço freia/derrapa • E sai do veículo")


func leave_vehicle(vehicle: CharacterBody2D, exit_position: Vector2) -> void:
	if current_vehicle != vehicle:
		return
	current_vehicle = null
	global_position = exit_position
	sprite.show()
	interaction_area.set_deferred("monitoring", true)
	collision_shape.set_deferred("disabled", false)
	player_camera.enabled = true
	player_camera.position = Vector2.ZERO
	player_camera.make_current()
	show_message("Você saiu do veículo.")


func show_message(text: String) -> void:
	message_requested.emit(text)


func _update_visual_animation(delta: float) -> void:
	_animation_time += delta
	match motion_state:
		MotionState.IDLE:
			sprite.position.y = lerpf(sprite.position.y, -7.0, delta * 10.0)
			sprite.scale = Vector2.ONE * (1.0 + sin(_animation_time * 2.2) * 0.012)
		MotionState.WALK:
			sprite.position.y = -7.0 + sin(_animation_time * 10.0) * 2.0
			sprite.scale = Vector2(1.0, 1.0 + sin(_animation_time * 10.0) * 0.025)
		MotionState.RUN:
			sprite.position.y = -7.0 + sin(_animation_time * 16.0) * 3.2
			sprite.scale = Vector2(1.03, 0.97 + sin(_animation_time * 16.0) * 0.035)


func _update_camera_look_ahead(delta: float) -> void:
	var target := Vector2.ZERO
	if velocity.length() > 20.0:
		target = velocity.normalized() * camera_look_ahead
	player_camera.position = player_camera.position.lerp(target, 1.0 - exp(-5.0 * delta))


func _nearby_interactables() -> Array[Node2D]:
	var result: Array[Node2D] = []
	if interaction_area.monitoring:
		for body in interaction_area.get_overlapping_bodies():
			if body is Node2D and body.has_method("interact"):
				result.append(body)

	# Fallback para interações importantes (telefone, NPCs e veículos).
	# Evita perder o alvo quando o overlap ainda não foi atualizado no mesmo frame.
	for candidate in get_tree().get_nodes_in_group("interactable"):
		if not candidate is Node2D or not candidate.has_method("interact"):
			continue
		if result.has(candidate):
			continue
		if global_position.distance_to(candidate.global_position) <= interaction_fallback_range:
			result.append(candidate)
	return result


func _update_prompt() -> void:
	if is_instance_valid(current_vehicle):
		_focused_interactable = null
		_set_prompt("E  Sair do veículo")
		return

	var nearest := _find_nearest_interactable()

	_focused_interactable = nearest
	if is_instance_valid(nearest):
		_set_prompt("E  " + str(nearest.call("get_interaction_text", self)))
	else:
		_set_prompt("")


func _find_nearest_interactable() -> Node2D:
	var nearest: Node2D
	var nearest_distance := INF
	for candidate in _nearby_interactables():
		var distance := global_position.distance_squared_to(candidate.global_position)
		if distance < nearest_distance:
			nearest = candidate
			nearest_distance = distance
	return nearest


func _nearest_capturable() -> Node2D:
	var nearest: Node2D
	var nearest_distance := INF
	if not interaction_area.monitoring:
		return nearest
	for body in interaction_area.get_overlapping_bodies():
		if not body is Node2D or not body.is_in_group("capturable"):
			continue
		var distance := global_position.distance_squared_to(body.global_position)
		if distance < nearest_distance:
			nearest = body
			nearest_distance = distance
	return nearest


func _set_prompt(text: String) -> void:
	if text == _last_prompt:
		return
	_last_prompt = text
	prompt_changed.emit(text)
