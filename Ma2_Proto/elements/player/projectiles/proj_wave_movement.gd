extends Node3D

@export var amplitude:float = 1;
@export var frequency:float = 1;

@export var rotation_factor:float = PI;

var t:float;

func set_inverted(inverted:bool = true):
	if inverted:
		t = PI;
	else:
		t = 0;


func _physics_process(delta: float) -> void:
	position = Vector3(cos(t) * amplitude, 0, 0);
	var delta_freq := delta * frequency * 2.0 * PI;
	var dx:float = cos(t + delta_freq) * amplitude - position.x; ##has to be physics_process for it to work
	
	rotation = Vector3(0, dx * rotation_factor, 0)
	t += delta_freq;
	
