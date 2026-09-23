extends CharacterBody2D

const CITIZEN_TEXTURES: Array[Texture2D] = [
	preload("res://assets/characters/citizen.svg"),
	preload("res://assets/characters/citizen_b.svg"),
	preload("res://assets/characters/citizen_c.svg"),
	preload("res://assets/characters/citizen_d.svg"),
]

enum State { IDLE, WANDER, TALK, FLEE, FIGHT, DOWNED }

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
@export var max_health := 70.0
@export_range(0.0, 1.0) var fight_chance := 0.42
@export var fight_speed := 150.0
@export var attack_damage := 9.0
@export var attack_range := 58.0
@export var attack_cooldown := 0.9
@export var wallet_min := 6
@export var wallet_max := 38

@onready var sprite: Sprite2D = $Sprite2D
@onready var ambient_label: Label = $AmbientLabel
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var state := State.IDLE
var health := 70.0
var _home := Vector2.ZERO
var _target := Vector2.ZERO
var _state_timer := 1.0
var _flee_direction := Vector2.ZERO
var _crime_cooldown := 0.0
var _attack_cooldown_left := 0.0
var _ambient_timer := 4.0
var _ambient_visible_left := 0.0
var _stun_left := 0.0
var _wallet_cash := 0
var _wallet_looted := false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("citizens")
	add_to_group("civilian_damageable")
	_home = global_position
	_rng.seed = hash(name)
	health = max_health
	_wallet_cash = _rng.randi_range(wallet_min, maxi(wallet_min, wallet_max))
	sprite.texture = CITIZEN_TEXTURES[clampi(appearance_variant, 0, CITIZEN_TEXTURES.size() - 1)]
	sprite.modulate = appearance_tint
	ambient_label.hide()
	_ambient_timer = _rng.randf_range(2.5, 7.5)
	GameManager.noise_emitted.connect(_on_noise_emitted)


func _physics_process(delta: float) -> void:
	_state_timer -= delta
	_crime_cooldown = maxf(0.0, _crime_cooldown - delta)
	_attack_cooldown_left = maxf(0.0, _attack_cooldown_left - delta)
	_stun_left = maxf(0.0, _stun_left - delta)
	_update_ambient_chatter(delta)

	if state == State.DOWNED:
		velocity = Vector2.ZERO
		if _state_timer <= 0.0:
			_recover_from_downed()
		return

	if _stun_left > 0.0:
		velocity = velocity.move_toward(Vector2.ZERO, 850.0 * delta)
		move_and_slide()
		return

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
		State.FIGHT:
			_update_fight_state(delta)

	if velocity.length() > 1.0:
		sprite.rotation = velocity.angle() + PI / 2.0
	move_and_slide()


func get_interaction_priority(_player: CharacterBody2D) -> int:
	if state == State.DOWNED and not _is_essential():
		return 110
	if mission_giver or not mission_contact.is_empty():
		return 120
	return 100


func get_interaction_text(_player: CharacterBody2D) -> String:
	if state == State.DOWNED:
		if _is_essential():
			return "%s está se recuperando" % citizen_name
		if not _wallet_looted:
			return "Pegar dinheiro de %s" % citizen_name
		return "%s está caído" % citizen_name
	if state == State.FIGHT:
		return "%s está reagindo" % citizen_name
	return "Conversar com " + citizen_name


func interact(player: CharacterBody2D) -> void:
	if state == State.DOWNED:
		if _is_essential():
			player.call("show_message", "%s está se recuperando." % citizen_name)
			return
		if _wallet_looted:
			player.call("show_message", "Você já pegou o dinheiro dessa pessoa.")
			return
		_wallet_looted = true
		GameManager.add_money(_wallet_cash)
		WantedManager.add_heat(20.0, "Roubo de pedestre")
		player.call("show_message", "Você pegou $%d • testemunhas podem chamar a polícia." % _wallet_cash)
		return

	if state == State.FIGHT:
		player.call("show_message", "%s não quer conversar agora." % citizen_name)
		return

	_hide_ambient()
	_set_state(State.TALK, 2.5)
	var text := dialogue
	match mission_contact:
		"bruno":
			text = MissionManager.talk_to_bruno()
		"jade":
			text = MissionManager.talk_to_jade()
		"cora":
			text = MissionManager.talk_to_cora()
		"port_job":
			text = SideJobManager.talk_to_malik()
		"port_pickup":
			text = SideJobManager.talk_to_dante()
		"rico":
			text = SideJobManager.talk_to_rico()
		"vera":
			text = SideJobManager.talk_to_vera()
		"race":
			text = StreetRaceManager.talk_to_nando()
		_:
			if mission_giver:
				text = MissionManager.talk_to_maya()
	player.call("show_message", text if text.begins_with(citizen_name + ":") else citizen_name + ": “" + text + "”")


func take_damage(amount: float, source: Node2D = null) -> void:
	if amount <= 0.0 or state == State.DOWNED:
		return

	_hide_ambient()
	var player_aggression := _is_player_aggression(source)
	if player_aggression and _crime_cooldown <= 0.0:
		_crime_cooldown = 5.0
		if is_instance_valid(source) and source.is_in_group("player_vehicle"):
			WantedManager.add_heat(30.0, "Atropelamento")
		else:
			WantedManager.add_heat(22.0, "Agressão a pedestre")
			GameManager.emit_noise(global_position, 260.0, "assault", self)

	health = maxf(0.0, health - amount)
	sprite.modulate = Color(1.5, 0.7, 0.7)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", appearance_tint, 0.18)

	if health <= 0.0:
		if _is_essential():
			health = maxf(15.0, max_health * 0.25)
			_begin_flee_from(source)
		else:
			_enter_downed()
		return

	if player_aggression:
		if _rng.randf() <= fight_chance and not _is_essential():
			_begin_fight()
		else:
			_begin_flee_from(source)


func apply_stun(duration: float) -> void:
	if state == State.DOWNED:
		return
	_stun_left = maxf(_stun_left, duration)


func apply_knockback(direction: Vector2, strength: float) -> void:
	if state == State.DOWNED:
		return
	velocity += direction.normalized() * minf(strength, 180.0)


func react_to_vehicle(impact_speed: float, vehicle: Node2D) -> void:
	if state == State.DOWNED:
		return
	_hide_ambient()
	if impact_speed < 55.0:
		_begin_flee_from(vehicle)
		return
	var damage := clampf((impact_speed - 35.0) * 0.48, 10.0, 95.0)
	take_damage(damage, vehicle)


func react_to_danger(source_position: Vector2) -> void:
	if state == State.DOWNED or state == State.FIGHT:
		return
	_hide_ambient()
	_flee_direction = source_position.direction_to(global_position)
	if _flee_direction == Vector2.ZERO:
		_flee_direction = Vector2.RIGHT
	_set_state(State.FLEE, 4.0)


func _on_noise_emitted(position: Vector2, radius: float, kind: String, source: Node2D) -> void:
	if state == State.DOWNED or source == self:
		return
	if global_position.distance_to(position) > radius:
		return
	if kind == "gunshot":
		react_to_danger(position)
		WantedManager.report_gunshot(true)
	elif kind == "vehicle_theft" or kind == "assault":
		react_to_danger(position)


func _update_fight_state(delta: float) -> void:
	var player: CharacterBody2D = GameManager.player
	if not is_instance_valid(player):
		_end_fight()
		return
	if is_instance_valid(player.current_vehicle):
		_begin_flee_from(player.current_vehicle)
		return

	var distance := global_position.distance_to(player.global_position)
	if distance > 430.0:
		_end_fight()
		return
	if distance <= attack_range:
		velocity = velocity.move_toward(Vector2.ZERO, 720.0 * delta)
		if _attack_cooldown_left <= 0.0:
			_attack_cooldown_left = attack_cooldown
			player.call("take_damage", attack_damage, self)
			var punch := create_tween()
			punch.tween_property(sprite, "scale", Vector2(1.12, 0.9), 0.07)
			punch.tween_property(sprite, "scale", Vector2.ONE, 0.12)
	else:
		var direction := global_position.direction_to(player.global_position)
		velocity = direction * fight_speed


func _begin_fight() -> void:
	_set_state(State.FIGHT, 12.0)
	if not is_in_group("hostile"):
		add_to_group("hostile")
	ambient_label.text = "Ei! Vem então!"
	ambient_label.show()
	_ambient_visible_left = 1.2


func _end_fight() -> void:
	if is_in_group("hostile"):
		remove_from_group("hostile")
	_home = global_position
	_set_state(State.IDLE, 2.0)


func _begin_flee_from(source: Node2D) -> void:
	if is_in_group("hostile"):
		remove_from_group("hostile")
	if is_instance_valid(source):
		_flee_direction = source.global_position.direction_to(global_position)
	else:
		_flee_direction = Vector2.RIGHT
	if _flee_direction == Vector2.ZERO:
		_flee_direction = Vector2.RIGHT
	_set_state(State.FLEE, 5.0)


func _enter_downed() -> void:
	if is_in_group("hostile"):
		remove_from_group("hostile")
	state = State.DOWNED
	_state_timer = 12.0
	velocity = Vector2.ZERO
	sprite.rotation += PI * 0.5
	sprite.modulate = appearance_tint.darkened(0.18)
	collision_shape.set_deferred("disabled", true)
	ambient_label.text = "CAÍDO"
	ambient_label.show()
	_ambient_visible_left = 0.0


func _recover_from_downed() -> void:
	health = maxf(28.0, max_health * 0.45)
	state = State.FLEE
	_state_timer = 5.0
	sprite.rotation = 0.0
	sprite.modulate = appearance_tint
	collision_shape.set_deferred("disabled", false)
	ambient_label.hide()
	_flee_direction = global_position.direction_to(_home)
	if _flee_direction == Vector2.ZERO:
		_flee_direction = Vector2.RIGHT


func _is_player_aggression(source: Node2D) -> bool:
	if not is_instance_valid(source):
		return false
	if source == GameManager.player:
		return true
	return source.is_in_group("player_vehicle")


func _is_essential() -> bool:
	return mission_giver or not mission_contact.is_empty()


func _begin_wander() -> void:
	_target = _home + Vector2.from_angle(_rng.randf_range(0.0, TAU)) * _rng.randf_range(25.0, wander_radius)
	_set_state(State.WANDER, 4.0)


func _set_state(next_state: State, duration: float) -> void:
	state = next_state
	_state_timer = duration


func _update_ambient_chatter(delta: float) -> void:
	if not ambient_chatter or ambient_lines.is_empty() or state == State.FLEE or state == State.TALK or state == State.FIGHT or state == State.DOWNED:
		if state != State.DOWNED:
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
	if state != State.DOWNED:
		ambient_label.hide()
