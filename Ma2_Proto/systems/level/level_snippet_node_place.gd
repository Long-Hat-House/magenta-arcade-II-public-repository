class_name Level_Snippet_Node_Place extends Level_Snippet_Node

@export var place:Node3D;
@export var x_duration:float;
@export var x_ease:Tween.EaseType;
@export var x_trans:Tween.TransitionType;
@export var z_duration:float;
@export var z_ease:Tween.EaseType;
@export var z_trans:Tween.TransitionType;
@export var wait:WaitMode;

enum WaitMode
{
	None,
	Minimum,
	All,
	X,
	Z
}

func cmd_wait()->Level.CMD:
	match wait:
		WaitMode.Minimum:
			return Level.CMD_Wait_Seconds.new(minf(x_duration, z_duration));
		WaitMode.All:
			return Level.CMD_Wait_Seconds.new(maxf(x_duration, z_duration));
		WaitMode.X:
			return Level.CMD_Wait_Seconds.new(x_duration);
		WaitMode.Z:
			return Level.CMD_Wait_Seconds.new(z_duration);
	return Level.CMD_Nop.new();

func cmd_camera(lvl:Level, axis:LevelCameraController.MovementAxis, duration:float, ease:Tween.EaseType, trans:Tween.TransitionType)->Level.CMD:
	return Level.CMD_Callable.new(func snippet_camera_walk():
		var p:float;
		match axis:
			LevelCameraController.MovementAxis.X:
				p = lvl.stage.get_pos_x();
			LevelCameraController.MovementAxis.Z:
				p = lvl.stage.get_pos_z();
		lvl.cam.tween_position(p, duration, axis, trans, ease);
		);

func cmd(level:Level)->Level.CMD:
	return Level.CMD_Sequence.new([
		Level.CMD_Callable.new(func goto_place():
			level.stage.set_pivot_offset_to_exactly_node(place);
			),
		cmd_camera(level, LevelCameraController.MovementAxis.X, x_duration, x_ease, x_trans),
		cmd_camera(level, LevelCameraController.MovementAxis.Z, z_duration, z_ease, z_trans),
		cmd_wait(),
		_cmd(level)
	])
