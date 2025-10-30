class_name TimeSlowdown extends Node

enum Style
{
	WhileInTree,
	Manual
}

@export var style:Style = Style.WhileInTree;
@export var time_delta:float = 1;
var tc:TimeManager.TimeDeltaChange;

func _ready() -> void:
	if style == Style.WhileInTree:
		set_slowdown(true);

func _enter_tree() -> void:
	if is_node_ready() and style == Style.WhileInTree:
		set_slowdown(true);

func _exit_tree() -> void:
	if style == Style.WhileInTree:
		set_slowdown(false);

func get_id()->String:
	return name + get_parent().name;

func set_slowdown(slowdown:bool):
	if slowdown:
		if tc == null:
			tc = TimeManager.add_time_change(get_id());
			tc.time_multiplier = time_delta;
		else:
			TimeManager.readd_time_change(tc)
	else:
		TimeManager.remove_time_change(tc)
