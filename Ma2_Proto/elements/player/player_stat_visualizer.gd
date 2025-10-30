class_name PlayerStatVisualizer extends Node3D

@export var map_in_min:float = 0;
@export var map_in_max:float = 5;
@export var map_out_min:float = 0;
@export var map_out_max:float = 5;
@export var vector_multiplier:float = 4;
@export var color:Color = Color.WHITE_SMOKE;

func _ready() -> void:
	%Sprite3D.modulate = color;

func visualize_vector3(v:Vector3):
	if v.length_squared() > 0.001:
		basis = Basis.looking_at(v.normalized(), Vector3.UP, false);
		var length:float = remap(v.length(), map_in_min, map_in_max, map_out_min, map_out_max)
		basis.z *= 0.01 + (length * vector_multiplier);
		var is_max:bool = length >= map_out_max;
		%Sprite3D.modulate = Color.WHITE if is_max else color;
	else:
		basis = Basis.IDENTITY;
		var length:float = remap(0, map_in_min, map_in_max, map_out_min, map_out_max)
		basis.z *= 0.01 + (length * vector_multiplier);
		%Sprite3D.modulate = color.lerp(Color.BLACK, 0.5);
