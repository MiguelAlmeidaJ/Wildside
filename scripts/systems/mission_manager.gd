extends Node

signal objective_changed(title: String, description: String, target: Vector2, has_target: bool)
signal mission_completed(reward: int)

enum Stage {
	TALK_TO_MAYA,
	ANSWER_PHONE,
	REACH_WILDERNESS,
	CAPTURE_NIB,
	ESCAPE_POLICE,
	RETURN_TO_MAYA,
	COMPLETE,
}

const MAYA_POSITION := Vector2(-282, 92)
const PHONE_POSITION := Vector2(280, 220)
const WILDERNESS_POSITION := Vector2(0, -1260)
const REWARD := 250

var stage := Stage.TALK_TO_MAYA


func _ready() -> void:
	WantedManager.wanted_changed.connect(_on_wanted_changed)


func reset_run() -> void:
	stage = Stage.TALK_TO_MAYA
	_emit_current_objective()


func talk_to_maya() -> String:
	match stage:
		Stage.TALK_TO_MAYA:
			stage = Stage.ANSWER_PHONE
			_emit_current_objective()
			return "Maya: O telefone da praça não para de tocar. Acho que é para você."
		Stage.RETURN_TO_MAYA:
			stage = Stage.COMPLETE
			GameManager.add_money(REWARD)
			mission_completed.emit(REWARD)
			_emit_current_objective()
			return "Maya: Então os Wilds são reais... Pegue isto. Você vai precisar.  +$%d" % REWARD
		Stage.COMPLETE:
			return "Maya: Cuide do Nib. A cidade ainda não sabe o que está chegando."
		_:
			return "Maya: Siga a pista. Eu fico de olho nas ruas."


func answer_phone() -> String:
	if stage != Stage.ANSWER_PHONE:
		return "O aparelho está mudo."
	stage = Stage.REACH_WILDERNESS
	_emit_current_objective()
	return "DESCONHECIDO: Se quer entender esta cidade, vá até a mata ao norte."


func enter_wilderness() -> void:
	if stage != Stage.REACH_WILDERNESS:
		return
	stage = Stage.CAPTURE_NIB
	_emit_current_objective()


func capture_nib() -> void:
	if stage != Stage.CAPTURE_NIB:
		return
	stage = Stage.ESCAPE_POLICE
	_emit_current_objective()
	if WantedManager.wanted_level == 0:
		WantedManager.add_heat(20.0, "Sinal anômalo detectado")


func _on_wanted_changed(level: int, _heat: float) -> void:
	if stage == Stage.ESCAPE_POLICE and level == 0:
		stage = Stage.RETURN_TO_MAYA
		_emit_current_objective()


func _emit_current_objective() -> void:
	match stage:
		Stage.TALK_TO_MAYA:
			objective_changed.emit("ANOMALIA #001", "Converse com Maya.", MAYA_POSITION, true)
		Stage.ANSWER_PHONE:
			objective_changed.emit("ANOMALIA #001", "Atenda o telefone da praça.", PHONE_POSITION, true)
		Stage.REACH_WILDERNESS:
			objective_changed.emit("ANOMALIA #001", "Vá até a mata ao norte.", WILDERNESS_POSITION, true)
		Stage.CAPTURE_NIB:
			objective_changed.emit("CRIATURA SELVAGEM", "Aproxime-se do Nib e pressione Q.", WILDERNESS_POSITION, true)
		Stage.ESCAPE_POLICE:
			objective_changed.emit("FUJA", "Perca a polícia e reduza a procura.", Vector2.ZERO, false)
		Stage.RETURN_TO_MAYA:
			objective_changed.emit("ANOMALIA #001", "Volte para Maya.", MAYA_POSITION, true)
		Stage.COMPLETE:
			objective_changed.emit("MISSÃO CONCLUÍDA", "Nib agora faz parte do seu grupo.", Vector2.ZERO, false)

