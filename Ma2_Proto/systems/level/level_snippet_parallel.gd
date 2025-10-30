class_name Level_Snippet_Parallel extends Level_Snippet_ChildSet

@export var complete:bool;

func cmd(level:Level)->Level.CMD:
	if complete:
		return Level.CMD_Parallel_Complete.new(get_commands(level));
	else:
		return Level.CMD_Parallel.new(get_commands(level));
		
