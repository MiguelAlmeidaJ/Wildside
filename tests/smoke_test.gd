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
	var parked_blocker = car.get_node("ParkedBlocker/CollisionShape2D")
	var maya = game.get_node("World/Entities/NPCs/Maya")
	var bruno = game.get_node("World/Entities/NPCs/Bruno")
	var phone = game.get_node("World/Props/Payphone")
	var nib = game.get_node("World/Entities/Creatures/Nib")
	var volt = game.get_node("World/Entities/Creatures/Volt")
	var workshop = game.get_node("World/Props/Workshop")
	var police = game.get_node("World/Entities/NPCs/Police1")
	var district_tracker = game.get_node("DistrictTracker")
	var raider1 = game.get_node("World/Entities/Enemies/Raider1")
	var raider2 = game.get_node("World/Entities/Enemies/Raider2")
	_check(player != null, "Player precisa existir")
	_check(car != null, "Car precisa existir")
	await physics_frame
	_check(car.collision_layer == 0, "Carro estacionado não deve usar o CharacterBody como obstáculo do player")
	_check(not parked_blocker.disabled, "Carro estacionado precisa manter o bloqueio estático ativo")
	_check(get_nodes_in_group("interactable").size() >= 11, "Cidade ampliada precisa ter NPCs, veículos, telefone e Nib interativos")
	_check(district_tracker._district_for(Vector2(0, 0)) == "CENTRO DE WILDSIDE", "Centro precisa ser identificado")
	_check(district_tracker._district_for(Vector2(-1400, 400)) == "BAIRRO RESIDENCIAL", "Residencial precisa ser identificado")
	_check(district_tracker._district_for(Vector2(1400, 400)) == "DISTRITO INDUSTRIAL", "Industrial precisa ser identificado")
	_check(district_tracker._district_for(Vector2(0, 1400)) == "ZONA SUL", "Zona Sul precisa ser identificada")
	_check(district_tracker._district_for(Vector2(0, -1300)) == "MATA NORTE", "Mata Norte precisa ser identificada")

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
	_check(car.collision_layer == 4, "Carro dirigido precisa reativar sua camada móvel")
	_check(parked_blocker.disabled, "Bloqueio estático deve desligar enquanto o carro é dirigido")
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
	_check(car.collision_layer == 0, "Carro deve voltar ao modo estacionado após a saída")
	_check(not parked_blocker.disabled, "Bloqueio estático deve voltar após a saída")

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

	# Wild capturado nunca deve roubar o foco de conversa de um NPC próximo.
	player.global_position = maya.global_position + Vector2(0, 82)
	player.velocity = Vector2.ZERO
	nib.global_position = player.global_position + Vector2(0, 8)
	var conversation_focus = player._find_nearest_interactable()
	_check(conversation_focus == maya, "NPC precisa ter prioridade sobre Wild capturado no E")
	var nib_anchor: Vector2 = player.get_companion_anchor(0)
	var volt_anchor: Vector2 = player.get_companion_anchor(1)
	_check(nib_anchor.distance_to(player.global_position) > 120.0, "Nib precisa abrir espaço quando há interação próxima")
	_check(volt_anchor.distance_to(player.global_position) > 120.0, "Volt precisa abrir espaço quando há interação próxima")
	_check(mission.stage == mission.Stage.ESCAPE_POLICE, "Captura precisa iniciar a fuga")
	_check(wanted.wanted_level == 1, "Captura precisa disparar a perseguição")
	wanted.clear()
	_check(mission.stage == mission.Stage.RETURN_TO_MAYA, "Perder a polícia precisa liberar o retorno")
	maya.interact(player)
	_check(mission.stage == mission.Stage.COMPLETE, "Maya precisa concluir a missão")
	_check(game_manager.money == 250, "Missão 1 precisa pagar $250")

	# ANOMALIA #002: Maya -> Bruno -> Oficina Cobalto -> Volt -> Bruno.
	maya.interact(player)
	_check(mission.stage == mission.Stage.TALK_TO_BRUNO, "Maya precisa liberar a missão 2")
	bruno.interact(player)
	_check(mission.stage == mission.Stage.BUY_DEVICE, "Bruno precisa indicar a Oficina Cobalto")
	workshop.interact(player)
	_check(mission.stage == mission.Stage.CAPTURE_VOLT, "Comprar o dispositivo precisa liberar a captura de Volt")
	_check(game_manager.money == 150, "Dispositivo Wild precisa custar $100")
	_check(game_manager.capture_devices == 1, "Compra precisa adicionar um Dispositivo Wild")

	await process_frame
	await physics_frame
	_check(volt.available, "Volt precisa aparecer quando a missão liberar sua captura")
	volt.capture_chance = 1.0
	volt.attempt_capture(player)
	await physics_frame
	_check(volt.captured, "Volt precisa ser capturável")
	_check(game_manager.capture_devices == 0, "Captura de Volt precisa consumir um dispositivo")
	_check(mission.stage == mission.Stage.RETURN_TO_BRUNO, "Captura de Volt precisa liberar o retorno ao Bruno")
	bruno.interact(player)
	_check(mission.stage == mission.Stage.CLEAR_RAIDERS, "Bruno precisa liberar a limpeza dos galpões")
	_check(mission.raiders_defeated == 0, "Missão dos Raiders precisa começar em 0/2")
	_check(game_manager.money == 350, "Missão 2 precisa pagar $200 após a compra do dispositivo")

	# Arsenal da Oficina Cobalto: pistola e munição.
	_check(InputMap.has_action("shoot"), "Ação de tiro precisa existir")
	_check(InputMap.has_action("reload"), "Ação de recarga precisa existir")
	workshop.interact(player)
	_check(game_manager.pistol_unlocked, "Cobalto precisa vender a pistola após a missão 2")
	_check(player.pistol_equipped, "Pistola comprada precisa ser equipada")
	_check(game_manager.money == 200, "Pistola precisa custar $150")
	_check(game_manager.pistol_magazine == 8 and game_manager.pistol_reserve == 24, "Pistola precisa vir com 8/24 munições")

	# Combate liberado após a missão 2.
	await process_frame
	await physics_frame
	_check(raider1.active and raider2.active, "Raiders precisam ativar após a ANOMALIA #002")
	_check(InputMap.has_action("wild_nib"), "Ação da habilidade do Nib precisa existir")
	_check(InputMap.has_action("wild_volt"), "Ação da habilidade do Volt precisa existir")

	# Pistola: hitscan direcionado, gasto de munição e recarga.
	player.global_position = raider1.global_position + Vector2(0, 210)
	player.velocity = Vector2.ZERO
	player._shoot_cooldown_left = 0.0
	raider1.health = raider1.max_health
	raider1._update_health_label()
	var pistol_health_before: float = raider1.health
	var magazine_before := game_manager.pistol_magazine
	var shot := player.fire_pistol_at(raider1.global_position)
	_check(shot, "Pistola precisa disparar")
	_check(game_manager.pistol_magazine == magazine_before - 1, "Disparo precisa consumir uma munição")
	_check(raider1.health < pistol_health_before, "Pistola precisa causar dano no Raider alinhado")

	game_manager.pistol_magazine = 2
	game_manager.pistol_reserve = 10
	game_manager.weapon_changed.emit(true, game_manager.pistol_magazine, game_manager.pistol_reserve)
	player._reload_left = 0.0
	_check(player.start_reload(), "Recarga precisa iniciar com pente incompleto")
	player._complete_reload()
	_check(game_manager.pistol_magazine == 8 and game_manager.pistol_reserve == 4, "Recarga precisa transferir munição da reserva")

	var ammo_money_before := game_manager.money
	var ammo_reserve_before := game_manager.pistol_reserve
	workshop.interact(player)
	_check(game_manager.money == ammo_money_before - 40, "Pacote de munição precisa custar $40")
	_check(game_manager.pistol_reserve == ammo_reserve_before + 16, "Pacote precisa adicionar 16 munições")

	# Habilidade ativa do Nib: dano forte em um alvo + knockback.
	raider1.health = raider1.max_health
	raider1._update_health_label()
	raider1._knockback = Vector2.ZERO
	nib.global_position = raider1.global_position + Vector2(0, 120)
	nib.ability_cooldown_left = 0.0
	var nib_health_before: float = raider1.health
	var nib_used := nib.use_active_ability(player)
	_check(nib_used, "Nib precisa conseguir usar Impacto")
	_check(raider1.health < nib_health_before, "Impacto do Nib precisa causar dano")
	_check(raider1._knockback.length() > 0.0, "Impacto do Nib precisa aplicar knockback")
	_check(nib.ability_cooldown_left > 0.0, "Impacto do Nib precisa iniciar cooldown")

	# Habilidade ativa do Volt: corrente elétrica em múltiplos alvos + stun.
	raider1.health = raider1.max_health
	raider2.health = raider2.max_health
	raider1._update_health_label()
	raider2._update_health_label()
	raider1._knockback = Vector2.ZERO
	raider2._knockback = Vector2.ZERO
	raider1._stun_left = 0.0
	raider2._stun_left = 0.0
	volt.global_position = raider1.global_position + Vector2(-80, 0)
	volt.ability_cooldown_left = 0.0
	var volt_r1_before: float = raider1.health
	var volt_r2_before: float = raider2.health
	var volt_used := volt.use_active_ability(player)
	_check(volt_used, "Volt precisa conseguir usar Sobrecarga")
	_check(raider1.health < volt_r1_before, "Sobrecarga precisa atingir o primeiro Raider")
	_check(raider2.health < volt_r2_before, "Sobrecarga precisa encadear para o segundo Raider")
	_check(raider1._stun_left > 0.0 and raider2._stun_left > 0.0, "Sobrecarga precisa atordoar os alvos")
	_check(volt.ability_cooldown_left > 0.0, "Sobrecarga do Volt precisa iniciar cooldown")

	# Restaura os inimigos para os testes de combate corpo a corpo abaixo.
	raider1.health = raider1.max_health
	raider2.health = raider2.max_health
	raider1._stun_left = 0.0
	raider2._stun_left = 0.0
	raider1._knockback = Vector2.ZERO
	raider2._knockback = Vector2.ZERO
	raider1._update_health_label()
	raider2._update_health_label()

	# Ataque corpo a corpo do player deve respeitar alcance e direção.
	player.global_position = raider1.global_position + Vector2(0, 82)
	player.velocity = Vector2.ZERO
	player.facing_direction = Vector2.UP
	player._attack_cooldown_left = 0.0
	var raider_health_before: float = raider1.health
	var hit := player.perform_attack()
	_check(hit, "Ataque do player precisa acertar Raider à frente")
	_check(raider1.health < raider_health_before, "Raider precisa receber dano do ataque")

	# Raider consegue ferir o jogador e a invulnerabilidade evita dano instantâneo repetido.
	var player_health_before: float = player.health
	player._invulnerability_left = 0.0
	player.take_damage(12.0, raider1)
	_check(player.health == player_health_before - 12.0, "Player precisa receber dano")
	var health_after_hit: float = player.health
	player.take_damage(12.0, raider1)
	_check(player.health == health_after_hit, "Invulnerabilidade curta precisa impedir dano duplicado")

	# Derrotar os dois Raiders precisa atualizar e concluir a missão.
	var money_before_raider := game_manager.money
	raider1.take_damage(999.0, player)
	_check(raider1.dead, "Raider precisa ser derrotável")
	_check(mission.raiders_defeated == 1, "Primeiro Raider precisa atualizar o objetivo para 1/2")
	_check(mission.stage == mission.Stage.CLEAR_RAIDERS, "Missão deve continuar após o primeiro Raider")
	_check(game_manager.money == money_before_raider + raider1.reward, "Primeiro Raider precisa pagar recompensa própria")

	var money_before_second_raider := game_manager.money
	raider2.take_damage(999.0, player)
	_check(raider2.dead, "Segundo Raider precisa ser derrotável")
	_check(mission.raiders_defeated == 2, "Segundo Raider precisa atualizar o objetivo para 2/2")
	_check(mission.stage == mission.Stage.MISSION_3_COMPLETE, "Segundo Raider precisa concluir a limpeza dos galpões")
	_check(game_manager.money == money_before_second_raider + raider2.reward + mission.MISSION_3_REWARD, "Segundo Raider precisa pagar recompensa própria e bônus da missão")

	# Derrota do player deve restaurar vida, posição e cobrar até $50.
	var money_before_defeat := game_manager.money
	player._invulnerability_left = 0.0
	player.take_damage(999.0, raider2)
	_check(player.health == player.max_health, "Derrota precisa restaurar a vida")
	_check(player.global_position == player._spawn_position, "Derrota precisa levar o player ao ponto inicial")
	_check(game_manager.money == money_before_defeat - mini(50, money_before_defeat), "Derrota precisa aplicar penalidade de até $50")

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
