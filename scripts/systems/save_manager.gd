extends Node

const SAVE_PATH := "user://wildside_save.json"
const SAVE_VERSION := 8
const MIN_SUPPORTED_VERSION := 5


func save_game() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false

	var player_position := Vector2.ZERO
	var respawn_position := Vector2.ZERO
	if is_instance_valid(GameManager.player):
		player_position = GameManager.player.global_position
		respawn_position = GameManager.player.call("get_respawn_point") as Vector2

	var scene := get_tree().current_scene
	var nib = scene.get_node_or_null("World/Entities/Creatures/Nib") if scene != null else null
	var volt = scene.get_node_or_null("World/Entities/Creatures/Volt") if scene != null else null
	var murno = scene.get_node_or_null("World/Entities/Creatures/Murno") if scene != null else null
	var personal_car = scene.get_node_or_null("World/Entities/Vehicles/PersonalCar") if scene != null else null

	file.store_string(JSON.stringify({
		"version": SAVE_VERSION,
		"money": GameManager.money,
		"capture_devices": GameManager.capture_devices,
		"pistol_unlocked": GameManager.pistol_unlocked,
		"pistol_magazine": GameManager.pistol_magazine,
		"pistol_reserve": GameManager.pistol_reserve,
		"medkits": GameManager.medkits,
		"snacks": GameManager.snacks,
		"energy_drinks": GameManager.energy_drinks,
		"personal_vehicle_unlocked": GameManager.personal_vehicle_unlocked,
		"collected_caches": GameManager.collected_caches,
		"personal_vehicle_durability": float(personal_car.get("durability")) if is_instance_valid(personal_car) else 100.0,
		"mission_stage": MissionManager.stage,
		"raiders_defeated": MissionManager.raiders_defeated,
		"blackout_raiders_defeated": MissionManager.blackout_raiders_defeated,
		"side_job_stage": SideJobManager.stage,
		"deliveries_completed": SideJobManager.deliveries_completed,
		"race_best_time": StreetRaceManager.best_time,
		"race_wins": StreetRaceManager.wins,
		"world_time_minutes": WorldTimeManager.game_minutes,
		"world_day_count": WorldTimeManager.day_count,
		"world_events_completed": WorldEventManager.events_completed,
		"captured_wilds": GameManager.captured_wilds,
		"active_wilds": GameManager.active_wilds,
		"player_position": [player_position.x, player_position.y],
		"respawn_position": [respawn_position.x, respawn_position.y],
		"nib_captured": bool(nib.get("captured")) if is_instance_valid(nib) else false,
		"volt_captured": bool(volt.get("captured")) if is_instance_valid(volt) else false,
		"murno_captured": bool(murno.get("captured")) if is_instance_valid(murno) else false,
	}))
	return true


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var data = JSON.parse_string(file.get_as_text())
	if not data is Dictionary:
		return false
	if int(data.get("version", 0)) < MIN_SUPPORTED_VERSION:
		return false

	GameManager.money = int(data.get("money", 0))
	GameManager.capture_devices = int(data.get("capture_devices", 0))
	GameManager.pistol_unlocked = bool(data.get("pistol_unlocked", false))
	GameManager.pistol_magazine = int(data.get("pistol_magazine", 0))
	GameManager.pistol_reserve = int(data.get("pistol_reserve", 0))
	GameManager.medkits = int(data.get("medkits", 0))
	GameManager.snacks = int(data.get("snacks", 0))
	GameManager.energy_drinks = int(data.get("energy_drinks", 0))
	GameManager.personal_vehicle_unlocked = bool(data.get("personal_vehicle_unlocked", false))
	GameManager.collected_caches.clear()
	var saved_caches: Array = data.get("collected_caches", [])
	for cache_value in saved_caches:
		var cache_id := str(cache_value)
		if not cache_id.is_empty() and not GameManager.collected_caches.has(cache_id):
			GameManager.collected_caches.append(cache_id)
	GameManager.store_open = false
	GameManager.active_store = ""
	GameManager.wild_terminal_open = false

	var saved_captured_wilds: Array[String] = []
	var captured_data: Array = data.get("captured_wilds", [])
	if not captured_data.is_empty():
		for wild_value in captured_data:
			var wild_id := str(wild_value)
			if not wild_id.is_empty() and not saved_captured_wilds.has(wild_id):
				saved_captured_wilds.append(wild_id)
	else:
		if bool(data.get("nib_captured", false)):
			saved_captured_wilds.append("nib")
		if bool(data.get("volt_captured", false)):
			saved_captured_wilds.append("volt")
		if bool(data.get("murno_captured", false)):
			saved_captured_wilds.append("murno")

	var saved_active_wilds: Array[String] = []
	var active_data: Array = data.get("active_wilds", [])
	if not active_data.is_empty():
		for wild_value in active_data:
			var wild_id := str(wild_value)
			if saved_captured_wilds.has(wild_id) and not saved_active_wilds.has(wild_id) and saved_active_wilds.size() < GameManager.MAX_ACTIVE_WILDS:
				saved_active_wilds.append(wild_id)
	else:
		for wild_id in ["nib", "volt"]:
			if saved_captured_wilds.has(wild_id) and saved_active_wilds.size() < GameManager.MAX_ACTIVE_WILDS:
				saved_active_wilds.append(wild_id)

	GameManager.set_wild_roster(saved_captured_wilds, saved_active_wilds)

	MissionManager.stage = int(data.get("mission_stage", MissionManager.Stage.TALK_TO_MAYA))
	MissionManager.raiders_defeated = int(data.get("raiders_defeated", 0))
	MissionManager.blackout_raiders_defeated = int(data.get("blackout_raiders_defeated", 0))
	SideJobManager.stage = int(data.get("side_job_stage", SideJobManager.Stage.IDLE))
	SideJobManager.deliveries_completed = int(data.get("deliveries_completed", 0))

	StreetRaceManager.state = StreetRaceManager.State.IDLE
	StreetRaceManager.current_checkpoint = 0
	StreetRaceManager.elapsed = 0.0
	StreetRaceManager.best_time = float(data.get("race_best_time", -1.0))
	StreetRaceManager.wins = int(data.get("race_wins", 0))

	WorldTimeManager.game_minutes = float(data.get("world_time_minutes", WorldTimeManager.START_MINUTES))
	WorldTimeManager.day_count = int(data.get("world_day_count", 1))
	WorldTimeManager.call("_emit_time", true)

	WorldEventManager.cancel_event()
	WorldEventManager.events_completed = int(data.get("world_events_completed", 0))
	WorldEventManager.event_history_changed.emit(WorldEventManager.events_completed)
	WorldEventManager.time_until_next = 35.0

	if is_instance_valid(GameManager.player):
		var player_position_data: Array = data.get("player_position", [])
		if player_position_data.size() >= 2:
			GameManager.player.global_position = Vector2(float(player_position_data[0]), float(player_position_data[1]))
		var respawn_data: Array = data.get("respawn_position", [])
		if respawn_data.size() >= 2:
			GameManager.player.call("set_respawn_point", Vector2(float(respawn_data[0]), float(respawn_data[1])))

	var scene := get_tree().current_scene
	if scene != null:
		var nib = scene.get_node_or_null("World/Entities/Creatures/Nib")
		var volt = scene.get_node_or_null("World/Entities/Creatures/Volt")
		var murno = scene.get_node_or_null("World/Entities/Creatures/Murno")
		var personal_car = scene.get_node_or_null("World/Entities/Vehicles/PersonalCar")
		if bool(data.get("nib_captured", false)) and is_instance_valid(nib):
			nib.call("restore_captured")
		if bool(data.get("volt_captured", false)) and is_instance_valid(volt):
			volt.call("restore_captured")
		if bool(data.get("murno_captured", false)) and is_instance_valid(murno):
			murno.call("restore_captured")
		if is_instance_valid(personal_car):
			personal_car.call("set_durability", float(data.get("personal_vehicle_durability", 100.0)))

	GameManager.money_changed.emit(GameManager.money)
	GameManager.capture_devices_changed.emit(GameManager.capture_devices)
	GameManager.weapon_changed.emit(GameManager.pistol_unlocked, GameManager.pistol_magazine, GameManager.pistol_reserve)
	GameManager.inventory_changed.emit(GameManager.medkits, GameManager.snacks, GameManager.energy_drinks)
	GameManager.store_state_changed.emit(false, "")
	GameManager.vehicle_ownership_changed.emit(GameManager.personal_vehicle_unlocked)
	GameManager.cache_progress_changed.emit(GameManager.collected_caches.size(), GameManager.CACHE_TOTAL)
	GameManager.wild_roster_changed.emit(GameManager.captured_wilds, GameManager.active_wilds)
	GameManager.wild_terminal_changed.emit(false)

	StreetRaceManager.race_state_changed.emit(StreetRaceManager.state)
	StreetRaceManager.race_progress_changed.emit(0, StreetRaceManager.CHECKPOINT_COUNT, 0.0)

	if GameManager.pistol_unlocked and is_instance_valid(GameManager.player):
		GameManager.player.call("equip_pistol", true)

	MissionManager.call("_emit_current_objective")
	SideJobManager.call("_emit_objective")
	return true
