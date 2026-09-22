extends Node2D

@onready var player = $Player
@onready var hud = $HUD


func _ready() -> void:
	player.prompt_changed.connect(hud.set_prompt)
	player.message_requested.connect(hud.show_message)
	hud.show_message("Explore a cidade • WASD/setas para andar • E para interagir")
