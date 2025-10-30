class_name Task extends Node

signal started;
signal done;

#Override this with the task in mind
func _start_task() -> void:
	pass;

##Public function
func start_task() -> void:
	if is_instance_valid(self):
		started.emit();
		await _start_task();
	if is_instance_valid(self):
		done.emit();
