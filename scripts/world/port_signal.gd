extends StaticBody2D

@onready var glow: Polygon2D = $Glow
@onready var label: Label = $Label

var _time := 0.0


func _ready() -> void:
	add_to_group("interactable")


func _process(delta: float) -> void:
	_time += delta
	var active_signal := MissionManager.stage >= MissionManager.Stage.INVESTIGATE_PORT_SIGNAL and MissionManager.stage <= MissionManager.Stage.RETURN_TO_CORA
	glow.modulate.a = (0.48 + sin(_time * 4.2) * 0.2) if active_signal else 0.16
	label.text = "RELÉ • SINAL" if active_signal else "RELÉ"


func get_interaction_priority(_player: CharacterBody2D) -> int:
	if MissionManager.stage == MissionManager.Stage.INVESTIGATE_PORT_SIGNAL or MissionManager.stage == MissionManager.Stage.RECOVER_PORT_CORE:
		return 128
	return 70


func get_interaction_text(_player: CharacterBody2D) -> String:
	if MissionManager.stage == MissionManager.Stage.INVESTIGATE_PORT_SIGNAL:
		return "Analisar relé do cais"
	if MissionManager.stage == MissionManager.Stage.RECOVER_PORT_CORE:
		return "Retirar núcleo de transmissão"
	return "Examinar relé portuário"


func interact(player: CharacterBody2D) -> void:
	if MissionManager.stage == MissionManager.Stage.INVESTIGATE_PORT_SIGNAL:
		MissionManager.investigate_port_signal()
		player.call("show_message", "RELÉ: transmissão anômala detectada • movimento armado se aproxima.")
		return
	if MissionManager.stage == MissionManager.Stage.RECOVER_PORT_CORE:
		MissionManager.recover_port_core()
		player.call("show_message", "NÚCLEO RECUPERADO • leve a peça para Cora.")
		return
	if MissionManager.stage == MissionManager.Stage.CLEAR_PORT_RAIDERS:
		player.call("show_message", "O relé está bloqueado pelo tiroteio. Limpe o píer primeiro.")
		return
	player.call("show_message", "Relé portuário antigo. Nenhum canal ativo.")
