class_name Boss_Pirulito_Lamp extends Node3D

@onready var laser_area:Enemy_LaserArea = %Laser
@onready var center_position:Node3D = $"Laser Pivot_no";
@onready var laser_rotation:Node3D = $"Laser Pivot_no/Laser Rotation"
@onready var graphic: Node3D = $lamp_graphic
@onready var thunder_point: Marker3D = $lamp_graphic/ThunderPoint


@export var rotation_velocity_active:float = 7;
@export var rotation_velocity_inactive:float = 20;
@export var height_velocity:float = 2;

@export var height_curve:Curve;

@export var scaled_mesh_line:ScaledMeshLine;

var thunder_target:Node3D;
var remember_position:bool;
var flight_value:float;
var flight_origin:Vector3;
var flight_count:float;

var flight_ab:float;

var _current_laser_target:Vector3;

var _first_point:bool = false;
var _pointed:bool = false;

func _process(delta: float) -> void:
	_process_laser_active(delta);

	flight_count += delta * flight_value;
	position = flight_origin + abs(flight_value) * (
		1.25 * Vector3.UP * height_curve.sample(abs(flight_value)) + ## height base
		0.25 * Vector3.FORWARD + ## circle base
		(1.0 - flight_ab) * (1.75 * Vector3.RIGHT * flight_value) + ## A position -> circle base
		(flight_ab) * Vector3(0, 0, 0.75) + ## B position -> circle base
		0.125 * Vector3.UP * sin(flight_count * 4) + ## oscillating height
		Vector3(cos(flight_count * 0.5), 0, sin(flight_count * 0.5)) * 0.15) ## oscillating circle

func _is_valid()->bool:
	return get_tree() != null;

func set_light(on:bool):
	graphic.set_on(on);

func set_flight(on:bool, negative:bool):
	if not remember_position and on:
		flight_origin = position;
		remember_position = true;
	create_tween().tween_property(self, "flight_value", (-1 if negative else 1) if on else 0, 2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE);

func set_flight_alternate(on:bool):
	create_tween().tween_property(self, "flight_ab", 1 if on else 0, 1).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE);

func set_thunder_target(target:Node3D):
	scaled_mesh_line.set_target(thunder_point, target);

func point_laser_to(target:Vector3):
	_current_laser_target = target;
	if not _pointed:
		_first_point = true;
	_pointed = true;

func is_using_laser()->bool:
	return usingLaser;

func is_laser_active()->bool:
	return laser_area.is_active();

var usingLaser:bool;
var laserToken:int = 0;
func _laser_not_valid(token:int):
	return not _is_valid() or token != laserToken;

func use_laser(pre_time:float = 2, active_time:float = 1, post_time:float = 1):
	var tokenNow = Time.get_ticks_usec();
	usingLaser = true;
	laserToken = tokenNow;
	laser_area.pre_laser();
	#health.invulnerable = false;
	await get_tree().create_timer(pre_time).timeout;
	if _laser_not_valid(tokenNow): return;

	laser_area.start_laser();
	#health.invulnerable = false;
	await get_tree().create_timer(active_time).timeout;
	if _laser_not_valid(tokenNow): return;

	laser_area.stop_laser();
	#health.invulnerable = true;
	await get_tree().create_timer(post_time).timeout;
	if _laser_not_valid(tokenNow): return;
	usingLaser = false;

func start_laser_constant(pre_time:float = 2):
	usingLaser = true;
	laser_area.pre_laser();
	#health.invulnerable = false;
	await get_tree().create_timer(pre_time).timeout;
	if not _is_valid() or not usingLaser: return;

	laser_area.start_laser();

func stop_laser_constant():
	laser_area.stop_laser();
	#health.invulnerable = true;
	usingLaser = false;

func interrupt_laser():
	laser_area.stop_laser();
	usingLaser = false;
	laserToken = 0;

func _get_rotation_velocity(is_laser_active:bool)->float:
	return rotation_velocity_active if is_laser_active else rotation_velocity_inactive;

func _process_laser_active(delta:float):
	var transform_to_point:Transform3D = laser_area.global_transform;
	var target_direction:Vector3 = (_current_laser_target - transform_to_point.origin).normalized();
	target_direction.y = 0;
	var rotation_velocity := _get_rotation_velocity(is_laser_active());
	var axis := Vector3.UP;
	if _first_point:
		laser_rotation.global_basis = Basis.looking_at(-target_direction, Vector3.UP);
		_first_point = false;
	else:
		laser_rotation.transform = laser_rotation.transform.rotated(axis,
				TransformUtils.linear_rotation_angle_rad(laser_area.global_transform.basis.z, target_direction,
						axis, delta, rotation_velocity
				)
		);
