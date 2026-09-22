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
	TALK_TO_BRUNO,
	BUY_DEVICE,
	CAPTURE_VOLT,
	RETURN_TO_BRUNO,
	MISSION_2_COMPLETE,
	CLEAR_RAIDERS,
	MISSION_3_COMPLETE,
}

const MAYA_POSITION := Vector2(-282, 92)
const PHONE_POSITION := Vector2(280, 220)
const WILDERNESS_POSITION := Vector2(0, -1260)
const BRUNO_POSITION := Vector2(1240, 420)
const WORKSHOP_POSITION := Vector2(1240, 620)
const VOLT_POSITION := Vector2(1010, -600)

const MISSION_1_REWARD := 250
const MISSION_2_REWARD := 200
const MISSION_3_REWARD := 150
const RAIDERS_REQUIRED := 2

var stage := Stage.TALK_TO_MAYA
var raiders_defeated := 0


func _ready() -> void:
	WantedManager.wanted_changed.connect(_on_wanted_changed)


func reset_run() -> void:
	stage = Stage.TALK_TO_MAYA
	raiders_defeated = 0
	_emit_current_objective()


func talk_to_maya() -> String:
	match stage:
		Stage.TALK_TO_MAYA:
			stage = Stage.ANSWER_PHONE
			_emit_current_objective()
			return "Maya: O telefone da praça não para de tocar. Acho que é para você."
		Stage.RETURN_TO_MAYA:
			stage = Stage.COMPLETE
			GameManager.add_money(MISSION_1_REWARD)
			mission_completed.emit(MISSION_1_REWARD)
			_emit_current_objective()
			return "Maya: Então os Wilds são reais... Pegue isto. Você vai precisar.  +$%d" % MISSION_1_REWARD
		Stage.COMPLETE:
			stage = Stage.TALK_TO_BRUNO
			_emit_current_objective()
			return "Maya: Tem um cara chamado Bruno no Distrito Industrial. Se alguém entende esses sinais, é ele."
		Stage.CLEAR_RAIDERS, Stage.MISSION_2_COMPLETE:
			return "Maya: Os Raiders estão se aproveitando do caos. Limpe os galpões e volte inteiro."
		Stage.MISSION_3_COMPLETE:
			return "Maya: Dois Wilds e um distrito limpo... agora temos problemas maiores para investigar."
		_:
			return "Maya: Siga a pista. Eu fico de olho nas ruas."


func talk_to_bruno() -> String:
	match stage:
		Stage.TALK_TO_BRUNO:
			stage = Stage.BUY_DEVICE
			_emit_current_objective()
			return "Bruno: Vi o que apareceu na mata. Passe na Oficina Cobalto e compre um Dispositivo Wild. Tem outra criatura rondando os galpões."
		Stage.RETURN_TO_BRUNO:
			stage = Stage.CLEAR_RAIDERS
			raiders_defeated = 0
			GameManager.add_money(MISSION_2_REWARD)
			mission_completed.emit(MISSION_2_REWARD)
			_emit_current_objective()
			return "Bruno: Você trouxe o Volt vivo... bom. Agora limpe os dois Raiders dos galpões. A Cobalto separou uma pistola para você, se tiver dinheiro.  +$%d" % MISSION_2_REWARD
		Stage.CLEAR_RAIDERS, Stage.MISSION_2_COMPLETE:
			return "Bruno: Ainda tem Raider nos galpões. Resolva isso antes que chegue reforço."
		Stage.MISSION_3_COMPLETE:
			return "Bruno: Galpões limpos. Bom trabalho. Mas eles estavam procurando alguma coisa por aqui..."
		_:
			return "Bruno: Agora não. Resolva o que já começou."


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


func bought_capture_device() -> void:
	if stage != Stage.BUY_DEVICE:
		return
	stage = Stage.CAPTURE_VOLT
	_emit_current_objective()


func capture_volt() -> void:
	if stage != Stage.CAPTURE_VOLT:
		return
	stage = Stage.RETURN_TO_BRUNO
	_emit_current_objective()


func raider_defeated() -> void:
	# Compatibilidade com saves da 0.5 que paravam em MISSION_2_COMPLETE.
	if stage == Stage.MISSION_2_COMPLETE:
		stage = Stage.CLEAR_RAIDERS
		raiders_defeated = 0

	if stage != Stage.CLEAR_RAIDERS:
		return

	raiders_defeated = mini(RAIDERS_REQUIRED, raiders_defeated + 1)
	if raiders_defeated >= RAIDERS_REQUIRED:
		stage = Stage.MISSION_3_COMPLETE
		GameManager.add_money(MISSION_3_REWARD)
		mission_completed.emit(MISSION_3_REWARD)
	_emit_current_objective()


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
			objective_changed.emit("MISSÃO CONCLUÍDA", "Nib agora faz parte do seu grupo. Fale com Maya para continuar.", Vector2.ZERO, false)
		Stage.TALK_TO_BRUNO:
			objective_changed.emit("ANOMALIA #002", "Procure Bruno no Distrito Industrial.", BRUNO_POSITION, true)
		Stage.BUY_DEVICE:
			objective_changed.emit("OFICINA COBALTO", "Compre um Dispositivo Wild por $100.", WORKSHOP_POSITION, true)
		Stage.CAPTURE_VOLT:
			objective_changed.emit("ANOMALIA #002", "Encontre e capture Volt nos galpões.", VOLT_POSITION, true)
		Stage.RETURN_TO_BRUNO:
			objective_changed.emit("ANOMALIA #002", "Volte para Bruno.", BRUNO_POSITION, true)
		Stage.MISSION_2_COMPLETE, Stage.CLEAR_RAIDERS:
			objective_changed.emit(
				"LIMPEZA DOS GALPÕES",
				"Elimine os Raiders no Distrito Industrial.  %d/%d" % [raiders_defeated, RAIDERS_REQUIRED],
				Vector2(1285, -605),
				true
			)
		Stage.MISSION_3_COMPLETE:
			objective_changed.emit(
				"MISSÃO CONCLUÍDA",
				"Galpões limpos. Recompensa: +$%d. Bruno tem mais informações." % MISSION_3_REWARD,
				Vector2.ZERO,
				false
			)
