extends Node

const LOD_INTERVAL := 0.25
const DEBUG_INTERVAL := 0.50

const CITIZEN_SLEEP_DISTANCE := 1280.0
const CITIZEN_WAKE_DISTANCE := 1080.0
const TRAFFIC_SLEEP_DISTANCE := 1450.0
const TRAFFIC_WAKE_DISTANCE := 1180.0
const RAIDER_SLEEP_DISTANCE := 1550.0
const RAIDER_WAKE_DISTANCE := 1280.0
const NEARBY_METRIC_DISTANCE := 900.0

var _lod_timer: Timer
var _debug_timer: Timer
var _debug_layer: CanvasLayer
var _debug_label: Label
var _debug_visible := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_lod_timer = Timer.new()
	_lod_timer.wait_time = LOD_INTERVAL
	_lod_timer.one_shot = false
	add_child(_lod_timer)
	_lod_timer.timeout.connect(_update_lod)
	_lod_timer.start()

	_debug_timer = Timer.new()
	_debug_timer.wait_time = DEBUG_INTERVAL
	_debug_timer.one_shot = false
	add_child(_debug_timer)
	_debug_timer.timeout.connect(_update_debug_metrics)
	_debug_timer.start()

	_create_debug_overlay()
	_debug_visible = OS.is_debug_build()
	_debug_layer.visible = _debug_visible
	call_deferred("_update_lod")
	call_deferred("_update_debug_metrics")


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode != KEY_F3 and key_event.physical_keycode != KEY_F3:
		return

	_debug_visible = not _debug_visible
	_debug_layer.visible = _debug_visible
	if _debug_visible:
		_update_debug_metrics()


func _update_lod() -> void:
	if not is_instance_valid(GameManager.player):
		return

	var player_position := GameManager.get_controlled_position()
	_apply_group_lod(&"citizens", player_position, CITIZEN_SLEEP_DISTANCE, CITIZEN_WAKE_DISTANCE)
	_apply_group_lod(&"ambient_traffic", player_position, TRAFFIC_SLEEP_DISTANCE, TRAFFIC_WAKE_DISTANCE)
	_apply_group_lod(&"performance_raider", player_position, RAIDER_SLEEP_DISTANCE, RAIDER_WAKE_DISTANCE)


func _apply_group_lod(
	group_name: StringName,
	player_position: Vector2,
	sleep_distance: float,
	wake_distance: float
) -> void:
	for entity in get_tree().get_nodes_in_group(group_name):
		if not (entity is Node2D) or not entity.is_inside_tree():
			continue

		var sleeping := bool(entity.get_meta(&"_performance_sleeping", false))
		var distance := (entity as Node2D).global_position.distance_to(player_position)

		if sleeping and distance <= wake_distance:
			_set_entity_sleep(entity, false, player_position)
		elif not sleeping and distance >= sleep_distance:
			_set_entity_sleep(entity, true, player_position)


func _set_entity_sleep(entity: Node, sleeping: bool, player_position: Vector2) -> void:
	entity.set_meta(&"_performance_sleeping", sleeping)

	if entity.has_method("set_performance_sleep"):
		entity.call("set_performance_sleep", sleeping, player_position)
		return

	if entity is CharacterBody2D and sleeping:
		(entity as CharacterBody2D).velocity = Vector2.ZERO
	entity.set_physics_process(not sleeping)


func _create_debug_overlay() -> void:
	_debug_layer = CanvasLayer.new()
	_debug_layer.layer = 100
	add_child(_debug_layer)

	_debug_label = Label.new()
	_debug_label.position = Vector2(14, 14)
	_debug_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_debug_label.add_theme_font_size_override("font_size", 14)
	_debug_label.add_theme_constant_override("outline_size", 6)
	_debug_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.88))
	_debug_layer.add_child(_debug_label)


func _update_debug_metrics() -> void:
	if not _debug_visible or not is_instance_valid(_debug_label):
		return

	var citizen_counts := _count_processing(&"citizens")
	var traffic_counts := _count_processing(&"ambient_traffic")
	var police_count := _count_visible_police()
	var nearby_count := _count_nearby_entities()

	_debug_label.text = (
		"PERF  [F3]\n"
		+ "FPS %d\n" % roundi(Engine.get_frames_per_second())
		+ "NPCs ativos %d / %d\n" % [citizen_counts.x, citizen_counts.y]
		+ "Trânsito ativo %d / %d\n" % [traffic_counts.x, traffic_counts.y]
		+ "Polícia %d\n" % police_count
		+ "Entidades próximas %d" % nearby_count
	)


func _count_processing(group_name: StringName) -> Vector2i:
	var active := 0
	var total := 0
	for entity in get_tree().get_nodes_in_group(group_name):
		if not (entity is Node):
			continue
		total += 1
		if entity.is_physics_processing():
			active += 1
	return Vector2i(active, total)


func _count_visible_police() -> int:
	var ids := {}
	for group_name in [&"police_unit", &"law_enforcement"]:
		for entity in get_tree().get_nodes_in_group(group_name):
			if not (entity is Node2D) or not entity.visible:
				continue
			ids[entity.get_instance_id()] = true
	return ids.size()


func _count_nearby_entities() -> int:
	if not is_instance_valid(GameManager.player):
		return 0

	var player_position := GameManager.get_controlled_position()
	var ids := {}
	for group_name in [&"citizens", &"ambient_traffic", &"performance_raider", &"police_unit", &"law_enforcement"]:
		for entity in get_tree().get_nodes_in_group(group_name):
			if not (entity is Node2D) or not entity.visible:
				continue
			if entity.global_position.distance_to(player_position) <= NEARBY_METRIC_DISTANCE:
				ids[entity.get_instance_id()] = true
	return ids.size()
