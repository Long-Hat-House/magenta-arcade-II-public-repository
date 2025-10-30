class_name Level_Snippet_FactoryBranch extends Level_Snippet_Node

@export var door_a:Node3D;
@export var branch_a:Level_Snippet_Node;
@export var door_b:Node3D;
@export var branch_b:Level_Snippet_Node;

func _cmd(level:Level)->Level.CMD:
	return Level.CMD_Sequence.new([
		Level.CMD_Wait_Callable.new(func factory_branch_wait():
			return !is_instance_valid(door_a) or !is_instance_valid(door_b);
			),
		Level.CMD_Branch.new(func factory_branch_selector():
			return !is_instance_valid(door_a);
			, branch_a.cmd(level), branch_b.cmd(level))
	])
