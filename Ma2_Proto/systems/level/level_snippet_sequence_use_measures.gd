class_name Level_Snippet_Sequence_UseMeasures extends Level_Snippet_Sequence

@export var piece:LevelStagePiece;
@export var piece_scene:PackedScene;

enum TimeType{
	TIME,
	VELOCITY
}

@export var use_measures_data:bool;
@export var time_to_camera_to_go_type:TimeType;
@export var time_to_camera_to_go:float = 1;
@export var time_to_camera_to_go_extra:Array[float];
@export var time_to_wait_before_wave:float = 0;

var used_main_piece:bool = false;

func cmd(lvl:Level)->Level.CMD:
	var measures = {
		arr = [],
	};
	var final_commands:Array[Level.CMD] = [
		Level.CMD_Callable.new(func():
			measures.arr = lvl.get_measures();
			lvl.current_measure_index = -1;
			var i:int = 0;
			),
		Level.CMD_Callable.new(func():
			print("[PIECE] lets check the pieces!");
			for measure in get_tree().get_nodes_in_group("measure"):
				print("%s -> %s" % [measure, measure.global_position]);
			)
		];
	var commands = get_commands(lvl);
	for index_command in range(commands.size()):
		final_commands.push_back(Level.CMD_Sequence.new([
			Level.CMD_Callable.new(func():
				if use_measures_data:
					var measure:StageMeasure = measures.arr[index_command];
					if measure:
						measure.do_camera_tween(lvl);
						return;
				lvl.stage.set_pivot_offset_to_exactly_node(measures.arr[index_command]);
				var target_pos:Vector3 = lvl.stage.get_grid(0,0);
				lvl.cam.tween_position_vector(target_pos, get_cam_duration(lvl, time_to_camera_to_go + get_extra_time(index_command), target_pos));
				),
			Level.CMD_Wait_Seconds.new(time_to_wait_before_wave),
			commands[index_command],
		]))
	final_commands.push_back(lvl.cmd_clear_measures());
	return Level.CMD_Sequence.new(final_commands);

func get_cam_duration(lvl:Level, time:float, where:Vector3):
	match time_to_camera_to_go_type:
		TimeType.TIME:
			return time;
		TimeType.VELOCITY:
			var dist:Vector3 = (lvl.cam.get_pos()-where);
			dist.y = 0;
			if dist.length_squared() == 0:
				return 0;
			else:
				return dist.length() / time;

func get_extra_time(index:int)->float:
	if time_to_camera_to_go_extra != null and time_to_camera_to_go_extra.size() > index:
		return time_to_camera_to_go_extra[index];
	else:
		return 0.0;
