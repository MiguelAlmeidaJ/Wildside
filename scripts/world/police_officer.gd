extends CharacterBody2D

@export var move_speed := 205.0
@export var arrest_range := 46.0
@export var arrest_time := 1.45
@export var contact_range := 520.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var source_car: Node2D
var arrest_progress := 0.0
var returning_to_car := false


func _ready() -> void:
	add_to_group("law_enforcement")
	WantedManager.wanted_changed.connect(_on_wanted_changed)


func _physics_process(delta: float) -> void:
	if WantedManager.wanted_level <= 0:
		_clear_arrest_progress()
		queue_free()
		return

	var player := GameManager.player
	if not is_instance_valid(player):
		return

	if is_instance_valid(player.current_vehicle):
		returning_to_car = true
		_return_to_car(delta)
		return

	returning_to_car = false
	var distance := global_position.distance_to(player.global_position)
	if distance <= contact_range:
		WantedManager.report_police_contact()

	if distance <= arrest_range:
		velocity = velocity.move_toward(Vector2.ZERO, 800.0 * delta)
		arrest_progress = minf(arrest_time, arrest_progress + delta)
		player.call("set_arrest_progress", arrest_progress / arrest_time, self)
		if arrest_progress >= arrest_time:
			player.call("arrest_by_police", self)
			arrest_progress = 0.0
			return
	else:
		_clear_arrest_progress()
		var direction: Vector2 = global_position.direction_to(player.global_position)
		velocity = velocity.move_toward(direction * move_speed, 700.0 * delta)
		if velocity.length() > 2.0:
			sprite.rotation = velocity.angle() + PI / 2.0

	move_and_slide()


func _return_to_car(delta: float) -> void:
	_clear_arrest_progress()
	if not is_instance_valid(source_car):
		queue_free()
		return

	var distance := global_position.distance_to(source_car.global_position)
	if distance <= 58.0:
		queue_free()
		return

	var direction: Vector2 = global_position.direction_to(source_car.global_position)
	velocity = velocity.move_toward(direction * move_speed, 700.0 * delta)
	if velocity.length() > 2.0:
		sprite.rotation = velocity.angle() + PI / 2.0
	move_and_slide()


func _clear_arrest_progress() -> void:
	if arrest_progress <= 0.0:
		return
	arrest_progress = 0.0
	if is_instance_valid(GameManager.player):
		GameManager.player.call("set_arrest_progress", 0.0, self)


func _on_wanted_changed(level: int, _heat: float) -> void:
	if level <= 0:
		_clear_arrest_progress()
		queue_free()
