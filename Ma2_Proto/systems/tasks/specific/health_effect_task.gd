class_name Task_HealthEffect extends Task

@export var effect_value = 1

func _start_task() -> void:
	if effect_value > 0:
		Player.instance.heal(effect_value)
	elif effect_value < 0:
		Player.instance.damage(-effect_value)
