class_name ParallelTask extends Task


@export var instruction:String = "Put tasks as direct children and it will work."

@export var amount_tasks_left_to_finish:int = 0;

var task_num:int = 0;
var max_task_num:int = 0;
var tasks_done:int:
	get:
		return max_task_num - task_num;

signal _single_task_done;

func _start_task() -> void:
	
	task_num = 0;
	max_task_num = 0;

	for child in get_children():
		var childTask:Task = child as Task;
		if childTask and is_instance_valid(childTask):
			task_num += 1;
			max_task_num += 1;
			_single_task(childTask);
			
	
	while task_num > amount_tasks_left_to_finish:
		await _single_task_done;
			
func _single_task(task:Task) -> void:
	await task.start_task();
	task_num -= 1;
	_single_task_done.emit();
