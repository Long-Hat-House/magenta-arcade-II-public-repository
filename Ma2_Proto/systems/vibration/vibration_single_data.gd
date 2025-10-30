class_name VibrationSingle extends Resource

@export var duration_ms:float = 500;
@export var amplitude:float = -1.0;
@export var priority:int = 1;

func vibrate(node:Node, duration_multiplier:float = 1.0, amplitude_multiplier:float = 1.0):
	VibrationManager.vibrate(priority, floori(duration_ms * duration_multiplier), amplitude * amplitude_multiplier);

func interrupt():
	pass;
