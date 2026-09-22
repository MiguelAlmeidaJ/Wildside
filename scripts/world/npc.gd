extends CharacterBody2D

enum State { IDLE, WANDER, TALK, FLEE }

@export var citizen_name := "Maya"
@export_multiline var dialogue := "A cidade está estranha hoje."
@export var mission_giver := false
@export var mission_contact := ""
@export var can_wander := true
@export var wander_radius := 85.0

@onready var sprite: Sprite2D = $Sprite2D

var state := State.IDLE
var _home := Vector2.ZERO
var _target := Vector2.ZERO
var _state_timer := 1.0
var _flee_direction := Vector2.ZERO
var _crime_cooldown := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("citizens")
	_home = global_position
	_rng.seed = hash(name)


func _physics_process(delta: float) -> void:
	_state_timer -= delta
	_crime_cooldown = maxf(0.0, _crime_cooldown - delta)
	match state:
		State.IDLE:
			velocity = velocity.move_toward(Vector2.ZERO, 500.0 * delta)
			if can_wander and _state_timer <= 0.0:
				_begin_wander()
		State.WANDER:
			var direction := global_position.direction_to(_target)
			velocity = direction * 62.0
			if global_position.distance_to(_target) < 10.0 or _state_timer <= 0.0:
				_set_state(State.IDLE, _rng.randf_range(1.5, 3.5))
		State.TALK:
			velocity = Vector2.ZERO
			if _state_timer <= 0.0:
				_set_state(State.IDLE, 2.0)
		State.FLEE:
			velocity = _flee_direction * 210.0
			if _state_timer <= 0.0:
				_home = global_position
				_set_state(State.IDLE, 3.0)

	if velocity.length() > 1.0:
		sprite.rotation = velocity.angle() + PI / 2.0
	move_and_slide()


func get_interaction_priority(_player: CharacterBody2D) -> int:
	if mission_giver or not mission_contact.is_empty():
		return 120
	return 100


func get_interaction_text(_player: CharacterBody2D) -> String:
	return "Conversar com " + citizen_name


func interact(player: CharacterBody2D) -> void:
	_set_state(State.TALK, 2.5)
	var text := dialogue
	if mission_contact == "bruno":
		text = MissionManager.talk_to_bruno()
	elif mission_giver:
		text = MissionManager.talk_to_maya()
	player.call("show_message", text if text.begins_with(citizen_name + ":") else citizen_name + ": “" + text + "”")


func react_to_vehicle(impact_speed: float, vehicle: Node2D) -> void:
	_flee_direction = vehicle.global_position.direction_to(global_position)
	if _flee_direction == Vector2.ZERO:
		_flee_direction = Vector2.RIGHT
	_set_state(State.FLEE, 4.5)
	if impact_speed >= 90.0 and _crime_cooldown <= 0.0:
		_crime_cooldown = 8.0
		WantedManager.add_heat(30.0, "Atropelamento")


func react_to_danger(source_position: Vector2) -> void:
	_flee_direction = source_position.direction_to(global_position)
	_set_state(State.FLEE, 4.0)


func _begin_wander() -> void:
	_target = _home + Vector2.from_angle(_rng.randf_range(0.0, TAU)) * _rng.randf_range(25.0, wander_radius)
	_set_state(State.WANDER, 4.0)


func _set_state(next_state: State, duration: float) -> void:
	state = next_state
	_state_timer = duration

