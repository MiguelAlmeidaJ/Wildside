extends StaticBody2D

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var glow: Polygon2D = $Glow
@onready var label: Label = $Label

var active := false
var money_reward := 0
var item_id := ""
var _time := 0.0


func _ready() -> void:
	deactivate_event()


func _process(delta: float) -> void:
	if not active:
		return
	_time += delta
	glow.modulate.a = 0.4 + sin(_time * 4.0) * 0.18


func activate_event(position: Vector2, reward: int, reward_item: String) -> void:
	global_position = position
	money_reward = reward
	item_id = reward_item
	active = true
	visible = true
	collision_shape.set_deferred("disabled", false)
	if not is_in_group("interactable"):
		add_to_group("interactable")
	label.text = "CARGA"


func deactivate_event() -> void:
	active = false
	visible = false
	collision_shape.set_deferred("disabled", true)
	if is_in_group("interactable"):
		remove_from_group("interactable")


func get_interaction_priority(_player: CharacterBody2D) -> int:
	return 125 if active else 0


func get_interaction_text(_player: CharacterBody2D) -> String:
	return "Abrir carga perdida"


func interact(player: CharacterBody2D) -> void:
	if not active:
		return
	if money_reward > 0:
		GameManager.add_money(money_reward)
	if not item_id.is_empty():
		GameManager.add_item(item_id, 1)

	var item_text := ""
	match item_id:
		"snack":
			item_text = " + Lanche"
		"energy":
			item_text = " + Energético"
		"medkit":
			item_text = " + Kit médico"

	player.call("show_message", "CARGA RECUPERADA • +$%d%s" % [money_reward, item_text])
	WorldEventManager.cargo_collected()
