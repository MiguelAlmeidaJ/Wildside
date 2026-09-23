extends StaticBody2D

@onready var glow: Polygon2D = $Glow
@onready var label: Label = $Label

var _time := 0.0


func _ready() -> void:
	add_to_group("interactable")


func _process(delta: float) -> void:
	_time += delta
	var waiting := SideJobManager.stage == SideJobManager.Stage.HOT_CARGO_DELIVER
	glow.modulate.a = (0.52 + sin(_time * 4.0) * 0.2) if waiting else 0.16
	label.text = "DESMANCHE • ENTREGA" if waiting else "DESMANCHE"


func get_interaction_priority(_player: CharacterBody2D) -> int:
	return 122 if SideJobManager.stage == SideJobManager.Stage.HOT_CARGO_DELIVER else 72


func get_interaction_text(_player: CharacterBody2D) -> String:
	if SideJobManager.stage == SideJobManager.Stage.HOT_CARGO_DELIVER:
		return "Entregar Carga Quente"
	return "Examinar desmanche"


func interact(player: CharacterBody2D) -> void:
	var text := SideJobManager.deliver_hot_cargo(player)
	player.call("show_message", text)
