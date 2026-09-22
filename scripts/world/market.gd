extends StaticBody2D

@onready var glow: Polygon2D = $Glow

var _time := 0.0


func _ready() -> void:
	add_to_group("interactable")


func _process(delta: float) -> void:
	_time += delta
	glow.modulate.a = 0.55 + sin(_time * 3.4) * 0.18


func get_interaction_priority(_player: CharacterBody2D) -> int:
	return 108


func get_interaction_text(_player: CharacterBody2D) -> String:
	if SideJobManager.stage == SideJobManager.Stage.PICKUP_PACKAGE:
		return "Retirar encomenda • Mercado 24H"
	return "Entrar no Mercado 24H"


func interact(player: CharacterBody2D) -> void:
	if WantedManager.wanted_level > 0:
		player.call("show_message", "MERCADO 24H: Porta trancada enquanto a polícia está atrás de você.")
		return

	if SideJobManager.stage == SideJobManager.Stage.PICKUP_PACKAGE:
		if SideJobManager.pickup_package():
			player.call("show_message", "Encomenda retirada. Leve o pacote para Vera no Residencial.")
			return

	GameManager.open_store("market24", "MERCADO 24H")
