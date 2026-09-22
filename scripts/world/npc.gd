extends CharacterBody2D

@export var citizen_name := "Maya"
@export_multiline var dialogue := "A cidade é pequena, mas já tem ruas suficientes para um test-drive."


func _ready() -> void:
	add_to_group("interactable")


func get_interaction_text(_player: CharacterBody2D) -> String:
	return "Conversar com " + citizen_name


func interact(player: CharacterBody2D) -> void:
	player.call("show_message", citizen_name + ": “" + dialogue + "”")
