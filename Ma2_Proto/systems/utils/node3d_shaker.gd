@tool
class_name Node3DShaker extends Node3D

@export var stop_shake_on_ready:bool;
@export var noise_texture : Texture2D
@export var property_vector3:StringName = "position";
@export var extra_properties:Array[StringName];
@export var shake_amplitude_ratio : float = 1
@export var shake_amplitude : float = 0.5
@export var shake_frequency : float = 1
@export var shake_x : bool = true
@export var shake_y : bool = true
@export var shake_z : bool = true
@export var dont_shake_itself:bool;
@export var extra_shakers:Array[Node3D];
@export var shake_difference_frequency:float = 0.2;

@onready var x_dir:Vector2 = Vector2.from_angle(randf() * 2 * PI)
@onready var y_dir:Vector2 = Vector2.from_angle(randf() * 2 * PI)
@onready var z_dir:Vector2 = Vector2.from_angle(randf() * 2 * PI)

var noise_image : Image

func _ready() -> void:
	noise_texture.changed.connect(_on_noise_texture_changed)
	_on_noise_texture_changed()
	if stop_shake_on_ready and not Engine.is_editor_hint():
		stop_shake();

func _on_noise_texture_changed():
	noise_image = noise_texture.get_image()

func _process(delta: float):
	if !noise_image: return

	var i:int = 1;
	for shaker in extra_shakers:
		shake(property_vector3, shaker, i * shake_difference_frequency)
		for p in extra_properties:
			shake(p, shaker, i * shake_difference_frequency);
		i+=1;

	if dont_shake_itself:
		self.set(property_vector3, 0.0);
		return;
	shake(property_vector3, self, 0.0);
	for p in extra_properties:
		shake(p, self, 0.0);


func shake(property_vec3:StringName, shaked:Node3D, offset:float):
	var shake_distance = shake_amplitude * shake_amplitude_ratio
	if shake_distance == 0:
		shaked.set(property_vec3, Vector3.ZERO);
		return

	var time:float = (Time.get_ticks_msec() + offset * 1000.0) * shake_frequency;

	var x:float = noise_image.get_pixelv((z_dir * time).posmodv(noise_image.get_size())).r - 0.5 if shake_x else 0.0
	var y:float = noise_image.get_pixelv((y_dir * time).posmodv(noise_image.get_size())).r - 0.5 if shake_y else 0.0
	var z:float = noise_image.get_pixelv((x_dir * time).posmodv(noise_image.get_size())).r - 0.5 if shake_z else 0.0

	var direction:Vector3 = Vector3(x, y, z);

	shaked.set(property_vec3, direction * shake_distance);

func stop_shake():
	shake_amplitude_ratio = 0;

func shake_tweener_in(tween:Tween, duration_in:float, final_value:float = 1.0)->MethodTweener:
	#print("shake IN of %s: %s [%s]" % [get_parent(), shake_amplitude_ratio, Engine.get_frames_drawn()]);
	return tween.tween_method(set_shake_amplitude_ratio, shake_amplitude_ratio, final_value, duration_in);

func shake_tweener_out(tween:Tween, duration_out:float, initial_value:float = -1.0)->MethodTweener:
	if initial_value < 0:
		initial_value = shake_amplitude_ratio;
	#print("shake OUT of %s: %s [%s]" % [get_parent(), shake_amplitude_ratio, Engine.get_frames_drawn()]);
	return tween.tween_method(set_shake_amplitude_ratio, initial_value, 0.0, duration_out);

func set_shake_amplitude_ratio(ratio:float):
	shake_amplitude_ratio = ratio
	#print("shake amplitude of %s: %s [%s]" % [get_parent(), ratio, Engine.get_frames_drawn()]);

func set_shake_amplitude(amplitude: float):
	shake_amplitude = amplitude

func set_shake_frequency(frequency: float):
	shake_frequency = frequency
