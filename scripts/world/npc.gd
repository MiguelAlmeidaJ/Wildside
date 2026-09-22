extends CharacterBody2D

const CITIZEN_TEXTURES: Array[Texture2D] = [
	preload("res://assets/characters/citizen.svg"),
	preload("res://assets/characters/citizen_b.svg"),
	preload("res://assets/characters/citizen_c.svg"),
	preload("res://assets/characters/citizen_d.svg"),
]

enum State { IDLE, WANDER, TALK, FLEE }

@export var citizen_name := "Maya"
@export_multiline var dialogue := "A cidade está estranha hoje."
@export var mission_giver := false
@export var mission_contact := ""
@export var can_wander := true
@export var wander_radius := 85.0
@export_range(0, 3) var appearance_variant := 0
@export var appearance_tint := Color.WHITE
@export var ambient_chatter := true
@export var ambient_lines := PackedStringArray()
@export var ambient_interval_min := 7.0
@export var ambient_interval_max := 14.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var ambient_label: Label = $AmbientLabel

var state := State.IDLE
var _home := Vector2.ZERO
var _target := Vector2.ZERO
var _state_timer := 1.0
var _flee_direction := Vector2.ZERO
var _crime_cooldown := 0.0
var _ambient_timer := 4.0
var _ambient_visible_left := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("citizens")
	_home = global_position
	_rng.seed = hash(name)
	sprite.texture = CITIZEN_TEXTURES[clampi(appearance_variant, 0, CITIZEN_TEXTURES.size() - 1)]
	sprite.modulate = appearance_tint
	ambient_label.hide()
	_ambient_timer = _rng.randf_range(2.5, 7.5)
	GameManager.noise_emitted.connect(_on_noise_emitted)


func _physics_process(delta: float) -> void:
	_state_timer -= delta
	_crime_cooldown = maxf(0.0, _crime_cooldown - delta)
	_update_ambient_chatter(delta)

	match state:
		State.IDLE:
			velocity = velocity.move_toward(Vector2.ZERO, 500.0 * delta)
			if can_wander and _state_timer <= 0.0:
				_begin_wander()
		State.WANDER:
			var direction: Vector2 = global_position.direction_to(_target)
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
	_hide_ambient()
	_set_state(State.TALK, 2.5)
	var text := dialogue
	match mission_contact:
		"bruno":
			text = MissionManager.talk_to_bruno()
		"jade":
			text = MissionManager.talk_to_jade()
		_:
			if mission_giver:
				text = MissionManager.talk_to_maya()
	player.call("show_message", text if text.begins_with(citizen_name + ":") else citizen_name + ": “" + text + "”")


func react_to_vehicle(impact_speed: float, vehicle: Node2D) -> void:
	_hide_ambient()
	_flee_direction = vehicle.global_position.direction_to(global_position)
	if _flee_direction == Vector2.ZERO:
		_flee_direction = Vector2.RIGHT
	_set_state(State.FLEE, 4.5)
	if impact_speed >= 90.0 and _crime_cooldown <= 0.0:
		_crime_cooldown = 8.0
		WantedManager.add_heat(30.0, "Atropelamento")


func react_to_danger(source_position: Vector2) -> void:
	_hide_ambient()
	_flee_direction = source_position.direction_to(global_position)
	if _flee_direction == Vector2.ZERO:
		_flee_direction = Vector2.RIGHT
	_set_state(State.FLEE, 4.0)


func _on_noise_emitted(position: Vector2, radius: float, kind: String, _source: Node2D) -> void:
	if kind != "gunshot":
		return
	if global_position.distance_to(position) > radius:
		return
	react_to_danger(position)
	WantedManager.report_gunshot(true)


func _begin_wander() -> void:
	_target = _home + Vector2.from_angle(_rng.randf_range(0.0, TAU)) * _rng.randf_range(25.0, wander_radius)
	_set_state(State.WANDER, 4.0)


func _set_state(next_state: State, duration: float) -> void:
	state = next_state
	_state_timer = duration


func _update_ambient_chatter(delta: float) -> void:
	if not ambient_chatter or ambient_lines.is_empty() or state == State.FLEE or state == State.TALK:
		_hide_ambient()
		return

	if _ambient_visible_left > 0.0:
		_ambient_visible_left = maxf(0.0, _ambient_visible_left - delta)
		if _ambient_visible_left <= 0.0:
			ambient_label.hide()
			_ambient_timer = _rng.randf_range(ambient_interval_min, ambient_interval_max)
		return

	_ambient_timer -= delta
	if _ambient_timer <= 0.0 and state == State.IDLE:
		var line_index := _rng.randi_range(0, ambient_lines.size() - 1)
		ambient_label.text = ambient_lines[line_index]
		ambient_label.show()
		_ambient_visible_left = 2.2


func _hide_ambient() -> void:
	_ambient_visible_left = 0.0
	ambient_label.hide()
