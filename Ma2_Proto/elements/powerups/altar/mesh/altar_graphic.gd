class_name Graphic_Altar extends LHH3D

@export_group("Object References Setup")
@export var instantiate_place:Node3D

@export var altar_box:Node3D
@export var offset:Vector3;
@export var altar_ornament:Node3D
@export var altar_door_l:Node3D
@export var altar_door_r:Node3D
@export var ornament_transform:Node3D
@export var door_l_transform:Node3D
@export var door_r_transform:Node3D
@export var inside_sprite_box:Sprite3D
@export var inside_sprite_l:Sprite3D
@export var inside_sprite_r:Sprite3D
@export var mesh_vanish:MeshInstance3D
@export var sfx_loop_open:AkEvent3DLoop

var transparency_inside:float:
	get:
		return mesh_vanish.get_instance_shader_parameter(&"Transparency");
	set(value):
		mesh_vanish.set_instance_shader_parameter(&"Transparency", value);
		mesh_vanish.visible = value != 1.0;

var closedR:float = 180;
var closedL:float = -180;
var openR:float = 25;
var openL:float = -25;

const TIME_BETWEEN_CLOSED_SFX:float = 1
var _time_since_last_closed_sfx:float = 0
var _played_closed_sfx:bool = false

var opened:bool;
var velocity:float = 2.5;
var moving:bool:
	get:
		return velocity > 0;

@export_category("Altar Animation Settings")
@export var closedForceL:Vector3 = Vector3(0,0,100);
@export var openedForceL:Vector3 = Vector3(0,0,-2);
@export var openedImpulseL:Vector3 = Vector3(0,0,-15);
@export var openedVelocityL:Vector3 = Vector3(0,0,0);

@export var instantiate_place_openUpTiming:float = 0.75;
@export var min_velocity:float = 1;
@export var max_velocity:float = 5;
@export var min_shake:float = 8;
@export var max_shake:float = 20;
@export var shake_amplitude:float = 5;

@export var rotation_x_base_walking = 12.5;
@export var rotation_x_base_idle = 0;
@export var rotation_x_base_stopped = 0;
var c:float;
var _old_position:Vector3;
var angle_vibration_rad:float;
var old_angle:float;


var box_rotation:VelValue = VelValue.new(0,0);
var target_box_rotation:float;

var door_r_rotation:VelValue = VelValue.new(0,0);
var target_rotation_r:float;
var door_l_rotation:VelValue = VelValue.new(0,0);
var target_rotation_l:float;

var instantiate_place_tween:Tween

var pressed:bool;

func _ready():
	inside_sprite_box.pixel_size = 2.0 / inside_sprite_box.texture.get_width();
	inside_sprite_l.pixel_size = 1.0 / inside_sprite_l.texture.get_width();
	inside_sprite_r.pixel_size = 1.0 / inside_sprite_r.texture.get_width();

	altar_box.position += offset;

	_played_closed_sfx = true #avoids playing closed in the beginning
	set_open(false, true);

	door_r_rotation.set_value_vel(target_rotation_r, 0);
	door_l_rotation.set_value_vel(target_rotation_l, 0);

	transparency_inside = 0;

func is_open()->bool:
	return opened;

func set_moving(value:bool):
	moving = value;

func set_velocity(value:float):
	velocity = value;

func set_pressed(value:bool):
	pressed = value;

func set_altar_transform(where:Transform3D, delta:float):
	self.global_transform = where;
	pass;

func set_open(value:bool, force:bool = false):
	if !force && (opened == value):
		return

	opened = value;

	if instantiate_place_tween:
		instantiate_place_tween.kill()

	instantiate_place_tween = create_tween()

	var min_effect:float

	if opened:
		if sfx_loop_open: sfx_loop_open.start_loop()
		min_effect = 300
		instantiate_place.process_mode = Node.PROCESS_MODE_INHERIT
		target_rotation_l = openL;
		target_rotation_r = openR;

		instantiate_place_tween.tween_property(instantiate_place, "scale", Vector3.ONE, instantiate_place_openUpTiming).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE);
		instantiate_place_tween.parallel().tween_property(self, "transparency_inside", 1.0, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC);
	else:
		if sfx_loop_open: sfx_loop_open.stop_loop()
		min_effect = 50
		instantiate_place.process_mode = Node.PROCESS_MODE_DISABLED

		target_rotation_l = closedL;
		target_rotation_r = closedR;
		instantiate_place_tween.tween_property(instantiate_place, "scale", Vector3(1,0.1,1), 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE);
		instantiate_place_tween.parallel().tween_property(self, "transparency_inside", 0.0, 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE);


	door_r_rotation.vel = (target_rotation_r - door_r_rotation.value) * 5;
	door_l_rotation.vel = (target_rotation_l - door_l_rotation.value) * 5;

	if abs(door_l_rotation.vel) < min_effect:
		door_r_rotation.vel = -min_effect + randf() * min_effect * 0.2
		door_l_rotation.vel = min_effect + randf() * min_effect * 0.2

func get_instantiate_place()->Node3D:
	return instantiate_place;


func _process(delta:float):
	var angle_dif:float = angle_vibration_rad - old_angle;
	old_angle = angle_vibration_rad;
	if opened:
		door_l_rotation.value += angle_dif * randf_range(50,200);
		door_r_rotation.value += angle_dif * randf_range(50,200);
	else:
		door_l_rotation.value += angle_dif * randf_range(10,20);
		door_r_rotation.value += angle_dif * randf_range(10,20);

	if self.moving and not pressed:
		_vibration_process(delta);
	else:
		_relaxation_process(delta);

	box_rotation._process(10, 2, target_box_rotation, delta);
	door_l_rotation._process(randf_range(2.5,15), 2, target_rotation_l, delta);
	door_l_rotation._clamp_reflect(-180,35, 50);
	door_r_rotation._process(randf_range(2,15.5), 2, target_rotation_r, delta);
	door_r_rotation._clamp_reflect(-35,180, 50);

	#print("%s to %s, %s to %s, %s to %s" % [box_rotation, target_box_rotation, door_l_rotation, target_rotation_r, door_r_rotation, target_rotation_l]);

	altar_box.rotation.x = deg_to_rad(box_rotation.get_value()) + angle_vibration_rad;
	altar_ornament.transform = altar_box.transform * ornament_transform.transform;
	altar_door_l.transform = altar_box.transform * door_l_transform.transform.rotated_local(Vector3.FORWARD, deg_to_rad(door_l_rotation.get_value()));
	altar_door_r.transform = altar_box.transform * door_r_transform.transform.rotated_local(Vector3.FORWARD, deg_to_rad(door_r_rotation.get_value()));

	_time_since_last_closed_sfx += delta
	var dist_l = abs(door_l_rotation.get_value() - closedL)
	var dist_r = abs(door_r_rotation.get_value() - closedR)
	if (dist_l < 10 || dist_r < 10 ):
		if _time_since_last_closed_sfx > TIME_BETWEEN_CLOSED_SFX && !_played_closed_sfx:
			_played_closed_sfx = true
			sfx_loop_open.post_one_shot_event(AK.EVENTS.PLAY_INT_ALTAR_CLOSE_END)
			_time_since_last_closed_sfx = 0
	else:
		_played_closed_sfx = false

class VelValue:
	var value:float
	var vel:float

	func _init(v:float, vel:float) -> void:
		set_value_vel(v, vel)

	func set_value(v:float) -> void:
		vel = v - value
		value = v

	func set_value_vel(v:float, vel:float)->void:
		value = v
		self.vel = vel

	func _process(increase:float, friction:float, target:float, delta:float):
		vel += (target - value) * increase * delta
		value += vel * delta
		vel -= vel * friction * delta

	func _clamp_reflect(min:float, max:float, multiplier:float):
		var clamped_value := clampf(value, min, max)
		if clamped_value != value:
			vel -= (value - clamped_value) * multiplier
			value = clamped_value

	func _to_string() -> String:
		return "%s (%s)" % [value, vel]

	func get_value()->float:
		return value

func _vibration_process(delta:float):
	var velocity_value:float = inverse_lerp(min_velocity, max_velocity, clamp(velocity, min_velocity, max_velocity));
	c += delta * lerp(min_shake, max_shake, velocity_value);
	angle_vibration_rad = deg_to_rad(_get_rotation_base(delta, true, pressed) + (sin(c) * 2 + sin(c * 2 + PI * 0.15) * shake_amplitude));


func _relaxation_process(delta:float):
	angle_vibration_rad = _get_rotation_base(delta, false, pressed);


func _get_rotation_base(delta:float, walking:bool, pressed:bool):
	if pressed: return rotation_x_base_stopped;
	else:
		if walking: return rotation_x_base_walking;
		else: return rotation_x_base_idle;
