class_name LookAtCamera extends Node3D

@export var disabled:bool;
@export var enable_random_rotation:bool = false
var _random_angle:float = 0;

func _ready():
	if enable_random_rotation:
		_random_angle = randf_range(0,2 * PI)
		
func get_up_vector()->Vector3:
	if LevelCameraController.main_camera:
		return LevelCameraController.main_camera.basis.y;
	else: 
		return Vector3.UP;
		
func get_forward_rotation()->float:
	return 0;

func _process(_delta):
	if disabled:
		return
		
	if LevelCameraController.main_camera == null:
		return

	# Get the global position of the camera
	var camera_global_position = LevelCameraController.main_camera.global_position;

	look_at(camera_global_position, get_up_vector(), true)
	rotate_object_local(Vector3.FORWARD, get_forward_rotation());# + _random_angle);
	#rotate_object_local(Vector3.FORWARD, get_forward_rotation() + _random_angle);
