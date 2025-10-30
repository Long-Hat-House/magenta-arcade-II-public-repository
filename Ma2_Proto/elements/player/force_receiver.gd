class_name ForceReceiver extends Node3D


signal force_received(force:Vector3, delta:float);
@export var always_emit_even_if_zero:bool = true;
var frame_force:Vector3;
var was_zero:bool = false;
@export var force_is_the_average:bool = true;
@export var process_every_n_frames:int = 4;

static var last_index:int;
var receiver_index:int;

var _last_frame_force:Vector3;

func _ready() -> void:
	receiver_index = last_index;
	last_index += 1;

func _process(delta: float) -> void:
	if ((Engine.get_frames_drawn() + receiver_index) % process_every_n_frames) == 0: ## This is called a lot. Optimizing
		var i:int = 0;
		for generator in ForceGenerator.generators:
			_apply_force_from_generator(generator);
			i += 1;

		if force_is_the_average and i > 1:
			frame_force /= i;
		_last_frame_force = frame_force;
	else:
		frame_force = _last_frame_force;
	_consume_force(delta);

func _consume_force(delta:float)->void:
	if frame_force.length_squared() > 0.01:
		force_received.emit(frame_force, delta);
		frame_force = Vector3.ZERO;
		was_zero = false;
	else:
		if always_emit_even_if_zero:
			force_received.emit(Vector3.ZERO, delta);
		elif not was_zero: ##emit the first zero only then
			force_received.emit(Vector3.ZERO, delta);
			was_zero = true;


func apply_force(force:Vector3):
	frame_force += force;

func get_max_force()->float:
	return ForceGenerator.FORCE_MAX;

func _apply_force_from_generator(generator:ForceGenerator):
	apply_force(generator.get_force_now(self));
