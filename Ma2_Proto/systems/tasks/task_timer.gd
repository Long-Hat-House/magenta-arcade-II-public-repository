class_name Task_Timer extends Task

@export var time:float;
@export var process_always:bool = false;
@export var physics:bool = false;
@export var ignore_time_scale:bool = false;

#Override this with the task in mind
func _start_task() -> void:
	await get_tree().create_timer(time, process_always, physics, ignore_time_scale).timeout;
