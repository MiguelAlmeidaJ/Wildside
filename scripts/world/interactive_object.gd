extends StaticBody2D

@export var action_text := "Examinar"
@export_multiline var response_text := "Nada fora do normal. Ainda."


func _ready() -> void:
	add_to_group("interactable")


func get_interaction_text(_player: CharacterBody2D) -> String:
	return action_text


func interact(player: CharacterBody2D) -> void:
	player.call("show_message", response_text)
