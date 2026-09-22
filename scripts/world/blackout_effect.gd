extends CanvasModulate

@export var transition_speed := 2.4

var _time := 0.0


func _ready() -> void:
	color = Color.WHITE


func _process(delta: float) -> void:
	_time += delta
	var blackout_active := MissionManager.stage >= MissionManager.Stage.INVESTIGATE_BLACKOUT and MissionManager.stage <= MissionManager.Stage.ESCAPE_BLACKOUT

	var target := Color.WHITE
	if blackout_active:
		var flicker := sin(_time * 7.0) * 0.025 + sin(_time * 13.0) * 0.015
		target = Color(0.72 + flicker, 0.70 + flicker, 0.84 + flicker, 1.0)
		if MissionManager.stage == MissionManager.Stage.CAPTURE_MURNO:
			var pulse := sin(_time * 4.2) * 0.035
			target = Color(0.66 + pulse, 0.62 + pulse, 0.82 + pulse, 1.0)

	color = color.lerp(target, 1.0 - exp(-transition_speed * delta))
