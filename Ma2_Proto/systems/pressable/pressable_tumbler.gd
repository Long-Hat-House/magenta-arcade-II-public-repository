class_name TumblerPressable extends Tumbler

@export var pressable:Pressable;
@export var multiplier:float = 1;

func _ready() -> void:
	pressable.pressed_process.connect(on_pressed_process);
	pressable.pressed.connect(on_pressed);
	pressable.released.connect(on_released);
	
func on_pressed():
	self.set_active(true);
	
func on_released():
	self.set_active(false);
	
func on_pressed_process(touch:Player.TouchData, delta:float):
	self.set_target_tumble(Vector3.FORWARD * touch.instance.global_position.y)
