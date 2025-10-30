class_name FpsCounter
extends Control

@onready var label:Label = %Label

@export var template = "FPS: %6.2f"
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	label.text = template % [_calculate_fps()];


func _calculate_fps()->float:
	return Engine.get_frames_per_second();
