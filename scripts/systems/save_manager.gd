extends Node

const SAVE_PATH := "user://wildside_save.json"


func save_game() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({
		"version": 2,
		"money": GameManager.money,
		"capture_devices": GameManager.capture_devices,
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
	MissionManager.stage = int(data.get("mission_stage", MissionManager.Stage.TALK_TO_MAYA))
	GameManager.money_changed.emit(GameManager.money)
	GameManager.capture_devices_changed.emit(GameManager.capture_devices)
	MissionManager.call("_emit_current_objective")
	return true

