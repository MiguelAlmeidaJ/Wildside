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
@onready var murno_ability_label: Label = %MurnoAbilityLabel
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
@onready var cache_label: Label = %CacheLabel
@onready var event_stats_label: Label = %EventStatsLabel
@onready var vehicle_panel: PanelContainer = %VehiclePanel
@onready var vehicle_label: Label = %VehicleLabel
@onready var vehicle_bar: ProgressBar = %VehicleBar
@onready var race_panel: PanelContainer = %RacePanel
@onready var race_title: Label = %RaceTitle
@onready var race_description: Label = %RaceDescription
@onready var clock_label: Label = %ClockLabel
@onready var event_panel: PanelContainer = %EventPanel
@onready var event_title: Label = %EventTitle
@onready var event_description: Label = %EventDescription
@onready var mini_map_panel: PanelContainer = %MiniMapPanel
@onready var mini_map: Control = %MiniMap
@onready var wild_team_label: Label = %WildTeamLabel
@onready var wild_terminal_panel: PanelContainer = %WildTerminalPanel
@onready var nib_roster_label: Label = %NibRosterLabel
@onready var volt_roster_label: Label = %VoltRosterLabel
@onready var murno_roster_label: Label = %MurnoRosterLabel

var _objective_text := ""
var _objective_target := Vector2.ZERO
var _objective_has_target := false
var _district_tween: Tween
var _side_objective_text := ""
var _side_objective_target := Vector2.ZERO
var _side_objective_has_target := false
var _event_target := Vector2.ZERO
var _event_has_target := false
var _event_description_text := ""
var _minimap_before_modal := true
var _modal_focus_open := false


func _ready() -> void:
	_ensure_minimap_input()
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
	GameManager.cache_progress_changed.connect(_on_cache_progress_changed)
	GameManager.wild_roster_changed.connect(_on_wild_roster_changed)
	GameManager.wild_terminal_changed.connect(_on_wild_terminal_changed)
	SideJobManager.objective_changed.connect(_on_side_job_objective_changed)
	StreetRaceManager.race_state_changed.connect(_on_race_state_changed)
	StreetRaceManager.race_progress_changed.connect(_on_race_progress)
	StreetRaceManager.race_completed.connect(_on_race_completed)
	SideJobManager.job_completed.connect(_on_side_job_completed)
	WorldTimeManager.time_changed.connect(_on_time_changed)
	WorldEventManager.event_changed.connect(_on_world_event_changed)
	WorldEventManager.event_completed.connect(_on_world_event_completed)
	WorldEventManager.event_history_changed.connect(_on_event_history_changed)
	_on_wanted_changed(WantedManager.wanted_level, WantedManager.heat)
	_on_pursuit_state_changed(WantedManager.is_visible_to_police)
	set_arrest_progress(0.0)
	_on_money_changed(GameManager.money)
	_on_capture_devices_changed(GameManager.capture_devices)
	_on_weapon_changed(GameManager.pistol_unlocked, GameManager.pistol_magazine, GameManager.pistol_reserve)
	_on_inventory_changed(GameManager.medkits, GameManager.snacks, GameManager.energy_drinks)
	_on_store_state_changed(false, "")
	_on_cache_progress_changed(GameManager.collected_caches.size(), GameManager.CACHE_TOTAL)
	_on_wild_roster_changed(GameManager.captured_wilds, GameManager.active_wilds)
	_on_event_history_changed(WorldEventManager.events_completed)
	_on_race_state_changed(StreetRaceManager.state)
	_on_time_changed(WorldTimeManager.get_hour(), WorldTimeManager.get_minute(), WorldTimeManager.get_phase())
	event_panel.hide()
	side_job_panel.hide()
	inventory_panel.hide()
	wild_terminal_panel.hide()
	vehicle_panel.hide()


func _process(_delta: float) -> void:
	_update_pursuit_label()
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

	if StreetRaceManager.state == StreetRaceManager.State.READY:
		var start_distance := GameManager.get_controlled_position().distance_to(StreetRaceManager.START_POSITION)
		race_description.text = "Vá até a largada na Zona Sul.\n[ %d m ]" % roundi(start_distance / 4.0)

	if _event_has_target:
		var event_distance := GameManager.get_controlled_position().distance_to(_event_target)
		event_description.text = "%s\n[ %d m ]" % [_event_description_text, roundi(event_distance / 4.0)]
	else:
		event_description.text = _event_description_text


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("minimap_toggle") and not _modal_focus_open:
		mini_map_panel.visible = not mini_map_panel.visible
		get_viewport().set_input_as_handled()


func _ensure_minimap_input() -> void:
	if not InputMap.has_action("minimap_toggle"):
		InputMap.add_action("minimap_toggle")
	if InputMap.action_get_events("minimap_toggle").is_empty():
		var key := InputEventKey.new()
		key.physical_keycode = KEY_M
		InputMap.action_add_event("minimap_toggle", key)


func set_prompt(text: String) -> void:
	prompt_label.text = text
	prompt_label.visible = not text.is_empty()


func set_health(current: float, maximum: float) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	health_label.text = "VIDA  %d / %d" % [roundi(current), roundi(maximum)]


func toggle_inventory() -> void:
	var opening := not inventory_panel.visible
	if opening and GameManager.wild_terminal_open:
		GameManager.close_wild_terminal()
	inventory_panel.visible = opening
	_set_modal_focus(opening)


func set_energy_boost(remaining: float) -> void:
	if remaining > 0.05:
		energy_label.text = "J  ENERGÉTICO  x%d  •  BOOST %.1fs" % [GameManager.energy_drinks, remaining]
	else:
		energy_label.text = "J  ENERGÉTICO  x%d" % GameManager.energy_drinks


func set_vehicle_status(active: bool, vehicle_name: String = "", current: float = 0.0, maximum: float = 100.0, speed_kmh: int = 0) -> void:
	vehicle_panel.visible = active
	if not active:
		return
	vehicle_bar.max_value = maximum
	vehicle_bar.value = current
	vehicle_label.text = "%s  •  %d%%  •  %d KM/H" % [
		vehicle_name.to_upper(),
		roundi((current / maxf(1.0, maximum)) * 100.0),
		speed_kmh,
	]


func set_arrest_progress(value: float) -> void:
	value = clampf(value, 0.0, 1.0)
	arrest_bar.value = value * 100.0
	arrest_label.text = "PRISÃO  %d%%" % roundi(value * 100.0)
	arrest_panel.visible = value > 0.0


func set_wild_ability(slot: String, captured: bool, active: bool, remaining: float, _total: float) -> void:
	var label: Label = nib_ability_label
	var key := "1"
	var wild_name := "NIB"
	var ability_name := "IMPACTO"

	if slot == "volt":
		label = volt_ability_label
		key = "2"
		wild_name = "VOLT"
		ability_name = "SOBRECARGA"
	elif slot == "murno":
		label = murno_ability_label
		key = "3"
		wild_name = "MURNO"
		ability_name = "ECLIPSE"

	if not captured:
		label.text = "%s  %s • %s  [BLOQUEADO]" % [key, wild_name, ability_name]
	elif not active:
		label.text = "%s  %s • %s  [RESERVA]" % [key, wild_name, ability_name]
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
	mini_map.call("set_main_objective", target, has_target)
	mission_panel.show()


func _on_wanted_changed(level: int, heat: float) -> void:
	wanted_label.text = "%s%s  %03d" % ["★".repeat(level), "☆".repeat(5 - level), roundi(heat)]
	wanted_label.modulate = Color("#ffcf5c") if level > 0 else Color("#aeb7bd")
	_update_pursuit_label()


func _on_pursuit_state_changed(_seen: bool) -> void:
	_update_pursuit_label()


func _update_pursuit_label() -> void:
	var level := WantedManager.wanted_level
	if level <= 0:
		pursuit_label.text = "SEM PROCURA"
		pursuit_label.modulate = Color("#aeb7bd")
		return

	if not WantedManager.is_visible_to_police:
		var dispatching := false
		var unit_active := false
		for unit in get_tree().get_nodes_in_group("police_unit"):
			if bool(unit.get("responding")):
				dispatching = true
			if bool(unit.get("active")):
				unit_active = true
		if dispatching and not unit_active:
			pursuit_label.text = "VIATURAS A CAMINHO  •  NÍVEL %d" % level
			pursuit_label.modulate = Color("#ffcf5c")
		else:
			pursuit_label.text = "ESCAPANDO  •  NÍVEL %d" % level
			pursuit_label.modulate = Color("#7de3cf")
		return

	match level:
		5:
			pursuit_label.text = "CAÇADA TOTAL"
			pursuit_label.modulate = Color("#ff5555")
		4:
			pursuit_label.text = "RESPOSTA TÁTICA"
			pursuit_label.modulate = Color("#ff6868")
		3:
			pursuit_label.text = "CERCO ATIVO"
			pursuit_label.modulate = Color("#ff7b7b")
		_:
			pursuit_label.text = "VISTO"
			pursuit_label.modulate = Color("#ff8d8d")


func _on_money_changed(total: int) -> void:
	money_label.text = "$ %d" % total


func _on_capture_devices_changed(total: int) -> void:
	devices_label.text = "◇  %d" % total


func _on_inventory_changed(medkits: int, snacks: int, energy_drinks: int) -> void:
	medkit_label.text = "H  KIT MÉDICO  x%d  •  +55 HP" % medkits
	snack_label.text = "K  LANCHE  x%d  •  +20 HP" % snacks
	if is_instance_valid(GameManager.player) and float(GameManager.player.get("energy_boost_left")) > 0.05:
		set_energy_boost(float(GameManager.player.get("energy_boost_left")))
	else:
		energy_label.text = "J  ENERGÉTICO  x%d  •  10s velocidade" % energy_drinks


func _on_time_changed(hour: int, minute: int, phase: String) -> void:
	clock_label.text = "DIA %d  •  %02d:%02d  •  %s" % [WorldTimeManager.day_count, hour, minute, phase]


func _on_world_event_changed(title: String, description: String, target: Vector2, active: bool) -> void:
	event_panel.visible = active
	mini_map.call("set_event_objective", target, active)
	if not active:
		_event_has_target = false
		_event_description_text = ""
		return
	event_title.text = title
	_event_description_text = description
	_event_target = target
	_event_has_target = true


func _on_world_event_completed(title: String, reward: int) -> void:
	var reward_text := " • +$%d" % reward if reward > 0 else ""
	show_message("%s%s" % [title, reward_text])


func _on_event_history_changed(total: int) -> void:
	event_stats_label.text = "EVENTOS URBANOS  %d" % total


func _on_cache_progress_changed(found: int, total: int) -> void:
	cache_label.text = "ESCONDERIJOS  %d / %d" % [found, total]


func _on_race_state_changed(state: int) -> void:
	match state:
		StreetRaceManager.State.READY:
			race_panel.show()
			race_title.text = "CORRIDA DE RUA"
			race_description.text = "Vá até a largada na Zona Sul."
		StreetRaceManager.State.RACING:
			race_panel.show()
			race_title.text = "CORRIDA DE RUA"
		_:
			race_panel.hide()


func _on_race_progress(checkpoint: int, total: int, elapsed: float) -> void:
	if StreetRaceManager.state != StreetRaceManager.State.RACING:
		return
	race_description.text = "CHECKPOINT  %d / %d\nTEMPO  %.1fs" % [mini(checkpoint + 1, total), total, elapsed]


func _on_race_completed(reward: int, elapsed: float, best_time: float) -> void:
	show_message("CORRIDA CONCLUÍDA  •  %.1fs  •  +$%d  •  recorde %.1fs" % [elapsed, reward, best_time])


func _on_wild_roster_changed(captured: Array[String], active: Array[String]) -> void:
	var team_text := "—"
	if active.size() == 1:
		team_text = active[0].capitalize()
	elif active.size() >= 2:
		team_text = "%s + %s" % [active[0].capitalize(), active[1].capitalize()]
	wild_team_label.text = "EQUIPE WILD  %s" % team_text

	nib_roster_label.text = _wild_roster_text("1", "NIB", "nib", captured, active)
	volt_roster_label.text = _wild_roster_text("2", "VOLT", "volt", captured, active)
	murno_roster_label.text = _wild_roster_text("3", "MURNO", "murno", captured, active)


func _wild_roster_text(key: String, name: String, wild_id: String, captured: Array[String], active: Array[String]) -> String:
	if not captured.has(wild_id):
		return "%s  %s  •  NÃO CAPTURADO" % [key, name]
	if active.has(wild_id):
		return "%s  %s  •  ATIVO" % [key, name]
	return "%s  %s  •  RESERVA" % [key, name]


func _on_wild_terminal_changed(opened: bool) -> void:
	wild_terminal_panel.visible = opened
	if opened:
		inventory_panel.hide()
		_set_modal_focus(true)
	else:
		_set_modal_focus(false)


func _set_modal_focus(opened: bool) -> void:
	if opened and not _modal_focus_open:
		_minimap_before_modal = mini_map_panel.visible
	_modal_focus_open = opened
	if opened:
		mini_map_panel.hide()
		mission_panel.hide()
		side_job_panel.hide()
		race_panel.hide()
		event_panel.hide()
		return

	mini_map_panel.visible = _minimap_before_modal
	mission_panel.show()
	side_job_panel.visible = not _side_objective_text.is_empty()
	race_panel.visible = StreetRaceManager.state != StreetRaceManager.State.IDLE
	event_panel.visible = _event_has_target


func _on_store_state_changed(opened: bool, title: String) -> void:
	store_panel.visible = opened
	if opened:
		inventory_panel.hide()
		store_title.text = title
		_set_modal_focus(true)
	elif not GameManager.wild_terminal_open and not inventory_panel.visible:
		_set_modal_focus(false)


func _on_side_job_objective_changed(title: String, description: String, target: Vector2, has_target: bool) -> void:
	if title.is_empty():
		side_job_panel.hide()
		_side_objective_text = ""
		_side_objective_has_target = false
		mini_map.call("set_side_objective", Vector2.ZERO, false)
		return
	side_job_title.text = title
	_side_objective_text = description
	_side_objective_target = target
	_side_objective_has_target = has_target
	mini_map.call("set_side_objective", target, has_target)
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
