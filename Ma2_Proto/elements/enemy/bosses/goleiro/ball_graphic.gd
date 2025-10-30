class_name Graphic_Ball extends LHH3D

var mat:Material;

@onready var ball: MeshInstance3D = $ball

func _ready() -> void:
	mat = ball.get_active_material(0);
	set_emission_active(false);
	
func get_material()->Material:
	return mat;
	
func set_emission_active(active:bool):
	mat.set("emission_enabled", active);
