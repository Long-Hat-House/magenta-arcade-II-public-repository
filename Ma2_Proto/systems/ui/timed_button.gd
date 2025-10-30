class_name TimedButton extends Button

signal time_upped(time_ratio:float)
signal time_zeroed()
signal time_completed()
signal time_changed(time_ratio:float)

@export var target_time:float = 1

var being_pressed:bool
var current_time:float
var finished:bool

func get_percent_time() -> float:
	return current_time/target_time

func _ready():
	button_down.connect(func(): being_pressed = true)
	button_up.connect(func(): being_pressed = false)
	time_changed.emit(get_percent_time())

func _process(delta):
	if being_pressed && !finished:
		current_time += delta
		if current_time >= target_time:
			finished = true
			time_upped.emit(1)
			time_completed.emit()
			time_changed.emit(1)
		else:
			time_upped.emit(get_percent_time())
			time_changed.emit(get_percent_time())
	elif !being_pressed && current_time > 0:
		current_time = 0
		finished = false
		time_zeroed.emit()
		time_changed.emit(0)
