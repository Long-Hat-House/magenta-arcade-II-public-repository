@tool
class_name ControlShaker
extends Control

@export var shake_amplitude_ratio : float = 1
@export var shake_amplitude : float = 10.0
@export var shake_frequency : float = 10.0
@export var enabled : bool = true;
var last_value : float
var noise:FastNoiseLite = FastNoiseLite.new()

var _random_time:float

func _ready() -> void:
	_random_time = randf()*100

func _process(delta: float):
	var shake_val = shake_amplitude * shake_amplitude_ratio
	if shake_val == 0 or not enabled:
		position = Vector2.ZERO
		return

	var time:float = _random_time + Time.get_ticks_msec()
	var sin_val = sin(shake_frequency * (0 + 100 + time));
	var direction:Vector2 = Vector2(noise.get_noise_2d(0, time) - 0.5, noise.get_noise_2d(100, time) - 0.5);
	direction = direction.normalized()
	var dif = direction * sin_val;
	position = dif * shake_val;

	#var random_offset = Vector2(randf_range(-shake_amplitude, shake_amplitude), randf_range(-shake_amplitude, shake_amplitude))
	#position = random_offset * delta * sin(Time.get_ticks_msec() * shake_frequency)

func set_shake_amplitude_ratio(ratio:float):
	shake_amplitude_ratio = ratio

func set_shake_amplitude(amplitude: float):
	shake_amplitude = amplitude

func set_shake_frequency(frequency: float):
	shake_frequency = frequency
