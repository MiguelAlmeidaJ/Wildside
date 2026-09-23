extends CanvasModulate

@export var transition_speed := 2.4

var _time := 0.0


func _ready() -> void:
	color = WorldTimeManager.get_ambient_color()


func _process(delta: float) -> void:
	_time += delta
	var blackout_active := MissionManager.stage >= MissionManager.Stage.INVESTIGATE_BLACKOUT and MissionManager.stage <= MissionManager.Stage.ESCAPE_BLACKOUT

	var target := WorldTimeManager.get_ambient_color()
	if blackout_active:
		var flicker := sin(_time * 7.0) * 0.025 + sin(_time * 13.0) * 0.015
		target = Color(
			target.r * (0.72 + flicker),
			target.g * (0.70 + flicker),
			target.b * (0.9 + flicker),
			1.0
		)
		if MissionManager.stage == MissionManager.Stage.CAPTURE_MURNO:
			var pulse := sin(_time * 4.2) * 0.035
			target = Color(
				target.r * (0.66 + pulse),
				target.g * (0.62 + pulse),
				target.b * (0.98 + pulse),
				1.0
			)

	color = color.lerp(target, 1.0 - exp(-transition_speed * delta))
