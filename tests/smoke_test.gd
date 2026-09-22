extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_manager = root.get_node("GameManager")
	var wanted = root.get_node("WantedManager")
	var mission = root.get_node("MissionManager")
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
	var car = game.get_node("World/Entities/Vehicles/Car")
	var maya = game.get_node("World/Entities/NPCs/Maya")
	var phone = game.get_node("World/Props/Payphone")
	var nib = game.get_node("World/Entities/Creatures/Nib")
	var police = game.get_node("World/Entities/NPCs/Police1")
	_check(player != null, "Player precisa existir")
	_check(car != null, "Car precisa existir")
	_check(get_nodes_in_group("interactable").size() >= 5, "NPCs, telefone, carro e Nib precisam ser interativos")

	var player_start: Vector2 = player.global_position
	Input.action_press("move_up")
	Input.action_press("run")
	for _frame in 12:
		await physics_frame
	Input.action_release("move_up")
	Input.action_release("run")
	_check(player.global_position.y < player_start.y - 8.0, "Player precisa correr para cima")
	_check(player.motion_state == player.MotionState.RUN or player.velocity.length() > player.walk_speed, "Corrida precisa superar a caminhada")

	car.interact(player)
	await physics_frame
	_check(player.current_vehicle == car, "Player precisa entrar no carro")
	_check(car.driver == player, "Carro precisa registrar o motorista")
	_check(wanted.wanted_level == 1, "Roubar o carro precisa gerar uma estrela")
	_check(police.active, "Polícia precisa aparecer com uma estrela")

	var car_start: Vector2 = car.global_position
	Input.action_press("move_up")
	for _frame in 16:
		await physics_frame
	Input.action_release("move_up")
	_check(car.global_position.distance_to(car_start) > 2.0, "Carro precisa se mover ao acelerar")

	car.request_exit()
	await physics_frame
	_check(player.current_vehicle == null, "Player precisa sair do carro")
	_check(car.driver == null, "Carro precisa liberar o motorista")
	_check(player.global_position.distance_to(car.global_position) > 60.0, "Saída precisa usar um ponto lateral livre")

	wanted.clear()
	mission.reset_run()
	maya.interact(player)
	_check(mission.stage == mission.Stage.ANSWER_PHONE, "Maya precisa iniciar a missão")

	# Valida a interação do telefone pelo mesmo fluxo usado durante o jogo.
	player.global_position = phone.global_position + Vector2(0, 80)
	player.velocity = Vector2.ZERO
	await physics_frame
	await physics_frame
	_check(player._find_nearest_interactable() == phone, "Player precisa detectar o telefone como alvo de interação")

	var interact_event := InputEventAction.new()
	interact_event.action = "interact"
	interact_event.pressed = true
	Input.parse_input_event(interact_event)
	await process_frame
	await physics_frame
	var release_event := InputEventAction.new()
	release_event.action = "interact"
	release_event.pressed = false
	Input.parse_input_event(release_event)
	_check(mission.stage == mission.Stage.REACH_WILDERNESS, "Apertar E no telefone precisa indicar a mata")

	mission.enter_wilderness()
	_check(mission.stage == mission.Stage.CAPTURE_NIB, "Mata precisa liberar a captura")
	nib.capture_chance = 1.0
	nib.attempt_capture(player)
	await physics_frame
	_check(nib.captured, "Nib precisa ser capturável")
	_check(mission.stage == mission.Stage.ESCAPE_POLICE, "Captura precisa iniciar a fuga")
	_check(wanted.wanted_level == 1, "Captura precisa disparar a perseguição")
	wanted.clear()
	_check(mission.stage == mission.Stage.RETURN_TO_MAYA, "Perder a polícia precisa liberar o retorno")
	maya.interact(player)
	_check(mission.stage == mission.Stage.COMPLETE, "Maya precisa concluir a missão")
	_check(game_manager.money == 250, "Missão precisa pagar $250")

	game.queue_free()
	await process_frame
	await process_frame
	_finish()


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VERTICAL SLICE SMOKE TEST: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error("SMOKE TEST: " + failure)
		quit(1)
