extends Node2D

@onready var player = $Player
@onready var hud = $UI/HUD


func _ready() -> void:
	player.prompt_changed.connect(hud.set_prompt)
	player.message_requested.connect(hud.show_message)
	player.health_changed.connect(hud.set_health)
	GameManager.reset_run()
	WantedManager.reset_run()
	MissionManager.reset_run()
	hud.set_health(player.health, player.max_health)
	hud.show_message("Saia do apartamento e fale com Maya • Esta noite está diferente.")

