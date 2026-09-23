extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var save_path = ProjectSettings.globalize_path("user://wildside_save.json")
	if FileAccess.file_exists("user://wildside_save.json"):
		DirAccess.remove_absolute(save_path)

	var game_manager = root.get_node("GameManager")
	var wanted = root.get_node("WantedManager")
	var mission = root.get_node("MissionManager")
	var side_job = root.get_node("SideJobManager")
	var race_manager = root.get_node("StreetRaceManager")
	var time_manager = root.get_node("WorldTimeManager")
	var event_manager = root.get_node("WorldEventManager")
	var save_manager = root.get_node("SaveManager")
	var packed_main: PackedScene = load("res://main.tscn")
	_check(packed_main != null, "main.tscn precisa carregar")
	if packed_main == null:
		_finish()
		return

	var game = packed_main.instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await physics_frame

	var player = game.get_node("Player")
	var hud = game.get_node("UI/HUD")
	var mini_map = game.get_node("UI/HUD/MiniMapPanel/MiniMapContent/MiniMap")
	var mini_map_panel = game.get_node("UI/HUD/MiniMapPanel")
	var car = game.get_node("World/Entities/Vehicles/Car")
	var car_residential = game.get_node("World/Entities/Vehicles/CarResidential")
	var parked_blocker = car.get_node("ParkedBlocker/CollisionShape2D")
	var maya = game.get_node("World/Entities/NPCs/Maya")
	var bruno = game.get_node("World/Entities/NPCs/Bruno")
	var jade = game.get_node("World/Entities/NPCs/Jade")
	var rico = game.get_node("World/Entities/NPCs/Rico")
	var vera = game.get_node("World/Entities/NPCs/Vera")
	var nando = game.get_node("World/Entities/NPCs/Nando")
	var davi = game.get_node("World/Entities/NPCs/Davi")
	var phone = game.get_node("World/Props/Payphone")
	var nib = game.get_node("World/Entities/Creatures/Nib")
	var volt = game.get_node("World/Entities/Creatures/Volt")
	var murno = game.get_node("World/Entities/Creatures/Murno")
	var workshop = game.get_node("World/Props/Workshop")
	var blackout_anomaly = game.get_node("World/Props/BlackoutAnomaly")
	var market = game.get_node("World/Props/Market24")
	var safehouse = game.get_node("World/Props/Safehouse")
	var wild_terminal = game.get_node("World/Props/WildTerminal")
	var garage = game.get_node("World/Props/GarageCobalto")
	var personal_car = game.get_node("World/Entities/Vehicles/PersonalCar")
	var cache_center = game.get_node("World/Props/CacheCenter")
	var cache_residential = game.get_node("World/Props/CacheResidential")
	var cache_industrial = game.get_node("World/Props/CacheIndustrial")
	var cache_south = game.get_node("World/Props/CacheSouth")
	var cache_north = game.get_node("World/Props/CacheNorth")
	var police = game.get_node("World/Entities/NPCs/Police1")
	var police3 = game.get_node("World/Entities/NPCs/Police3")
	var police4 = game.get_node("World/Entities/NPCs/Police4")
	var police5 = game.get_node("World/Entities/NPCs/Police5")
	var district_tracker = game.get_node("DistrictTracker")
	var raider1 = game.get_node("World/Entities/Enemies/Raider1")
	var raider2 = game.get_node("World/Entities/Enemies/Raider2")
	var blackout_raider1 = game.get_node("World/Entities/Enemies/BlackoutRaider1")
	var blackout_raider2 = game.get_node("World/Entities/Enemies/BlackoutRaider2")
	var blackout_raider3 = game.get_node("World/Entities/Enemies/BlackoutRaider3")
	var event_raider1 = game.get_node("World/Entities/Enemies/EventRaider1")
	var event_raider2 = game.get_node("World/Entities/Enemies/EventRaider2")
	var event_cargo = game.get_node("World/Props/EventCargo")
	_check(player != null, "Player precisa existir")
	_check(hud != null and mini_map != null, "HUD precisa carregar o minimapa")
	_check(mini_map_panel.visible, "Minimapa precisa iniciar visível")
	_check(InputMap.has_action("minimap_toggle"), "Atalho M do minimapa precisa existir")
	_check(mini_map.main_target_active, "Minimapa precisa receber o objetivo principal inicial")
	_check(mini_map.main_target == mission.MAYA_POSITION, "Objetivo inicial do minimapa precisa apontar para Maya")
	_check(race_manager.CHECKPOINT_POSITIONS.size() == race_manager.CHECKPOINT_COUNT, "Minimapa precisa conhecer todos os checkpoints da corrida")
	_check(car != null, "Car precisa existir")
	await physics_frame
	_check(car.collision_layer == 0, "Carro estacionado não deve usar o CharacterBody como obstáculo do player")
	_check(not parked_blocker.disabled, "Carro estacionado precisa manter o bloqueio estático ativo")
	_check(get_nodes_in_group("interactable").size() >= 20, "Cidade Viva precisa ter mais cidadãos e interações")
	_check(get_nodes_in_group("citizens").size() >= 16, "Cidade Viva precisa ter população ampliada")
	_check(get_nodes_in_group("ambient_traffic").size() >= 6, "Cidade Viva precisa ter trânsito civil")
	_check(jade != null and murno != null and blackout_anomaly != null, "ANOMALIA #003 precisa carregar Jade, Murno e a distorção")
	_check(market != null and safehouse != null, "Mercado 24H e apartamento precisam existir")
	_check(wild_terminal != null, "Terminal Wild precisa existir no apartamento")
	_check(garage != null and personal_car != null, "Garagem Cobalto e veículo próprio precisam existir")
	_check(not personal_car.visible and personal_car.collision_layer == 0, "Veículo próprio deve começar bloqueado e sem colisão")
	_check(police3 != null and police4 != null and police5 != null, "Procura 3–5 estrelas precisa ter unidades dedicadas")
	_check(police.is_in_group("police_unit") and police5.is_in_group("police_unit"), "Viaturas precisam estar disponíveis para o minimapa")
	_check(event_cargo != null and event_raider1 != null and event_raider2 != null, "Eventos urbanos precisam ter atores carregados")
	_check(time_manager.get_phase() == "ENTARDECER", "Cidade precisa começar no entardecer")
	_check(district_tracker._district_for(Vector2(0, 0)) == "CENTRO DE WILDSIDE", "Centro precisa ser identificado")
	_check(district_tracker._district_for(Vector2(-1400, 400)) == "BAIRRO RESIDENCIAL", "Residencial precisa ser identificado")
	_check(district_tracker._district_for(Vector2(1400, 400)) == "DISTRITO INDUSTRIAL", "Industrial precisa ser identificado")
	_check(district_tracker._district_for(Vector2(0, 1400)) == "ZONA SUL", "Zona Sul precisa ser identificada")
	_check(district_tracker._district_for(Vector2(0, -1300)) == "MATA NORTE", "Mata Norte precisa ser identificada")

	# Vida urbana: Mercado 24H, mochila, consumíveis e corrida de entrega.
	game_manager.add_money(200)
	market.interact(player)
	_check(game_manager.store_open, "Mercado 24H precisa abrir a loja")
	var money_before_market = game_manager.money
	game_manager.purchase_store_slot(1)
	game_manager.purchase_store_slot(2)
	game_manager.purchase_store_slot(3)
	_check(game_manager.money == money_before_market - 110, "Comprar os três consumíveis precisa custar $110")
	_check(game_manager.snacks == 1 and game_manager.medkits == 1 and game_manager.energy_drinks == 1, "Compras precisam entrar na mochila")
	game_manager.close_store()

	player.health = 20.0
	player.health_changed.emit(player.health, player.max_health)
	_check(player.use_snack(), "Lanche precisa ser utilizável")
	_check(player.health == 40.0, "Lanche precisa curar 20 HP")
	_check(player.use_medkit(), "Kit médico precisa ser utilizável")
	_check(player.health == 95.0, "Kit médico precisa curar 55 HP")
	_check(player.use_energy_drink(), "Energético precisa ser utilizável")
	_check(player.energy_boost_left > 9.0, "Energético precisa ativar boost de 10s")

	side_job.reset_run()
	rico.interact(player)
	_check(side_job.stage == side_job.Stage.PICKUP_PACKAGE, "Rico precisa iniciar a Corrida Noturna")
	_check(mini_map.side_target_active and mini_map.side_target == side_job.MARKET_POSITION, "Minimapa precisa rastrear a Corrida Noturna")
	market.interact(player)
	_check(side_job.stage == side_job.Stage.DELIVER_PACKAGE, "Mercado precisa entregar a encomenda do Rico")
	var money_before_delivery = game_manager.money
	vera.interact(player)
	_check(side_job.stage == side_job.Stage.IDLE, "Vera precisa concluir a entrega")
	_check(side_job.deliveries_completed == 1, "Entrega concluída precisa entrar no contador")
	_check(game_manager.money == money_before_delivery + side_job.DELIVERY_REWARD, "Corrida Noturna precisa pagar $120")

	# Atividades livres 0.10: exploração, garagem, veículo próprio e corrida de rua.
	game_manager.add_money(900)
	var money_before_car = game_manager.money
	garage.interact(player)
	_check(game_manager.personal_vehicle_unlocked, "Garagem precisa vender o veículo próprio")
	_check(game_manager.money == money_before_car - 350, "Veículo próprio precisa custar $350")
	await process_frame
	await physics_frame
	_check(personal_car.visible, "Veículo próprio precisa aparecer após a compra")
	_check(personal_car.is_in_group("interactable"), "Veículo próprio comprado precisa ficar interativo")

	personal_car.apply_damage(50.0)
	var money_before_repair = game_manager.money
	garage.interact(player)
	_check(personal_car.durability == personal_car.maximum_durability, "Garagem precisa reparar o veículo próximo")
	_check(game_manager.money == money_before_repair - 40, "Reparo de 50% precisa custar $40")

	var money_before_caches = game_manager.money
	cache_center.interact(player)
	cache_residential.interact(player)
	cache_industrial.interact(player)
	cache_south.interact(player)
	cache_north.interact(player)
	_check(game_manager.collected_caches.size() == game_manager.CACHE_TOTAL, "Cinco esconderijos precisam ser coletáveis")
	_check(game_manager.money > money_before_caches, "Esconderijos precisam recompensar exploração")
	var money_after_caches = game_manager.money
	cache_center.interact(player)
	_check(game_manager.money == money_after_caches, "Esconderijo já coletado não pode pagar duas vezes")

	race_manager.reset_run()
	nando.interact(player)
	_check(race_manager.state == race_manager.State.READY, "Nando precisa liberar a Corrida de Rua")
	personal_car.interact(player)
	await physics_frame
	_check(player.current_vehicle == personal_car, "Veículo próprio precisa ser dirigível sem roubo")
	_check(wanted.wanted_level == 0, "Entrar no veículo próprio não pode gerar procura")
	_check(race_manager.start_race(personal_car), "Largada precisa iniciar corrida com o carro dirigido")
	for checkpoint_index in range(race_manager.CHECKPOINT_COUNT - 1):
		_check(race_manager.checkpoint_reached(checkpoint_index, personal_car), "Checkpoint %d precisa ser aceito em ordem" % (checkpoint_index + 1))
	race_manager.elapsed = 60.0
	var money_before_race = game_manager.money
	_check(race_manager.checkpoint_reached(race_manager.CHECKPOINT_COUNT - 1, personal_car), "Checkpoint final precisa concluir a corrida")
	_check(race_manager.wins == 1, "Corrida concluída precisa entrar no histórico")
	_check(is_equal_approx(race_manager.best_time, 60.0), "Primeira corrida precisa registrar melhor tempo")
	_check(game_manager.money == money_before_race + 230, "Volta de 60s precisa pagar prêmio base + bônus")
	personal_car.global_position = Vector2(1000, 1000)
	personal_car.request_exit()
	await physics_frame
	_check(player.current_vehicle == null, "Player precisa conseguir sair do veículo próprio após a corrida")
	var money_before_recovery = game_manager.money
	garage.interact(player)
	_check(personal_car.global_position == garage.global_position + Vector2(-230, 0), "Garagem precisa recuperar o carro próprio distante")
	_check(game_manager.money == money_before_recovery - 50, "Recuperação do Cobalto R precisa custar $50")

	# Prototype 0.11: relógio vivo e eventos urbanos independentes de missão.
	time_manager.set_time(12, 0)
	_check(time_manager.get_phase() == "DIA", "12:00 precisa usar iluminação de dia")
	var day_color: Color = time_manager.get_ambient_color()
	time_manager.set_time(22, 0)
	_check(time_manager.get_phase() == "NOITE", "22:00 precisa usar iluminação noturna")
	_check(time_manager.get_ambient_color() != day_color, "Dia e noite precisam produzir iluminação diferente")
	time_manager.set_time(18, 30)

	event_manager.reset_run()
	var cargo_money_before = game_manager.money
	var energy_before_event = game_manager.energy_drinks
	_check(event_manager.force_event(event_manager.EventType.CARGO, 1), "Evento de carga precisa poder ser iniciado")
	_check(event_cargo.active and event_cargo.visible, "Carga perdida precisa aparecer no mundo")
	_check(mini_map.event_target_active and mini_map.event_target == event_manager.EVENT_ANCHORS[1], "Minimapa precisa rastrear evento urbano")
	event_cargo.interact(player)
	_check(event_manager.current_type == event_manager.EventType.NONE, "Coletar carga precisa encerrar o evento")
	_check(game_manager.money == cargo_money_before + 100, "Carga do segundo ponto precisa pagar $100")
	_check(game_manager.energy_drinks == energy_before_event + 1, "Carga do segundo ponto precisa dar energético")
	_check(event_manager.events_completed == 1, "Evento de carga precisa contar como concluído")

	var raid_money_before = game_manager.money
	_check(event_manager.force_event(event_manager.EventType.RAIDERS, 2), "Confronto urbano precisa poder ser iniciado")
	_check(event_raider1.active and event_raider2.active, "Dois Raiders precisam aparecer no confronto urbano")
	event_raider1.take_damage(999.0, player)
	_check(event_manager.raiders_defeated == 1, "Primeiro Raider do evento precisa atualizar 1/2")
	event_raider2.take_damage(999.0, player)
	_check(event_manager.current_type == event_manager.EventType.NONE, "Segundo Raider precisa concluir o evento")
	_check(game_manager.money == raid_money_before + event_raider1.reward + event_raider2.reward + event_manager.RAIDERS_COMPLETION_REWARD, "Confronto urbano precisa pagar inimigos e bônus")
	_check(event_manager.events_completed == 2, "Dois eventos urbanos precisam ficar registrados")

	game_manager.reset_run()
	event_manager.reset_run()
	side_job.reset_run()
	race_manager.reset_run()
	player.energy_boost_left = 0.0
	player.heal(player.max_health)

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
	wanted.report_police_contact(1.0)
	_check(wanted.is_visible_to_police, "Contato policial precisa marcar o player como VISTO")

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

	var heat_before_swap: float = wanted.heat
	var swapped = wanted.notify_vehicle_change(car_residential)
	_check(swapped, "Trocar para outro veículo durante a perseguição precisa ajudar na fuga")
	_check(wanted.heat == maxf(0.0, heat_before_swap - 15.0), "Troca de veículo precisa reduzir 15 de heat")

	wanted.clear()
	_check(not wanted.is_visible_to_police, "Limpar procura precisa remover estado VISTO")

	# Escalada completa de procura: 3, 4 e 5 estrelas adicionam respostas mais pesadas.
	wanted.add_heat(100.0, "Teste 3 estrelas")
	_check(wanted.wanted_level == 3, "100 heat precisa gerar 3 estrelas")
	_check(police3.active and not police4.active and not police5.active, "3 estrelas precisam ativar a terceira unidade")
	wanted.add_heat(40.0, "Teste 4 estrelas")
	_check(wanted.wanted_level == 4 and police4.active, "140 heat precisa ativar a quarta unidade")
	wanted.add_heat(40.0, "Teste 5 estrelas")
	_check(wanted.wanted_level == 5 and police5.active, "180 heat precisa ativar resposta máxima")
	_check(wanted.get_arrest_bail() == 200, "Cinco estrelas precisam ter fiança máxima de $200")
	police5._deploy_officer()
	await process_frame
	await physics_frame
	_check(is_instance_valid(police5.officer), "Unidade de cinco estrelas precisa desembarcar agente")
	if is_instance_valid(police5.officer):
		_check(police5.officer.response_level == 5, "Agente da resposta máxima precisa receber nível 5")
		_check(police5.officer.arrest_time < 1.0, "Agente tático precisa prender mais rápido")
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

	var interact_event = InputEventAction.new()
	interact_event.action = "interact"
	interact_event.pressed = true
	Input.parse_input_event(interact_event)
	await process_frame
	await physics_frame
	var release_event = InputEventAction.new()
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
	_check(game_manager.is_wild_captured("nib") and game_manager.is_wild_active("nib"), "Nib capturado precisa entrar na equipe ativa")

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
	_check(game_manager.is_wild_active("volt") and game_manager.active_wilds.size() == 2, "Volt precisa ocupar a segunda vaga da equipe")
	_check(InputMap.has_action("wild_murno"), "Ação da habilidade do Murno precisa existir")
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
	game_manager.set_district("DISTRITO INDUSTRIAL")
	davi.global_position = player.global_position + Vector2(110, 0)
	davi._set_state(davi.State.IDLE, 1.0)
	raider2._investigate_left = 0.0
	wanted.clear()

	var pistol_health_before: float = raider1.health
	var magazine_before = game_manager.pistol_magazine
	var shot = player.fire_pistol_at(raider1.global_position)
	_check(shot, "Pistola precisa disparar")
	_check(game_manager.pistol_magazine == magazine_before - 1, "Disparo precisa consumir uma munição")
	_check(raider1.health < pistol_health_before, "Pistola precisa causar dano no Raider alinhado")
	_check(davi.state == davi.State.FLEE, "Civil próximo precisa fugir ao ouvir tiro")
	_check(raider2._investigate_left > 0.0, "Raider fora da visão precisa investigar o disparo")
	_check(wanted.wanted_level == 1, "Disparo urbano precisa gerar uma estrela")
	_check(police.active, "Polícia precisa reagir ao disparo urbano")

	var heat_after_first_shot: float = wanted.heat
	player._shoot_cooldown_left = 0.0
	player.fire_pistol_at(player.global_position + Vector2.LEFT * 300.0)
	_check(is_equal_approx(wanted.heat, heat_after_first_shot), "Rajada curta não deve acumular heat a cada bala")
	wanted.clear()

	game_manager.pistol_magazine = 2
	game_manager.pistol_reserve = 10
	game_manager.weapon_changed.emit(true, game_manager.pistol_magazine, game_manager.pistol_reserve)
	player._reload_left = 0.0
	_check(player.start_reload(), "Recarga precisa iniciar com pente incompleto")
	player._complete_reload()
	_check(game_manager.pistol_magazine == 8 and game_manager.pistol_reserve == 4, "Recarga precisa transferir munição da reserva")

	var ammo_money_before = game_manager.money
	var ammo_reserve_before = game_manager.pistol_reserve
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
	var nib_used = nib.use_active_ability(player)
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
	var volt_used = volt.use_active_ability(player)
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
	var hit = player.perform_attack()
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
	var money_before_raider = game_manager.money
	raider1.take_damage(999.0, player)
	_check(raider1.dead, "Raider precisa ser derrotável")
	_check(mission.raiders_defeated == 1, "Primeiro Raider precisa atualizar o objetivo para 1/2")
	_check(mission.stage == mission.Stage.CLEAR_RAIDERS, "Missão deve continuar após o primeiro Raider")
	_check(game_manager.money == money_before_raider + raider1.reward, "Primeiro Raider precisa pagar recompensa própria")

	var money_before_second_raider = game_manager.money
	raider2.take_damage(999.0, player)
	_check(raider2.dead, "Segundo Raider precisa ser derrotável")
	_check(mission.raiders_defeated == 2, "Segundo Raider precisa atualizar o objetivo para 2/2")
	_check(mission.stage == mission.Stage.MISSION_3_COMPLETE, "Segundo Raider precisa concluir a limpeza dos galpões")
	_check(game_manager.money == money_before_second_raider + raider2.reward + mission.MISSION_3_REWARD, "Segundo Raider precisa pagar recompensa própria e bônus da missão")

	# ANOMALIA #003: Bruno -> Jade -> distorção -> emboscada -> Murno -> fuga -> Jade.
	bruno.interact(player)
	_check(mission.stage == mission.Stage.TALK_TO_JADE, "Bruno precisa liberar o contato com Jade após limpar os galpões")
	jade.interact(player)
	_check(mission.stage == mission.Stage.INVESTIGATE_BLACKOUT, "Jade precisa iniciar a investigação do apagão")
	await process_frame
	await physics_frame
	_check(blackout_anomaly.active, "Distorção precisa aparecer quando Jade liberar a investigação")
	blackout_anomaly.interact(player)
	_check(mission.stage == mission.Stage.CLEAR_BLACKOUT, "Distorção precisa iniciar a emboscada da Zona Sul")

	await process_frame
	await physics_frame
	_check(blackout_raider1.active and blackout_raider2.active and blackout_raider3.active, "Três Raiders precisam ativar na emboscada")
	_check(mission.blackout_raiders_defeated == 0, "Emboscada precisa começar em 0/3")

	blackout_raider1.take_damage(999.0, player)
	_check(mission.blackout_raiders_defeated == 1, "Primeiro invasor precisa atualizar a emboscada para 1/3")
	blackout_raider2.take_damage(999.0, player)
	_check(mission.blackout_raiders_defeated == 2, "Segundo invasor precisa atualizar a emboscada para 2/3")
	var devices_before_murno = game_manager.capture_devices
	blackout_raider3.take_damage(999.0, player)
	_check(mission.stage == mission.Stage.CAPTURE_MURNO, "Terceiro invasor precisa liberar o confronto com Murno")
	_check(game_manager.capture_devices == devices_before_murno + 1, "Missão precisa fornecer um dispositivo para capturar Murno")

	await process_frame
	await physics_frame
	_check(murno.active, "Murno precisa aparecer como boss após a emboscada")
	murno.take_damage(130.0, player)
	_check(murno.weakened, "Murno precisa ficar capturável abaixo de 35% de vida")
	_check(murno.is_in_group("capturable"), "Murno enfraquecido precisa entrar no grupo capturable")

	murno.attempt_capture(player)
	_check(murno.captured, "Murno precisa ser capturável com o dispositivo")
	_check(game_manager.is_wild_captured("murno"), "Murno capturado precisa entrar na coleção")
	_check(not game_manager.is_wild_active("murno"), "Murno precisa começar na reserva quando a equipe já tem dois Wilds")
	_check(mission.stage == mission.Stage.ESCAPE_BLACKOUT, "Capturar Murno precisa disparar a fuga da Zona Sul")
	_check(wanted.wanted_level == 2, "Pulso de Murno precisa gerar duas estrelas de procura")

	wanted.clear()
	_check(mission.stage == mission.Stage.RETURN_TO_JADE, "Perder a polícia precisa liberar o retorno para Jade")
	var money_before_jade = game_manager.money
	jade.interact(player)
	_check(mission.stage == mission.Stage.ANOMALY_3_COMPLETE, "Jade precisa concluir a ANOMALIA #003")
	_check(game_manager.money == money_before_jade + mission.ANOMALY_3_REWARD, "ANOMALIA #003 precisa pagar $400")

	# Prototype 0.13: Terminal Wild permite formar equipe de até dois companheiros.
	wild_terminal.interact(player)
	_check(game_manager.wild_terminal_open, "Terminal Wild precisa abrir no apartamento")
	game_manager.toggle_wild_active("volt")
	game_manager.toggle_wild_active("murno")
	await physics_frame
	_check(game_manager.active_wilds.size() == 2, "Equipe ativa precisa continuar limitada a dois Wilds")
	_check(game_manager.is_wild_active("nib") and game_manager.is_wild_active("murno"), "Terminal precisa permitir trocar Volt por Murno")
	_check(not volt.visible and murno.visible, "Wild na reserva precisa sumir e Murno ativo precisa aparecer")
	game_manager.close_wild_terminal()

	# Apartamento: descanso, checkpoint e save persistente da versão 0.13.
	wanted.clear()
	player.health = 25.0
	player.health_changed.emit(player.health, player.max_health)
	safehouse.interact(player)
	_check(player.health == player.max_health, "Apartamento precisa restaurar a vida")
	_check(player.get_respawn_point() == safehouse.global_position + Vector2(0, 72), "Apartamento precisa atualizar o checkpoint")
	_check(FileAccess.file_exists("user://wildside_save.json"), "Apartamento precisa criar o save")
	_check(save_manager.SAVE_VERSION == 8, "Prototype 0.13 precisa usar save version 8")

	# Save/load deve restaurar estado urbano, exploração, carro próprio e recordes.
	game_manager.add_item("medkit", 2)
	game_manager.add_item("energy", 1)
	game_manager.unlock_personal_vehicle()
	game_manager.collect_cache("center")
	game_manager.collect_cache("north")
	race_manager.best_time = 58.5
	race_manager.wins = 2
	time_manager.set_time(23, 15)
	time_manager.day_count = 3
	event_manager.events_completed = 4
	personal_car.set_durability(63.0)
	var saved_money = game_manager.money
	var saved_position: Vector2 = player.global_position
	safehouse.interact(player)

	game_manager.money = 0
	game_manager.medkits = 0
	game_manager.energy_drinks = 0
	game_manager.personal_vehicle_unlocked = false
	game_manager.collected_caches.clear()
	race_manager.best_time = -1.0
	race_manager.wins = 0
	time_manager.set_time(8, 0)
	time_manager.day_count = 1
	event_manager.events_completed = 0
	game_manager.set_wild_roster([], [])
	personal_car.set_durability(100.0)
	player.global_position = Vector2.ZERO

	_check(save_manager.load_game(), "Save 0.13 precisa ser carregável")
	_check(game_manager.money == saved_money, "Load precisa restaurar dinheiro")
	_check(game_manager.medkits == 2 and game_manager.energy_drinks == 1, "Load precisa restaurar consumíveis")
	_check(player.global_position == saved_position, "Load precisa restaurar posição do player")
	_check(game_manager.personal_vehicle_unlocked, "Load precisa restaurar propriedade do veículo")
	_check(game_manager.collected_caches.has("center") and game_manager.collected_caches.has("north"), "Load precisa restaurar esconderijos encontrados")
	_check(is_equal_approx(race_manager.best_time, 58.5) and race_manager.wins == 2, "Load precisa restaurar recorde e vitórias de corrida")
	_check(time_manager.get_hour() == 23 and time_manager.get_minute() == 15 and time_manager.day_count == 3, "Load precisa restaurar relógio e dia")
	_check(event_manager.events_completed == 4, "Load precisa restaurar histórico de eventos urbanos")
	_check(game_manager.is_wild_active("nib") and game_manager.is_wild_active("murno"), "Load precisa restaurar a formação Wild ativa")
	_check(game_manager.is_wild_captured("volt"), "Load precisa manter Wilds da reserva na coleção")
	_check(is_equal_approx(personal_car.durability, 63.0), "Load precisa restaurar durabilidade do veículo próprio")

	# Derrota do player deve restaurar vida, posição e cobrar até $50.
	var money_before_defeat = game_manager.money
	player._invulnerability_left = 0.0
	player.take_damage(999.0, raider2)
	_check(player.health == player.max_health, "Derrota precisa restaurar a vida")
	_check(player.global_position == player._spawn_position, "Derrota precisa levar o player ao ponto inicial")
	_check(game_manager.money == money_before_defeat - mini(50, money_before_defeat), "Derrota precisa aplicar penalidade de até $50")

	# Polícia a pé e prisão.
	wanted.add_heat(20.0, "Teste de prisão")
	police.global_position = player.global_position + Vector2(0, 120)
	police._deploy_officer()
	await process_frame
	await physics_frame
	_check(is_instance_valid(police.officer), "Viatura precisa conseguir desembarcar um policial")

	if is_instance_valid(police.officer):
		var officer = police.officer
		officer.global_position = player.global_position + Vector2(0, 28)
		var money_before_arrest = game_manager.money
		for _frame in 110:
			await physics_frame
			if wanted.wanted_level == 0:
				break
		_check(wanted.wanted_level == 0, "Policial próximo precisa concluir a prisão")
		_check(player.global_position == player._spawn_position, "Prisão precisa levar o player ao ponto inicial")
		_check(game_manager.money == money_before_arrest - mini(75, money_before_arrest), "Prisão precisa cobrar até $75 de fiança")

	if FileAccess.file_exists("user://wildside_save.json"):
		DirAccess.remove_absolute(save_path)

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
