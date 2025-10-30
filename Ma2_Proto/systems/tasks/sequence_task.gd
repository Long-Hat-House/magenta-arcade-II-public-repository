class_name SequenceTask extends Task

enum How
{
	SameTime,
	Sequence
}

@export var how:How = How.Sequence;

@export var instruction:String = "Put tasks as direct children and it will work."

func _start_task() -> void:
	for child in get_children():
		var childTask:Task = child as Task;
		if childTask and is_instance_valid(childTask):
			match how:
				How.Sequence:
					await childTask.start_task();
				How.SameTime:
					childTask.start_task();
