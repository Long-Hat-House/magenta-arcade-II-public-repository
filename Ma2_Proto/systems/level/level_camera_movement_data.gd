class_name CameraMovementData extends Resource

static var _DEFAULT_CAMERA_DATA:CameraMovementData;
static var DefaultData:CameraMovementData:
	get:
		if !_DEFAULT_CAMERA_DATA:
			_DEFAULT_CAMERA_DATA = load("res://elements/levels/level_structure/camera_movement_data_by_duration.tres");
		return _DEFAULT_CAMERA_DATA;

enum VelocityStyle{
	SPEED,
	DURATION
}
@export var camera_duration:float = 1.9;
@export var camera_speed:float = 27;
@export var camera_duration_style:VelocityStyle = VelocityStyle.SPEED;
@export var ease_x:Tween.EaseType = Tween.EASE_IN_OUT;
@export var trans_x:Tween.TransitionType = Tween.TRANS_QUAD;
@export var duration_multiplier_x:float = 1;
@export var ease_z:Tween.EaseType = Tween.EASE_IN_OUT;
@export var trans_z:Tween.TransitionType = Tween.TRANS_QUAD;
@export var duration_multiplier_z:float = 1;


func get_camera_duration(lvl:Level, pos:Node3D)->float:
	match camera_duration_style:
		VelocityStyle.SPEED:
			var dist:Vector3 = lvl.cam.get_pos() - pos.global_position;
			dist.y = 0;
			return dist.length() / camera_speed;
		VelocityStyle.DURATION:
			return camera_duration;
	return camera_duration;


func cmd_camera_tween(lvl:Level, to:Node3D, wait_multiplier:float = 0.0, fixed_duration:float = -1, set_pivot:bool = true)->Level.CMD:
	return Level.CMD_Await_AsyncCallable.new(do_cmd_camera_tween.bind(lvl, to, wait_multiplier, fixed_duration, set_pivot), self);

func do_cmd_camera_tween(lvl:Level, to:Node3D, wait_multiplier:float = 0.0, fixed_duration:float = -1, set_pivot:bool = true):
	if set_pivot:
		lvl.stage.set_pivot_offset_to_exactly_node(to);
	var used_duration:float = 0;
	if fixed_duration > 0:
		used_duration = fixed_duration;
	else:
		used_duration = get_camera_duration(lvl, to);
	camera_tween(lvl, to, used_duration);
	if wait_multiplier > 0:
		await lvl.get_tree().create_timer(used_duration * wait_multiplier).timeout;
	else:
		print("DIDNT NEED TO WAIT!");


func camera_tween_duration(lvl:Level, to:Node3D)->float:
	var duration:float = get_camera_duration(lvl, to);
	camera_tween(lvl, to, duration);
	return duration;


func camera_tween(lvl:Level, to:Node3D, duration:float):
	lvl.cam.tween_position(to.global_position.x, duration * duration_multiplier_x, LevelCameraController.MovementAxis.X, trans_x, ease_x);
	lvl.cam.tween_position(to.global_position.z, duration * duration_multiplier_z, LevelCameraController.MovementAxis.Z, trans_z, ease_z);
