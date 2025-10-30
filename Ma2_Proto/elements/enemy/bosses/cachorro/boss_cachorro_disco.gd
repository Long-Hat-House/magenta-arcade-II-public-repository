class_name Boss_Cachorro_Disco extends LHH3D

@export var angle_velocity:float = 10;


func rotate_angle(angle:float):
	#print("rotate %s" % angle)
	rotation_degrees.y += angle;

func _on_pressable_pressed_process(touch: Player.TouchData, delta: float) -> void:
	var pt:PlayerToken = touch.instance;
	
	var radius:Vector3 = pt.global_position - global_position;
	var orbit:Vector3 = radius.rotated(Vector3.UP, PI * 0.5).normalized();
	var displacement:Vector3 = pt.last_frame_displacement - LevelCameraController.instance.last_frame_movement;
	var amount_rotated:float = displacement.project(orbit).dot(orbit);
	
	rotate_angle(amount_rotated * angle_velocity);
	
