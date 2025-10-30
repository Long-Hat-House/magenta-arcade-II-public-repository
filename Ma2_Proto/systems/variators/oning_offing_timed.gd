class_name OningOffingTimed extends Node

@export var oning_time:float = 1.0;
@export var offing_time:float = 1.0;
@export var start_on:bool = false;
@export var only_if_on_screen:VisibleOnScreenNotifier3D;

var is_on:bool;
signal on;
signal off;
signal changed(on:bool);

func set_on(now_on:bool):
	if now_on:
		on.emit();
	else:
		off.emit();
	changed.emit(now_on);
	
var delay:float;

func _enter_tree() -> void:
	is_on = start_on;
	set_on(is_on);
	delay = reset_delay(is_on);
	
func reset_delay(on:bool)->float:
	return oning_time if on else offing_time;
	
func _process(delta: float) -> void:
	if only_if_on_screen:
		if not only_if_on_screen.is_on_screen(): return;
	delay -= delta;
	while delay <= 0:
		is_on = !is_on;
		set_on(is_on);
		delay += reset_delay(is_on);
