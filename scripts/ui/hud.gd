extends CanvasLayer

@onready var prompt_label: Label = %PromptLabel
@onready var message_panel: PanelContainer = %MessagePanel
@onready var message_label: Label = %MessageLabel
@onready var message_timer: Timer = $MessageTimer
@onready var wanted_label: Label = %WantedLabel
@onready var money_label: Label = %MoneyLabel
@onready var devices_label: Label = %DevicesLabel
@onready var mission_panel: PanelContainer = %MissionPanel
@onready var mission_title: Label = %MissionTitle
@onready var mission_description: Label = %MissionDescription
@onready var district_label: Label = %DistrictLabel
@onready var health_bar: ProgressBar = %HealthBar
@onready var health_label: Label = %HealthLabel
@onready var nib_ability_label: Label = %NibAbilityLabel
@onready var volt_ability_label: Label = %VoltAbilityLabel
@onready var weapon_label: Label = %WeaponLabel
@onready var weapon_hint_label: Label = %WeaponHintLabel
@onready var pursuit_label: Label = %PursuitLabel
@onready var arrest_panel: PanelContainer = %ArrestPanel
@onready var arrest_bar: ProgressBar = %ArrestBar
@onready var arrest_label: Label = %ArrestLabel
@onready var inventory_panel: PanelContainer = %InventoryPanel
@onready var medkit_label: Label = %MedkitLabel
@onready var snack_label: Label = %SnackLabel
@onready var energy_label: Label = %EnergyLabel
@onready var store_panel: PanelContainer = %StorePanel
@onready var store_title: Label = %StoreTitle
@onready var side_job_panel: PanelContainer = %SideJobPanel
@onready var side_job_title: Label = %SideJobTitle
@onready var side_job_description: Label = %SideJobDescription

var _objective_text := ""
var _objective_target := Vector2.ZERO
var _objective_has_target := false
var _district_tween: Tween
var _side_objective_text := ""
var _side_objective_target := Vector2.ZERO
var _side_objective_has_target := false


func _ready() -> void:
	MissionManager.objective_changed.connect(_on_objective_changed)
	MissionManager.mission_completed.connect(_on_mission_completed)
	WantedManager.wanted_changed.connect(_on_wanted_changed)
	WantedManager.crime_committed.connect(_on_crime_committed)
	WantedManager.pursuit_state_changed.connect(_on_pursuit_state_changed)
	GameManager.money_changed.connect(_on_money_changed)
	GameManager.capture_devices_changed.connect(_on_capture_devices_changed)
	GameManager.district_changed.connect(_on_district_changed)
	GameManager.weapon_changed.connect(_on_weapon_changed)
	GameManager.inventory_changed.connect(_on_inventory_changed)
	GameManager.store_state_changed.connect(_on_store_state_changed)
	SideJobManager.objective_changed.connect(_on_side_job_objective_changed)
	SideJobManager.job_completed.connect(_on_side_job_completed)
	_on_wanted_changed(WantedManager.wanted_level, WantedManager.heat)
	_on_pursuit_state_changed(WantedManager.is_visible_to_police)
	set_arrest_progress(0.0)
	_on_money_changed(GameManager.money)
	_on_capture_devices_changed(GameManager.capture_devices)
	_on_weapon_changed(GameManager.pistol_unlocked, GameManager.pistol_magazine, GameManager.pistol_reserve)
	_on_inventory_changed(GameManager.medkits, GameManager.snacks, GameManager.energy_drinks)
	_on_store_state_changed(false, "")
	side_job_panel.hide()
	inventory_panel.hide()


func _process(_delta: float) -> void:
	if _objective_has_target:
		var distance := GameManager.get_controlled_position().distance_to(_objective_target)
		mission_description.text = "%s\n[ %d m ]" % [_objective_text, roundi(distance / 4.0)]
	else:
		mission_description.text = _objective_text

	if _side_objective_has_target:
		var side_distance := GameManager.get_controlled_position().distance_to(_side_objective_target)
		side_job_description.text = "%s\n[ %d m ]" % [_side_objective_text, roundi(side_distance / 4.0)]
	else:
		side_job_description.text = _side_objective_text


func set_prompt(text: String) -> void:
	prompt_label.text = text
	prompt_label.visible = not text.is_empty()


func set_health(current: float, maximum: float) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	health_label.text = "VIDA  %d / %d" % [roundi(current), roundi(maximum)]


func toggle_inventory() -> void:
	inventory_panel.visible = not inventory_panel.visible


func set_energy_boost(remaining: float) -> void:
	if remaining > 0.05:
		energy_label.text = "J  ENERGÉTICO  x%d  •  BOOST %.1fs" % [GameManager.energy_drinks, remaining]
	else:
		energy_label.text = "J  ENERGÉTICO  x%d" % GameManager.energy_drinks


func set_arrest_progress(value: float) -> void:
	value = clampf(value, 0.0, 1.0)
	arrest_bar.value = value * 100.0
	arrest_label.text = "PRISÃO  %d%%" % roundi(value * 100.0)
	arrest_panel.visible = value > 0.0


func set_wild_ability(slot: String, unlocked: bool, remaining: float, _total: float) -> void:
	var label := nib_ability_label if slot == "nib" else volt_ability_label
	var key := "1" if slot == "nib" else "2"
	var wild_name := "NIB" if slot == "nib" else "VOLT"
	var ability_name := "IMPACTO" if slot == "nib" else "SOBRECARGA"

	if not unlocked:
		label.text = "%s  %s • %s  [BLOQUEADO]" % [key, wild_name, ability_name]
	elif remaining <= 0.05:
		label.text = "%s  %s • %s  [PRONTO]" % [key, wild_name, ability_name]
	else:
		label.text = "%s  %s • %s  [%.1fs]" % [key, wild_name, ability_name, remaining]


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
	if level <= 0:
		pursuit_label.text = "SEM PROCURA"
		pursuit_label.modulate = Color("#aeb7bd")
	elif WantedManager.is_visible_to_police:
		pursuit_label.text = "VISTO"
		pursuit_label.modulate = Color("#ff7b7b")
	else:
		pursuit_label.text = "ESCAPANDO"
		pursuit_label.modulate = Color("#7de3cf")


func _on_pursuit_state_changed(seen: bool) -> void:
	if WantedManager.wanted_level <= 0:
		pursuit_label.text = "SEM PROCURA"
		pursuit_label.modulate = Color("#aeb7bd")
	elif seen:
		pursuit_label.text = "VISTO"
		pursuit_label.modulate = Color("#ff7b7b")
	else:
		pursuit_label.text = "ESCAPANDO"
		pursuit_label.modulate = Color("#7de3cf")


func _on_money_changed(total: int) -> void:
	money_label.text = "$ %d" % total


func _on_capture_devices_changed(total: int) -> void:
	devices_label.text = "◇  %d" % total


func _on_inventory_changed(medkits: int, snacks: int, energy_drinks: int) -> void:
	medkit_label.text = "H  KIT MÉDICO  x%d  •  +55 HP" % medkits
	snack_label.text = "K  LANCHE  x%d  •  +20 HP" % snacks
	if GameManager.player != null and float(GameManager.player.get("energy_boost_left")) > 0.05:
		set_energy_boost(float(GameManager.player.get("energy_boost_left")))
	else:
		energy_label.text = "J  ENERGÉTICO  x%d  •  10s velocidade" % energy_drinks


func _on_store_state_changed(opened: bool, title: String) -> void:
	store_panel.visible = opened
	if opened:
		store_title.text = title


func _on_side_job_objective_changed(title: String, description: String, target: Vector2, has_target: bool) -> void:
	if title.is_empty():
		side_job_panel.hide()
		_side_objective_text = ""
		_side_objective_has_target = false
		return
	side_job_title.text = title
	_side_objective_text = description
	_side_objective_target = target
	_side_objective_has_target = has_target
	side_job_panel.show()


func _on_side_job_completed(reward: int, deliveries: int) -> void:
	show_message("CORRIDA CONCLUÍDA  •  +$%d  •  entregas: %d" % [reward, deliveries])


func _on_weapon_changed(unlocked: bool, magazine: int, reserve: int) -> void:
	if not unlocked:
		weapon_label.text = "PISTOLA  [BLOQUEADA]"
		weapon_hint_label.text = "Disponível na Oficina Cobalto"
		return
	weapon_label.text = "PISTOLA  %d / %d" % [magazine, reserve]
	weapon_hint_label.text = "Mouse1 atirar  •  R recarregar"


func _on_crime_committed(description: String, heat_added: float) -> void:
	show_message("%s  •  +%d procura" % [description, roundi(heat_added)])


func _on_mission_completed(reward: int) -> void:
	show_message("MISSÃO CONCLUÍDA  •  +$%d" % reward)


func _on_district_changed(name: String) -> void:
	if name.is_empty():
		return
	if _district_tween != null and _district_tween.is_valid():
		_district_tween.kill()

	district_label.text = name
	district_label.show()
	district_label.modulate.a = 0.0

	_district_tween = create_tween()
	_district_tween.set_trans(Tween.TRANS_QUAD)
	_district_tween.set_ease(Tween.EASE_OUT)
	_district_tween.tween_property(district_label, "modulate:a", 1.0, 0.22)
	_district_tween.tween_interval(1.65)
	_district_tween.tween_property(district_label, "modulate:a", 0.0, 0.65)
	_district_tween.tween_callback(district_label.hide)


func _on_message_timer_timeout() -> void:
	message_panel.hide()

