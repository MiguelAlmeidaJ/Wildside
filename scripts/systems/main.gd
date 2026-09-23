extends Node2D

@onready var player = $Player
@onready var hud = $UI/HUD
@onready var nib = $World/Entities/Creatures/Nib
@onready var volt = $World/Entities/Creatures/Volt
@onready var murno = $World/Entities/Creatures/Murno


func _ready() -> void:
	player.prompt_changed.connect(hud.set_prompt)
	player.message_requested.connect(hud.show_message)
	player.health_changed.connect(hud.set_health)
	player.arrest_progress_changed.connect(hud.set_arrest_progress)
	player.inventory_toggle_requested.connect(hud.toggle_inventory)

	GameManager.reset_run()
	WantedManager.reset_run()
	MissionManager.reset_run()
	SideJobManager.reset_run()
	StreetRaceManager.reset_run()
	WorldTimeManager.reset_run()
	WorldEventManager.reset_run()

	hud.set_health(player.health, player.max_health)

	if SaveManager.load_game():
		hud.show_message("SAVE CARREGADO • você voltou ao último descanso no apartamento.")
	else:
		hud.show_message("Wildside está viva • explore, trabalhe, corra ou siga as Anomalias.")


func _process(_delta: float) -> void:
	hud.set_wild_ability("nib", nib.captured, GameManager.is_wild_active("nib"), nib.ability_cooldown_left, nib.ability_cooldown)
	hud.set_wild_ability("volt", volt.captured, GameManager.is_wild_active("volt"), volt.ability_cooldown_left, volt.ability_cooldown)
	hud.set_wild_ability("murno", murno.captured, GameManager.is_wild_active("murno"), murno.ability_cooldown_left, murno.ability_cooldown)
	hud.set_energy_boost(float(player.get("energy_boost_left")))

	var current_vehicle = player.get("current_vehicle")
	if is_instance_valid(current_vehicle):
		var speed_kmh := 0
		if current_vehicle.has_method("get_speed_kmh"):
			speed_kmh = int(current_vehicle.call("get_speed_kmh"))
		hud.set_vehicle_status(
			true,
			str(current_vehicle.get("vehicle_name")),
			float(current_vehicle.get("durability")),
			float(current_vehicle.get("maximum_durability")),
			speed_kmh
		)
	else:
		hud.set_vehicle_status(false)
