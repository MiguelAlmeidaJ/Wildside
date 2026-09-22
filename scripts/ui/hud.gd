extends CanvasLayer

@onready var prompt_label: Label = %PromptLabel
@onready var message_panel: PanelContainer = %MessagePanel
@onready var message_label: Label = %MessageLabel
@onready var message_timer: Timer = $MessageTimer
@onready var wanted_label: Label = %WantedLabel
@onready var money_label: Label = %MoneyLabel
@onready var mission_panel: PanelContainer = %MissionPanel
@onready var mission_title: Label = %MissionTitle
@onready var mission_description: Label = %MissionDescription

var _objective_text := ""
var _objective_target := Vector2.ZERO
var _objective_has_target := false


func _ready() -> void:
	MissionManager.objective_changed.connect(_on_objective_changed)
	MissionManager.mission_completed.connect(_on_mission_completed)
	WantedManager.wanted_changed.connect(_on_wanted_changed)
	WantedManager.crime_committed.connect(_on_crime_committed)
	GameManager.money_changed.connect(_on_money_changed)
	_on_wanted_changed(WantedManager.wanted_level, WantedManager.heat)
	_on_money_changed(GameManager.money)


func _process(_delta: float) -> void:
	if _objective_has_target:
		var distance := GameManager.get_controlled_position().distance_to(_objective_target)
		mission_description.text = "%s\n[ %d m ]" % [_objective_text, roundi(distance / 4.0)]
	else:
		mission_description.text = _objective_text


func set_prompt(text: String) -> void:
	prompt_label.text = text
	prompt_label.visible = not text.is_empty()


func show_message(text: String) -> void:
	message_label.text = text
	message_panel.show()
	message_timer.start()


func _on_objective_changed(title: String, description: String, target: Vector2, has_target: bool) -> void:
	mission_title.text = title
	_objective_text = description
	_objective_target = target
	_objective_has_target = has_target
	mission_panel.show()


func _on_wanted_changed(level: int, heat: float) -> void:
	wanted_label.text = "%s%s  %02d" % ["★".repeat(level), "☆".repeat(5 - level), roundi(heat)]
	wanted_label.modulate = Color("#ffcf5c") if level > 0 else Color("#aeb7bd")


func _on_money_changed(total: int) -> void:
	money_label.text = "$ %d" % total


func _on_crime_committed(description: String, heat_added: float) -> void:
	show_message("%s  •  +%d procura" % [description, roundi(heat_added)])


func _on_mission_completed(reward: int) -> void:
	show_message("MISSÃO CONCLUÍDA  •  +$%d" % reward)


func _on_message_timer_timeout() -> void:
	message_panel.hide()

