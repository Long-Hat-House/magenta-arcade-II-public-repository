class_name ScreenFX_Task extends Task

@export var effect:HUD.ScreenEffect;

#Override this with the task in mind
func _start_task() -> void:
	await HUD.instance.make_screen_effect(effect);
	self.done.emit();
