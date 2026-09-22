extends StaticBody2D

@export var cache_id := "cache_01"
@export var money_reward := 50
@export var item_id := ""
@export var item_amount := 1

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var glow: Polygon2D = $Glow

var _time := 0.0


func _ready() -> void:
	add_to_group("street_cache")
	GameManager.cache_progress_changed.connect(_on_cache_progress_changed)
	_refresh()


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	glow.modulate.a = 0.35 + sin(_time * 3.2) * 0.16


func get_interaction_priority(_player: CharacterBody2D) -> int:
	return 92


func get_interaction_text(_player: CharacterBody2D) -> String:
	return "Vasculhar esconderijo"


func interact(player: CharacterBody2D) -> void:
	if GameManager.is_cache_collected(cache_id):
		_refresh()
		return
	if not GameManager.collect_cache(cache_id):
		return

	if money_reward > 0:
		GameManager.add_money(money_reward)
	if not item_id.is_empty() and item_amount > 0:
		GameManager.add_item(item_id, item_amount)

	var extra := ""
	match item_id:
		"medkit":
			extra = " + Kit médico"
		"snack":
			extra = " + Lanche"
		"energy":
			extra = " + Energético"

	player.call(
		"show_message",
		"ESCONDERIJO ENCONTRADO • +$%d%s • %d/%d" % [
			money_reward,
			extra,
			GameManager.collected_caches.size(),
			GameManager.CACHE_TOTAL,
		]
	)
	_refresh()


func _on_cache_progress_changed(_found: int, _total: int) -> void:
	_refresh()


func _refresh() -> void:
	var collected := GameManager.is_cache_collected(cache_id)
	visible = not collected
	collision_shape.set_deferred("disabled", collected)
	if collected:
		if is_in_group("interactable"):
			remove_from_group("interactable")
	else:
		if not is_in_group("interactable"):
			add_to_group("interactable")
