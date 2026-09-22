extends StaticBody2D

@export var action_text := "Examinar"
@export_multiline var response_text := "Nada fora do normal. Ainda."
@export var mission_phone := false


func _ready() -> void:
	add_to_group("interactable")


func get_interaction_text(_player: CharacterBody2D) -> String:
	return action_text


func interact(player: CharacterBody2D) -> void:
	var text := MissionManager.answer_phone() if mission_phone else response_text
	player.call("show_message", text)
