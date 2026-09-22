extends CharacterBody2D

@export var maximum_speed: float = 520.0
@export var reverse_speed: float = 230.0
@export var acceleration: float = 520.0
@export var braking: float = 700.0
@export var steering_speed: float = 2.3

@onready var vehicle_camera: Camera2D = $Camera2D

var driver
var current_speed := 0.0


func _ready() -> void:
	add_to_group("interactable")


func _physics_process(delta: float) -> void:
	if not is_instance_valid(driver):
		current_speed = move_toward(current_speed, 0.0, braking * delta)
		velocity = Vector2.UP.rotated(rotation) * current_speed
		move_and_slide()
		return

	var throttle := Input.get_axis("move_down", "move_up")
	var steering := Input.get_axis("move_left", "move_right")
	var target_speed := 0.0
	if throttle > 0.0:
		target_speed = throttle * maximum_speed
	elif throttle < 0.0:
		target_speed = throttle * reverse_speed

	var rate := acceleration if throttle != 0.0 else braking
	current_speed = move_toward(current_speed, target_speed, rate * delta)

	if absf(current_speed) > 8.0:
		var speed_ratio := clampf(absf(current_speed) / maximum_speed, 0.25, 1.0)
		rotation += steering * steering_speed * speed_ratio * signf(current_speed) * delta

	velocity = Vector2.UP.rotated(rotation) * current_speed
	move_and_slide()
	if get_slide_collision_count() > 0:
		current_speed *= 0.35


func get_interaction_text(_player: CharacterBody2D) -> String:
	return "Entrar no veículo"


func interact(player: CharacterBody2D) -> void:
	if is_instance_valid(driver):
		return
	driver = player
	player.call("enter_vehicle", self)
	vehicle_camera.enabled = true
	vehicle_camera.make_current()


func request_exit() -> void:
	if not is_instance_valid(driver):
		return
	var exiting_driver = driver
	driver = null
	current_speed = 0.0
	vehicle_camera.enabled = false
	var exit_position := global_position + Vector2.RIGHT.rotated(rotation) * 82.0
	exiting_driver.call("leave_vehicle", self, exit_position)
