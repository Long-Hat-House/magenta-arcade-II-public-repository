class_name CPUParticles3DIndependentFrameRate extends CPUParticles3D

var old_time:int;

func _ready() -> void:
	old_time = Time.get_ticks_msec();
	
func _enter_tree() -> void:
	old_time = Time.get_ticks_msec();

func _process(delta: float) -> void:
	var time:int = Time.get_ticks_msec();
	var new_delta:float = float(time - old_time)/1_000.0;
	request_particles_process(new_delta - delta);
	old_time = time;
