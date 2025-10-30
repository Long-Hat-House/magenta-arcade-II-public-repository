class_name Level_Snippet_Node extends Node

@export var disable:bool;

func is_active()->bool:
	return not disable and self.can_process();

func cmd(level:Level)->Level.CMD:
	return _cmd(level);

func _cmd(level:Level)->Level.CMD:
	return Level.CMD.Nop();
