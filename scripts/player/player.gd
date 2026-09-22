extends CharacterBody2D

signal prompt_changed(text: String)
signal message_requested(text: String)
signal health_changed(current: float, maximum: float)
signal player_defeated

enum MotionState { IDLE, WALK, RUN }

@export var walk_speed := 230.0
@export var run_speed := 360.0
@export var acceleration := 1500.0
@export var deceleration := 1900.0
@export var camera_look_ahead := 72.0
@export var interaction_fallback_range := 128.0
@export var max_health := 100.0
@export var attack_damage := 35.0
@export var attack_range := 96.0
@export var attack_cooldown := 0.42
@export var invulnerability_time := 0.6
@export var pistol_damage := 45.0
@export var pistol_range := 620.0
@export var pistol_hit_width := 34.0
@export var pistol_cooldown := 0.28
@export var pistol_reload_time := 1.1
@export var pistol_magazine_size := 8

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var player_camera: Camera2D = $Camera2D
@onready var interaction_area: Area2D = $InteractionArea

var current_vehicle
var motion_state := MotionState.IDLE
var _focused_interactable: Node2D
var _animation_time := 0.0
var _last_prompt := ""
var health := 100.0
var facing_direction := Vector2.UP
var _attack_cooldown_left := 0.0
var _invulnerability_left := 0.0
var _spawn_position := Vector2.ZERO
var pistol_equipped := false
var _shoot_cooldown_left := 0.0
var _reload_left := 0.0


func _ready() -> void:
	add_to_group("player")
	GameManager.register_player(self)
	_spawn_position = global_position
	health = max_health
	_ensure_weapon_inputs()
	player_camera.make_current()
	health_changed.emit(health, max_health)


func _physics_process(delta: float) -> void:
	_attack_cooldown_left = maxf(0.0, _attack_cooldown_left - delta)
	_invulnerability_left = maxf(0.0, _invulnerability_left - delta)
	_shoot_cooldown_left = maxf(0.0, _shoot_cooldown_left - delta)
	if _reload_left > 0.0:
		_reload_left = maxf(0.0, _reload_left - delta)
		if _reload_left <= 0.0:
			_complete_reload()

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
		facing_direction = direction.normalized()
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
	elif event.is_action_pressed("attack") and not is_instance_valid(current_vehicle):
		perform_attack()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("wild_nib") and not is_instance_valid(current_vehicle):
		_use_wild_ability("wild_nib", "Nib")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("wild_volt") and not is_instance_valid(current_vehicle):
		_use_wild_ability("wild_volt", "Volt")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("shoot") and not is_instance_valid(current_vehicle):
		fire_pistol_at(get_global_mouse_position())
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("reload") and not is_instance_valid(current_vehicle):
		start_reload()
		get_viewport().set_input_as_handled()


func _use_wild_ability(group_name: String, wild_name: String) -> bool:
	var wild := get_tree().get_first_node_in_group(group_name)
	if not is_instance_valid(wild) or not wild.has_method("use_active_ability"):
		show_message("%s ainda não está disponível." % wild_name)
		return false
	return bool(wild.call("use_active_ability", self))


func equip_pistol(silent := false) -> void:
	if not GameManager.pistol_unlocked:
		return
	pistol_equipped = true
	_reload_left = 0.0
	if not silent:
		show_message("Pistola equipada • Clique esquerdo para atirar • R recarrega")


func fire_pistol_at(target_position: Vector2) -> bool:
	if not GameManager.pistol_unlocked or not pistol_equipped:
		show_message("Você não tem uma pistola equipada.")
		return false
	if _reload_left > 0.0:
		show_message("Recarregando...")
		return false
	if _shoot_cooldown_left > 0.0:
		return false
	if GameManager.pistol_magazine <= 0:
		show_message("Pente vazio • pressione R para recarregar.")
		return false

	var direction := global_position.direction_to(target_position)
	if direction == Vector2.ZERO:
		direction = facing_direction
	facing_direction = direction
	sprite.rotation = direction.angle() + PI / 2.0
	_shoot_cooldown_left = pistol_cooldown
	GameManager.consume_pistol_round()

	var hit_target: Node2D
	var hit_projection := INF
	for enemy in get_tree().get_nodes_in_group("hostile"):
		if not enemy is Node2D or not enemy.visible or not enemy.has_method("take_damage"):
			continue
		var offset: Vector2 = enemy.global_position - global_position
		var projection := offset.dot(direction)
		if projection <= 0.0 or projection > pistol_range:
			continue
		var perpendicular := absf(direction.cross(offset))
		if perpendicular > pistol_hit_width:
			continue
		if projection < hit_projection:
			hit_target = enemy
			hit_projection = projection

	var end_position := global_position + direction * pistol_range
	if is_instance_valid(hit_target):
		end_position = hit_target.global_position
		hit_target.call("take_damage", pistol_damage, self)
	_draw_tracer(end_position)
	return true


func start_reload() -> bool:
	if not GameManager.pistol_unlocked or not pistol_equipped:
		return false
	if _reload_left > 0.0 or GameManager.pistol_reserve <= 0 or GameManager.pistol_magazine >= pistol_magazine_size:
		return false
	_reload_left = pistol_reload_time
	show_message("Recarregando pistola...")
	return true


func _complete_reload() -> void:
	_reload_left = 0.0
	var moved := GameManager.reload_pistol(pistol_magazine_size)
	if moved > 0:
		show_message("Pistola recarregada.")


func _draw_tracer(end_position: Vector2) -> void:
	var parent := get_parent()
	if parent == null:
		return
	var tracer := Line2D.new()
	tracer.width = 3.0
	tracer.default_color = Color(1.0, 0.86, 0.48, 0.95)
	tracer.points = PackedVector2Array([
		parent.to_local(global_position),
		parent.to_local(end_position),
	])
	parent.add_child(tracer)
	var tween := tracer.create_tween()
	tween.tween_property(tracer, "modulate:a", 0.0, 0.12)
	tween.tween_callback(tracer.queue_free)


func get_companion_anchor(slot: int) -> Vector2:
	var forward := facing_direction.normalized()
	if forward == Vector2.ZERO:
		forward = Vector2.UP
	if is_instance_valid(current_vehicle) and current_vehicle.velocity.length() > 10.0:
		forward = current_vehicle.velocity.normalized()
	var side := forward.orthogonal()
	var interaction_space := _has_nearby_priority_interactable()
	var back_distance := 125.0 if interaction_space else 88.0
	var side_distance := 125.0 if interaction_space else 68.0
	var side_sign := 1.0 if slot == 0 else -1.0
	return GameManager.get_controlled_position() - forward * back_distance + side * side_distance * side_sign


func _has_nearby_priority_interactable() -> bool:
	for candidate in get_tree().get_nodes_in_group("interactable"):
		if not candidate is Node2D:
			continue
		if candidate.has_method("get_interaction_priority") and int(candidate.call("get_interaction_priority", self)) < 50:
			continue
		if global_position.distance_to(candidate.global_position) <= 155.0:
			return true
	return false


func _ensure_weapon_inputs() -> void:
	if not InputMap.has_action("shoot"):
		InputMap.add_action("shoot")
	if InputMap.action_get_events("shoot").is_empty():
		var mouse := InputEventMouseButton.new()
		mouse.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("shoot", mouse)

	if not InputMap.has_action("reload"):
		InputMap.add_action("reload")
	if InputMap.action_get_events("reload").is_empty():
		var reload_key := InputEventKey.new()
		reload_key.physical_keycode = KEY_R
		InputMap.action_add_event("reload", reload_key)


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


func perform_attack() -> bool:
	if _attack_cooldown_left > 0.0:
		return false
	_attack_cooldown_left = attack_cooldown

	var hit := false
	for enemy in get_tree().get_nodes_in_group("hostile"):
		if not enemy is Node2D or not enemy.has_method("take_damage"):
			continue
		var offset: Vector2 = enemy.global_position - global_position
		var distance := offset.length()
		if distance > attack_range or distance <= 0.01:
			continue
		if facing_direction.dot(offset.normalized()) < 0.15:
			continue
		enemy.call("take_damage", attack_damage, self)
		hit = true

	_play_attack_animation(hit)
	return hit


func take_damage(amount: float, source: Node2D = null) -> void:
	if amount <= 0.0 or _invulnerability_left > 0.0 or health <= 0.0:
		return
	if is_instance_valid(current_vehicle):
		return

	health = maxf(0.0, health - amount)
	_invulnerability_left = invulnerability_time
	health_changed.emit(health, max_health)

	if is_instance_valid(source):
		var knockback := source.global_position.direction_to(global_position)
		velocity += knockback * 155.0

	_flash_damage()
	if health <= 0.0:
		_defeat()


func heal(amount: float) -> void:
	if amount <= 0.0:
		return
	health = minf(max_health, health + amount)
	health_changed.emit(health, max_health)


func _defeat() -> void:
	player_defeated.emit()
	var penalty := mini(50, GameManager.money)
	if penalty > 0:
		GameManager.add_money(-penalty)
	global_position = _spawn_position
	velocity = Vector2.ZERO
	health = max_health
	_invulnerability_left = 1.5
	health_changed.emit(health, max_health)
	show_message("Você apagou e acordou de volta no centro.  -$%d" % penalty)


func _play_attack_animation(hit: bool) -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.18, 0.82), 0.07)
	tween.tween_property(sprite, "scale", Vector2.ONE, 0.13).set_trans(Tween.TRANS_BACK)
	if hit:
		sprite.modulate = Color(1.25, 1.15, 0.85)
		tween.parallel().tween_property(sprite, "modulate", Color.WHITE, 0.16)


func _flash_damage() -> void:
	sprite.modulate = Color(1.7, 0.55, 0.55)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.18)


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
	var nearest_priority := -INF
	var nearest_distance := INF
	for candidate in _nearby_interactables():
		var priority := 50.0
		if candidate.has_method("get_interaction_priority"):
			priority = float(candidate.call("get_interaction_priority", self))
		var distance := global_position.distance_squared_to(candidate.global_position)
		if priority > nearest_priority or (is_equal_approx(priority, nearest_priority) and distance < nearest_distance):
			nearest = candidate
			nearest_priority = priority
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
