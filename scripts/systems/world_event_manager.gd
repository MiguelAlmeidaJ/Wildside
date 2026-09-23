extends Node

signal event_changed(title: String, description: String, target: Vector2, active: bool)
signal event_completed(title: String, reward: int)

enum EventType {
	NONE,
	CARGO,
	RAIDERS,
}

const EVENT_ANCHORS: Array[Vector2] = [
	Vector2(-1240, 1210),
	Vector2(1240, 1210),
	Vector2(1240, -240),
]
const RAIDERS_REQUIRED := 2
const RAIDERS_COMPLETION_REWARD := 150

var current_type := EventType.NONE
var current_anchor := -1
var raiders_defeated := 0
var time_until_next := 45.0
var events_completed := 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()


func _process(delta: float) -> void:
	if current_type != EventType.NONE:
		return
	if not is_instance_valid(GameManager.player):
		return
	if WantedManager.wanted_level > 0 or GameManager.store_open:
		return
	time_until_next -= delta
	if time_until_next <= 0.0:
		start_random_event()


func reset_run() -> void:
	current_type = EventType.NONE
	current_anchor = -1
	raiders_defeated = 0
	time_until_next = 45.0
	events_completed = 0
	event_changed.emit("", "", Vector2.ZERO, false)
	_hide_event_nodes()


func start_random_event() -> bool:
	var allow_raiders := MissionManager.stage >= MissionManager.Stage.MISSION_2_COMPLETE
	var raid_chance := 0.35
	if WorldTimeManager.get_phase() == "NOITE":
		raid_chance = 0.72
	elif WorldTimeManager.get_phase() == "ENTARDECER":
		raid_chance = 0.52

	var type := EventType.CARGO
	if allow_raiders and _rng.randf() < raid_chance:
		type = EventType.RAIDERS
	var anchor_index := _rng.randi_range(0, EVENT_ANCHORS.size() - 1)
	return force_event(type, anchor_index)


func force_event(type: int, anchor_index: int = 0) -> bool:
	if current_type != EventType.NONE:
		return false
	if type != EventType.CARGO and type != EventType.RAIDERS:
		return false
	if anchor_index < 0 or anchor_index >= EVENT_ANCHORS.size():
		return false

	current_type = type
	current_anchor = anchor_index
	raiders_defeated = 0
	var target := EVENT_ANCHORS[anchor_index]

	if type == EventType.CARGO:
		var crate := _event_crate()
		if not is_instance_valid(crate):
			_reset_after_failure()
			return false
		var reward := 80 + anchor_index * 20
		var item_id := "snack"
		if anchor_index == 1:
			item_id = "energy"
		elif anchor_index == 2:
			item_id = "medkit"
		crate.call("activate_event", target, reward, item_id)
		event_changed.emit("CARGA PERDIDA", "Uma carga sem dono apareceu na cidade. Chegue antes de outra pessoa.", target, true)
	else:
		var raider1 := _event_raider("EventRaider1")
		var raider2 := _event_raider("EventRaider2")
		if not is_instance_valid(raider1) or not is_instance_valid(raider2):
			_reset_after_failure()
			return false
		raider1.call("activate_world_event", target + Vector2(-70, -35))
		raider2.call("activate_world_event", target + Vector2(75, 45))
		event_changed.emit("CONFRONTO NAS RUAS", "Dois Raiders estão intimidando moradores. Elimine a ameaça.", target, true)
	return true


func cargo_collected() -> void:
	if current_type != EventType.CARGO:
		return
	_complete_event("CARGA RECUPERADA", 0)


func enemy_defeated() -> void:
	if current_type != EventType.RAIDERS:
		return
	raiders_defeated = mini(RAIDERS_REQUIRED, raiders_defeated + 1)
	if raiders_defeated >= RAIDERS_REQUIRED:
		GameManager.add_money(RAIDERS_COMPLETION_REWARD)
		_complete_event("RUA LIBERADA", RAIDERS_COMPLETION_REWARD)
	else:
		event_changed.emit(
			"CONFRONTO NAS RUAS",
			"Elimine os Raiders.  %d/%d" % [raiders_defeated, RAIDERS_REQUIRED],
			EVENT_ANCHORS[current_anchor],
			true
		)


func cancel_event() -> void:
	if current_type == EventType.NONE:
		return
	_hide_event_nodes()
	current_type = EventType.NONE
	current_anchor = -1
	raiders_defeated = 0
	time_until_next = _rng.randf_range(55.0, 90.0)
	event_changed.emit("", "", Vector2.ZERO, false)


func _complete_event(title: String, reward: int) -> void:
	events_completed += 1
	event_completed.emit(title, reward)
	_hide_event_nodes()
	current_type = EventType.NONE
	current_anchor = -1
	raiders_defeated = 0
	time_until_next = _rng.randf_range(65.0, 105.0)
	event_changed.emit("", "", Vector2.ZERO, false)


func _reset_after_failure() -> void:
	current_type = EventType.NONE
	current_anchor = -1
	time_until_next = 20.0


func _event_crate() -> Node:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	return scene.get_node_or_null("World/Props/EventCargo")


func _event_raider(node_name: String) -> Node:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	return scene.get_node_or_null("World/Entities/Enemies/" + node_name)


func _hide_event_nodes() -> void:
	var crate := _event_crate()
	if is_instance_valid(crate):
		crate.call("deactivate_event")
	for node_name in ["EventRaider1", "EventRaider2"]:
		var raider := _event_raider(node_name)
		if is_instance_valid(raider):
			raider.call("deactivate_world_event")
