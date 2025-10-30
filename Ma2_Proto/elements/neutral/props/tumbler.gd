class_name Tumbler extends Node


func set_active(active:bool):
	tumbler_active = active;
	
@export var tumbler_active:bool = true;
@export var tumbler:Node3D;
@export var tumble_corner: Node3D
@export var tumble_radius:float = 0.5;
@export var only_in_screen:VisibleOnScreenNotifier3D;

var target_tumble:Vector3 = Vector3.ZERO;
var current_tumble:Vector3 = Vector3.ZERO;
var current_tumble_vel:Vector3 = Vector3.ZERO;

@export var tumbling_positive_acceleration:float = 300;
@export var tumbling_negative_acceleration:float = 60;
@export var amount_instant_ratio:float = 4;
@export var velocity_decay_pressed:float = 30;
@export var velocity_decay_unpressed:float = 4.5;
@export var max_tumble:float = 100;
@export var max_tumble_velocity:float = 500;

func _process(delta: float) -> void:
	if tumbler.is_visible_in_tree() and GraphicSettingsManager.instance.get_wind_feedback_enabled():
		if only_in_screen == null or only_in_screen.is_on_screen():
			_tumble_process(delta);

func set_tumbler_active(active:bool):
	tumbler_active = active;
	
func set_target_tumble(force:Vector3):
	target_tumble = force;
	current_tumble = (target_tumble + current_tumble * amount_instant_ratio) / (1 + amount_instant_ratio);
	#var target_vel := \
			#(target_tumble - current_tumble) * initial_acceleration_relative + \
			#(target_tumble - current_tumble).normalized() * initial_acceleration_absolute;
	#current_tumble_vel
	
func _tumble_process(delta:float):
	if !target_tumble.is_zero_approx() and tumbler_active:
		current_tumble_vel = current_tumble_vel.move_toward(target_tumble, tumbling_positive_acceleration * delta);
		current_tumble += current_tumble_vel * delta;
		current_tumble_vel = current_tumble_vel.move_toward(Vector3.ZERO, current_tumble_vel.length() * velocity_decay_pressed * delta);
	else:
		current_tumble_vel = current_tumble_vel.move_toward(Vector3.ZERO, current_tumble.length() * tumbling_negative_acceleration * delta);
		current_tumble += current_tumble_vel * delta;
		current_tumble_vel = current_tumble_vel.move_toward(Vector3.ZERO, current_tumble_vel.length() * velocity_decay_pressed * delta);

	current_tumble = current_tumble.limit_length(max_tumble);	
	current_tumble_vel = current_tumble_vel.limit_length(max_tumble_velocity);	
		
	TransformUtils.tumble_rect(tumbler, current_tumble, tumble_corner.position)
