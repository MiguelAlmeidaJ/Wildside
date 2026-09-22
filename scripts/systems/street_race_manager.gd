extends Node

signal race_state_changed(state: int)
signal race_progress_changed(checkpoint: int, total: int, elapsed: float)
signal race_completed(reward: int, elapsed: float, best_time: float)

enum State {
	IDLE,
	READY,
	RACING,
}

const START_POSITION := Vector2(-880, 1500)
const CHECKPOINT_COUNT := 6
const BASE_REWARD := 180

var state := State.IDLE
var current_checkpoint := 0
var elapsed := 0.0
var best_time := -1.0
var wins := 0
var _race_vehicle_id := 0


func _process(delta: float) -> void:
	if state != State.RACING:
		return
	elapsed += delta
	race_progress_changed.emit(current_checkpoint, CHECKPOINT_COUNT, elapsed)


func reset_run() -> void:
	state = State.IDLE
	current_checkpoint = 0
	elapsed = 0.0
	best_time = -1.0
	wins = 0
	_race_vehicle_id = 0
	race_state_changed.emit(state)
	race_progress_changed.emit(0, CHECKPOINT_COUNT, 0.0)


func talk_to_nando() -> String:
	match state:
		State.IDLE:
			if WantedManager.wanted_level > 0:
				return "Nando: Com polícia no seu encalço? Nem pensar. Some daqui e volta limpo."
			state = State.READY
			current_checkpoint = 0
			elapsed = 0.0
			_race_vehicle_id = 0
			race_state_changed.emit(state)
			return "Nando: Quer correr? Pegue um carro e passe pela largada na Zona Sul. Sem atalho, sem desculpa."
		State.READY:
			return "Nando: A largada está marcada. Entre num carro e atravesse o arco."
		State.RACING:
			return "Nando: Você está no meio da volta. Termina primeiro, conversa depois."
	return "Nando: Hoje não."


func start_race(vehicle: Node2D) -> bool:
	if state != State.READY or not is_instance_valid(vehicle):
		return false
	if not vehicle.is_in_group("player_vehicle"):
		return false
	var player_vehicle = GameManager.player.get("current_vehicle") if is_instance_valid(GameManager.player) else null
	if player_vehicle != vehicle:
		return false
	state = State.RACING
	current_checkpoint = 0
	elapsed = 0.0
	_race_vehicle_id = vehicle.get_instance_id()
	race_state_changed.emit(state)
	race_progress_changed.emit(current_checkpoint, CHECKPOINT_COUNT, elapsed)
	return true


func checkpoint_reached(index: int, vehicle: Node2D) -> bool:
	if state != State.RACING or not is_instance_valid(vehicle):
		return false
	if vehicle.get_instance_id() != _race_vehicle_id:
		return false
	if index != current_checkpoint:
		return false

	current_checkpoint += 1
	if current_checkpoint >= CHECKPOINT_COUNT:
		_finish_race()
	else:
		race_progress_changed.emit(current_checkpoint, CHECKPOINT_COUNT, elapsed)
	return true


func cancel_race() -> void:
	if state == State.IDLE:
		return
	state = State.IDLE
	current_checkpoint = 0
	elapsed = 0.0
	_race_vehicle_id = 0
	race_state_changed.emit(state)
	race_progress_changed.emit(0, CHECKPOINT_COUNT, 0.0)


func _finish_race() -> void:
	var finished_time := elapsed
	var reward := BASE_REWARD
	if finished_time <= 55.0:
		reward += 100
	elif finished_time <= 75.0:
		reward += 50

	wins += 1
	if best_time < 0.0 or finished_time < best_time:
		best_time = finished_time

	GameManager.add_money(reward)
	state = State.IDLE
	current_checkpoint = CHECKPOINT_COUNT
	_race_vehicle_id = 0
	race_completed.emit(reward, finished_time, best_time)
	race_state_changed.emit(state)
