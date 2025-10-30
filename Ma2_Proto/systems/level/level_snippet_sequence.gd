class_name Level_Snippet_Sequence extends Level_Snippet_ChildSet

func cmd(level:Level)->Level.CMD:
	return Level.CMD_Sequence.new(get_commands(level));
