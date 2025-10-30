class_name SineMovement extends Node3D

@export var amplitude:Vector3;
@export var frequency_revolutions_per_second:float = 1;
@export var offset:float;
@export var stopped:bool;

var initial_position:Vector3;

var t:float;

func _ready() -> void:
	initial_position = position;

func _process(delta: float) -> void:
	if !stopped:
		position = initial_position + amplitude * sin(t + offset * 2 * PI);
		t += delta * frequency_revolutions_per_second * 2 * PI;
