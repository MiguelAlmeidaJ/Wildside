extends Node


func set_master_volume(linear_value: float) -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(clampf(linear_value, 0.001, 1.0)))

