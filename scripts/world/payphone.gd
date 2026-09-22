extends StaticBody2D

@export var active_action_text := "Atender telefone"
@export var idle_action_text := "Usar telefone"


func _ready() -> void:
	add_to_group("interactable")


func get_interaction_priority(_player: CharacterBody2D) -> int:
	return 115 if MissionManager.stage == MissionManager.Stage.ANSWER_PHONE else 75


func get_interaction_text(_player: CharacterBody2D) -> String:
	if MissionManager.stage == MissionManager.Stage.ANSWER_PHONE:
		return active_action_text
	return idle_action_text


func interact(player: CharacterBody2D) -> void:
	var text := MissionManager.answer_phone()
	player.call("show_message", text)
