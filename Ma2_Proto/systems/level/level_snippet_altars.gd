class_name Level_Snippet_Altars extends Level_Snippet_Node

@export var items:Array[PackedScene];

enum Direction{
	LEFT_TO_RIGHT,
	RIGHT_TO_LEFT
}

@export var wait_first:float = 0.5;
@export var direction:Direction;

@export var group:String = "altars"

func _cmd(level:Level)->Level.CMD:
	var arr:Array[Level.CMD] = [];

	arr.append(Level.CMD_Wait_Seconds.new(wait_first));
	match direction:
		Direction.LEFT_TO_RIGHT:
			arr.append(Level_Cmd_Utils.cmd_multiple_altars_left_to_right(Level_Cmd_Utils.ALTAR, items, level, group));
		Direction.RIGHT_TO_LEFT:
			arr.append(Level_Cmd_Utils.cmd_multiple_altars_right_to_left(Level_Cmd_Utils.ALTAR, items, level, group));

	arr.append(level.objs.cmd_wait_group(group));

	return Level.CMD_Sequence.new(arr);
