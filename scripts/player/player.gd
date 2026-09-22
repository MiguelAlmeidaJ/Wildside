extends CharacterBody2D

signal prompt_changed(text: String)
signal message_requested(text: String)

@export var speed: float = 250.0
@export var interaction_range: float = 105.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var player_camera: Camera2D = $Camera2D

var current_vehicle
var _focused_interactable: Node2D


func _ready() -> void:
	add_to_group("player")
	player_camera.make_current()


func _physics_process(_delta: float) -> void:
	if is_instance_valid(current_vehicle):
		global_position = current_vehicle.global_position
		_update_prompt()
		return

	var direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	velocity = direction * speed
	if direction != Vector2.ZERO:
		sprite.rotation = direction.angle() + PI / 2.0

	move_and_slide()
	_update_prompt()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return

	if is_instance_valid(current_vehicle):
		current_vehicle.call("request_exit")
	elif is_instance_valid(_focused_interactable):
		_focused_interactable.call("interact", self)

	get_viewport().set_input_as_handled()


func enter_vehicle(vehicle: CharacterBody2D) -> void:
	current_vehicle = vehicle
	velocity = Vector2.ZERO
	sprite.hide()
	collision_shape.set_deferred("disabled", true)
	player_camera.enabled = false
	show_message("Veículo ligado. WASD/setas para dirigir • E para sair")


func leave_vehicle(vehicle: CharacterBody2D, exit_position: Vector2) -> void:
	if current_vehicle != vehicle:
		return
	current_vehicle = null
	global_position = exit_position
	sprite.show()
	collision_shape.set_deferred("disabled", false)
	player_camera.enabled = true
	player_camera.make_current()
	show_message("Você saiu do veículo.")


func show_message(text: String) -> void:
	message_requested.emit(text)


func _update_prompt() -> void:
	if is_instance_valid(current_vehicle):
		_focused_interactable = null
		prompt_changed.emit("E  Sair do veículo")
		return

	var nearest: Node2D
	var nearest_distance := interaction_range
	for candidate in get_tree().get_nodes_in_group("interactable"):
		if not candidate is Node2D or not candidate.has_method("interact"):
			continue
		var distance := global_position.distance_to(candidate.global_position)
		if distance < nearest_distance:
			nearest = candidate
			nearest_distance = distance

	_focused_interactable = nearest
	if is_instance_valid(nearest):
		prompt_changed.emit("E  " + str(nearest.call("get_interaction_text", self)))
	else:
		prompt_changed.emit("")
