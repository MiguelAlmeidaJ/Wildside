extends StaticBody2D

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var core: Polygon2D = $Core
@onready var ring: Line2D = $Ring
@onready var label: Label = $Label

var active := false
var _time := 0.0


func _ready() -> void:
	_set_active(false)


func _process(delta: float) -> void:
	_time += delta
	var should_be_active := MissionManager.stage == MissionManager.Stage.INVESTIGATE_BLACKOUT
	if should_be_active != active:
		_set_active(should_be_active)

	if not active:
		return

	var pulse := 1.0 + sin(_time * 4.5) * 0.12
	core.scale = Vector2.ONE * pulse
	ring.rotation += delta * 0.7
	ring.modulate.a = 0.45 + sin(_time * 3.0) * 0.18


func get_interaction_priority(_player: CharacterBody2D) -> int:
	return 130 if active else 0


func get_interaction_text(_player: CharacterBody2D) -> String:
	return "Examinar distorção elétrica"


func interact(player: CharacterBody2D) -> void:
	if not active:
		return
	MissionManager.investigate_blackout()
	player.call("show_message", "O sinal explode em estática. Pessoas armadas surgem das ruas laterais.")
	_set_active(false)


func _set_active(value: bool) -> void:
	active = value
	visible = value
	collision_shape.set_deferred("disabled", not value)
	if value:
		if not is_in_group("interactable"):
			add_to_group("interactable")
	else:
		if is_in_group("interactable"):
			remove_from_group("interactable")
