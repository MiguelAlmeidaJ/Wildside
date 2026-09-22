extends StaticBody2D

@onready var light: Polygon2D = $Light

var _time := 0.0


func _ready() -> void:
	add_to_group("interactable")


func _process(delta: float) -> void:
	_time += delta
	light.modulate.a = 0.45 + sin(_time * 2.2) * 0.12


func get_interaction_priority(_player: CharacterBody2D) -> int:
	return 110


func get_interaction_text(_player: CharacterBody2D) -> String:
	return "Descansar e salvar no apartamento"


func interact(player: CharacterBody2D) -> void:
	if WantedManager.wanted_level > 0:
		player.call("show_message", "Você não pode entrar no apartamento enquanto está sendo procurado.")
		return

	player.call("heal", 9999.0)
	player.call("set_respawn_point", global_position + Vector2(0, 72))
	var saved := SaveManager.save_game()
	if saved:
		player.call("show_message", "Apartamento • vida restaurada • progresso salvo.")
	else:
		player.call("show_message", "Apartamento • vida restaurada, mas o save falhou.")
