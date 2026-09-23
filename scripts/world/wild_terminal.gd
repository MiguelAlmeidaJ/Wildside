extends StaticBody2D

@onready var glow: Polygon2D = $Glow

var _time := 0.0


func _ready() -> void:
	add_to_group("interactable")


func _process(delta: float) -> void:
	_time += delta
	glow.modulate.a = 0.42 + sin(_time * 3.0) * 0.16


func get_interaction_priority(_player: CharacterBody2D) -> int:
	return 118


func get_interaction_text(_player: CharacterBody2D) -> String:
	return "Gerenciar equipe Wild"


func interact(player: CharacterBody2D) -> void:
	if WantedManager.wanted_level > 0:
		player.call("show_message", "TERMINAL WILD: Volte quando a polícia não estiver atrás de você.")
		return
	if GameManager.captured_wilds.is_empty():
		player.call("show_message", "TERMINAL WILD: Nenhum Wild registrado ainda.")
		return
	GameManager.open_wild_terminal()
