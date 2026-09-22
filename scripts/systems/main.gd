extends Node2D

@onready var player = $Player
@onready var hud = $UI/HUD


func _ready() -> void:
	player.prompt_changed.connect(hud.set_prompt)
	player.message_requested.connect(hud.show_message)
	GameManager.reset_run()
	WantedManager.reset_run()
	MissionManager.reset_run()
	hud.show_message("Saia do apartamento e fale com Maya • Esta noite está diferente.")

