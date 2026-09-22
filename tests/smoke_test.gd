extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed_main: PackedScene = load("res://main.tscn")
	_check(packed_main != null, "main.tscn precisa carregar")
	if packed_main == null:
		_finish()
		return

	var game := packed_main.instantiate()
	root.add_child(game)
	await process_frame
	await physics_frame

	var player = game.get_node("Player")
	var car = game.get_node("Car")
	_check(player != null, "Player precisa existir")
	_check(car != null, "Car precisa existir")
	_check(get_nodes_in_group("interactable").size() >= 4, "NPCs, telefone e carro precisam ser interativos")

	var player_start: Vector2 = player.global_position
	Input.action_press("move_up")
	for _frame in 8:
		await physics_frame
	Input.action_release("move_up")
	_check(player.global_position.y < player_start.y - 5.0, "Player precisa se mover para cima")

	car.interact(player)
	await physics_frame
	_check(player.current_vehicle == car, "Player precisa entrar no carro")
	_check(car.driver == player, "Carro precisa registrar o motorista")

	var car_start: Vector2 = car.global_position
	Input.action_press("move_up")
	for _frame in 12:
		await physics_frame
	Input.action_release("move_up")
	_check(car.global_position.distance_to(car_start) > 2.0, "Carro precisa se mover ao acelerar")

	car.request_exit()
	await physics_frame
	_check(player.current_vehicle == null, "Player precisa sair do carro")
	_check(car.driver == null, "Carro precisa liberar o motorista")

	game.queue_free()
	await process_frame
	_finish()


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("SMOKE TEST: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error("SMOKE TEST: " + failure)
		quit(1)

