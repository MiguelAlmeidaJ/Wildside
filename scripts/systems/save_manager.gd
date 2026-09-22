extends Node

const SAVE_PATH := "user://wildside_save.json"


func save_game() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({
		"version": 3,
		"money": GameManager.money,
		"capture_devices": GameManager.capture_devices,
		"pistol_unlocked": GameManager.pistol_unlocked,
		"pistol_magazine": GameManager.pistol_magazine,
		"pistol_reserve": GameManager.pistol_reserve,
		"mission_stage": MissionManager.stage,
	}))
	return true


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	if not data is Dictionary:
		return false
	GameManager.money = int(data.get("money", 0))
	GameManager.capture_devices = int(data.get("capture_devices", 0))
	GameManager.pistol_unlocked = bool(data.get("pistol_unlocked", false))
	GameManager.pistol_magazine = int(data.get("pistol_magazine", 0))
	GameManager.pistol_reserve = int(data.get("pistol_reserve", 0))
	MissionManager.stage = int(data.get("mission_stage", MissionManager.Stage.TALK_TO_MAYA))
	GameManager.money_changed.emit(GameManager.money)
	GameManager.capture_devices_changed.emit(GameManager.capture_devices)
	GameManager.weapon_changed.emit(GameManager.pistol_unlocked, GameManager.pistol_magazine, GameManager.pistol_reserve)
	if GameManager.pistol_unlocked and is_instance_valid(GameManager.player):
		GameManager.player.call("equip_pistol", true)
	MissionManager.call("_emit_current_objective")
	return true

