class_name FloatEffect extends Node3D

@export var amplitude:Vector3 = Vector3.UP;
@export var revolutionsPerSecond:float = 1;
@export_range(0,1) var offset01:float;
@export var random_offset:bool;

@export var ellipsis_up:Vector3 = Vector3.BACK;
@export var ellipsis_amplitude:Vector2 = Vector2(0,0);
@export var ellipsis_pow:Vector2 = Vector2(1,1);
@export var ellipsis_frequency:Vector2 = Vector2(1,1);

var originalPosition:Vector3;
var t:float;
var offset:float;

func _ready():
	originalPosition = self.position;
	#print("original position is %s" % [originalPosition]);
	if random_offset:
		offset01 = randf();
	offset = offset01 * PI * 2;
	t = 0;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	self.position = originalPosition + amplitude * sin(t + offset) +\
			VectorUtils.get_ellipsis_point(t, ellipsis_pow, ellipsis_frequency, ellipsis_up, ellipsis_amplitude);
	t += delta * revolutionsPerSecond * 2 * PI;
