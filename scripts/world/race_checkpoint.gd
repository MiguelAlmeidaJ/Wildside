extends Area2D

@export var is_start := false
@export var checkpoint_index := 0
@export var marker_label := "CHECKPOINT"

@onready var visual: Node2D = $Visual
@onready var label: Label = $Visual/Label
@onready var ring: Line2D = $Visual/Ring

var _time := 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	label.text = marker_label


func _process(delta: float) -> void:
	_time += delta
	var active := false
	if is_start:
		active = StreetRaceManager.state == StreetRaceManager.State.READY
	else:
		active = (
			StreetRaceManager.state == StreetRaceManager.State.RACING
			and StreetRaceManager.current_checkpoint == checkpoint_index
		)
	visual.visible = active
	if active:
		ring.rotation += delta * 1.4
		visual.scale = Vector2.ONE * (1.0 + sin(_time * 5.0) * 0.06)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player_vehicle"):
		return
	if is_start:
		if StreetRaceManager.start_race(body) and is_instance_valid(GameManager.player):
			GameManager.player.call("show_message", "CORRIDA DE RUA • siga os checkpoints!")
		return
	if StreetRaceManager.checkpoint_reached(checkpoint_index, body) and is_instance_valid(GameManager.player):
		if StreetRaceManager.state == StreetRaceManager.State.RACING:
			GameManager.player.call("show_message", "Checkpoint %d/%d" % [checkpoint_index + 1, StreetRaceManager.CHECKPOINT_COUNT])
