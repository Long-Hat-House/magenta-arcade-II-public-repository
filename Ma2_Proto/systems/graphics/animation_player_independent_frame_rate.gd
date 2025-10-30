class_name AnimationPlayerIndependentFrameRate extends AnimationPlayer

var old_time:int;

func _ready() -> void:
	self.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL;
	old_time = Time.get_ticks_msec();

func _enter_tree() -> void:
	old_time = Time.get_ticks_msec();

func _process(delta: float) -> void:
	var time:int = Time.get_ticks_msec();
	var new_delta:float = float(time - old_time)/1_000.0;
	advance(new_delta);
	old_time = time;
