class_name Boss_Pirulito_Hand extends Node3D

@onready var arm_path:Path3D = $Path3D
@onready var arm:CSGPolygon3D = $Path3D/CSGPolygon3D;
@onready var laser_area:Enemy_LaserArea = %Laser
@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var health:Health = $MeshInstance3D/CharacterBody3D/Health

@export var rotation_velocity_active:float = 7;
@export var rotation_velocity_inactive:float = 20;
@export var height_velocity:float = 2;

var _current_laser_target:Vector3;


var hand_position:Vector3:
	get:
		return global_position;
	set(value):
		global_position = value;

var _arm_pit_position:Vector3;
var arm_pit_position:Vector3:
	get:
		return _arm_pit_position;
	set(value):
		_arm_pit_position = value;

func _ready():
	arm_path.curve = Curve3D.new();
	arm_path.curve.add_point(Vector3.ZERO);
	arm_path.curve.add_point(Vector3.FORWARD + Vector3.RIGHT * 0.5);
	arm_path.curve.add_point(Vector3.RIGHT);

	health.invulnerable = true;
	laser_area.stop_laser();


func redraw():
		var begin:Vector3 = Vector3.ZERO;
		var end:Vector3 = _arm_pit_position - hand_position;
		arm_path.curve.set_point_position(0, begin)
		arm_path.curve.set_point_position(1, (begin + end) * 0.5 + Vector3.FORWARD);
		arm_path.curve.set_point_in(1, end - begin);
		arm_path.curve.set_point_out(1, end - begin);
		arm_path.curve.set_point_position(2, end);


func _process(delta:float):
	_process_laser_active(delta);

func _is_valid()->bool:
	return get_tree() != null;

func point_laser_to(target:Vector3):
	_current_laser_target = target;

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
	health.invulnerable = false;
	await get_tree().create_timer(pre_time).timeout;
	if _laser_not_valid(tokenNow): return;

	laser_area.start_laser();
	health.invulnerable = false;
	await get_tree().create_timer(active_time).timeout;
	if _laser_not_valid(tokenNow): return;

	laser_area.stop_laser();
	health.invulnerable = true;
	await get_tree().create_timer(post_time).timeout;
	if _laser_not_valid(tokenNow): return;
	usingLaser = false;

func start_laser_constant(pre_time:float = 2):
	usingLaser = true;
	laser_area.pre_laser();
	health.invulnerable = false;
	await get_tree().create_timer(pre_time).timeout;
	if not _is_valid() or not usingLaser: return;

	laser_area.start_laser();

func stop_laser_constant():
	laser_area.stop_laser();
	health.invulnerable = true;
	usingLaser = false;

func interrupt_laser():
	laser_area.stop_laser();
	usingLaser = false;
	laserToken = 0;

func get_rotation_velocity(is_laser_active:bool)->float:
	return rotation_velocity_active if is_laser_active else rotation_velocity_inactive;

func _process_laser_active(delta:float):
	var transform_to_point:Transform3D = laser_area.global_transform;

	var targetHeight:float = 1 if is_using_laser() else 3;
	var currentHeight:float = transform_to_point.origin.y;
	var heightTranslation:float = height_velocity * sign(targetHeight - currentHeight) * delta;

	var target_direction:Vector3 = (_current_laser_target - transform_to_point.origin).normalized();
	target_direction.y = 0;
	var rotation_velocity := get_rotation_velocity(is_laser_active());
	var axis := Vector3.UP;
	self.transform = self.transform.rotated(axis,
			TransformUtils.linear_rotation_angle_rad(laser_area.global_transform.basis.z, target_direction,
					axis, delta, rotation_velocity
			)
	).translated(Vector3.UP * heightTranslation);


func _on_health_dead(health:Health):
	interrupt_laser();
	health.restore();
