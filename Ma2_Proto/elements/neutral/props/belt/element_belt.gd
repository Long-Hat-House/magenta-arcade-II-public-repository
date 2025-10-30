class_name Element_Belt extends LHH3D

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var belt: MeshInstance3D = $belt
@export var walk_multiplier:float = 0.053;

func set_animation_off():
	anim.stop();
	
func walk(delta:Vector3):
	if !delta.is_zero_approx():
		var length:float = delta.dot(Vector3.RIGHT);
		
		var value:Vector3 = belt.get_surface_override_material(0).get("uv1_offset")
		belt.get_surface_override_material(0).set("uv1_offset", value + Vector3.UP * length * walk_multiplier);
