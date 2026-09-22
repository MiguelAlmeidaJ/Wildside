extends Node2D

@onready var player = $Player
@onready var hud = $UI/HUD
@onready var nib = $World/Entities/Creatures/Nib
@onready var volt = $World/Entities/Creatures/Volt


func _ready() -> void:
	player.prompt_changed.connect(hud.set_prompt)
	player.message_requested.connect(hud.show_message)
	player.health_changed.connect(hud.set_health)
	GameManager.reset_run()
	WantedManager.reset_run()
	MissionManager.reset_run()
	hud.set_health(player.health, player.max_health)
	hud.show_message("Saia do apartamento e fale com Maya • Esta noite está diferente.")



func _process(_delta: float) -> void:
	hud.set_wild_ability("nib", nib.captured, nib.ability_cooldown_left, nib.ability_cooldown)
	hud.set_wild_ability("volt", volt.captured, volt.ability_cooldown_left, volt.ability_cooldown)
