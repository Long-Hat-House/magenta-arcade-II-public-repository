class_name Level_Snippet_Goto_Specific_Place extends Level_Snippet_Node

@export var where:Node3D;
@export var speed_or_time:float;
@export var style:TimeType;
@export var ease_x:Tween.EaseType = Tween.EASE_IN_OUT;
@export var trans_x:Tween.TransitionType = Tween.TRANS_SINE;
@export var ease_z:Tween.EaseType = Tween.EASE_IN_OUT;
@export var trans_z:Tween.TransitionType = Tween.TRANS_SINE;
@export var waits_tween:bool = true;

enum TimeType{
	TIME,
	VELOCITY
}

func get_cam_duration(lvl:Level, time:float, where:Vector3):
	match style:
		TimeType.TIME:
			return time;
		TimeType.VELOCITY:
			var dist:Vector3 = (lvl.cam.get_pos()-where);
			dist.y = 0;
			if dist.length_squared() == 0: 
				return 0;
			else:
				return dist.length() / time;

func cmd(level:Level)->Level.CMD:
	return Level.CMD_Sequence.new([
		go(level),
		super.cmd(level)
	])
	
func go(level:Level)->Level.CMD:
	var arr:Array[Level.CMD] = [
		Level.CMD_Callable.new(func measure_go():
			if where and is_instance_valid(where):
				level.stage.set_pivot_offset_to_exactly_node(where);
				var duration:float = get_cam_duration(level, speed_or_time, where.global_position);
				var tween_pos := level.stage.get_grid(0,0);
				level.cam.tween_position(tween_pos.x, duration, LevelCameraController.MovementAxis.X, trans_x, ease_x);
				level.cam.tween_position(tween_pos.z, duration, LevelCameraController.MovementAxis.Z, trans_z, ease_z);
			)
	];
	if waits_tween:
		arr.push_back(Level.CMD_Wait_Signal.new(level.cam.tweened))
	
	return Level.CMD_Sequence.new(arr);
