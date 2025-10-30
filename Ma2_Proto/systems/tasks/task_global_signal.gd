class_name Task_GlobalSignal extends Task

class Event:
	signal happened;
	
static var global_signal:Event = Event.new();

func _start_task() -> void:
	global_signal.happened.emit();
