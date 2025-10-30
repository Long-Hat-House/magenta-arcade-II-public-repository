class_name Task_Branch extends Task

@export var condition:Condition;
@export var if_true:Task;
@export var if_false:Task;

#Override this with the task in mind
func _start_task() -> void:
	if condition.is_condition():
		if if_true:
			await if_true.start_task();
	else:
		if if_false:
			await if_false.start_task();
