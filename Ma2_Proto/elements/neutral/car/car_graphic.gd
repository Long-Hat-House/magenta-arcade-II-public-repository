class_name Graphic_Car extends LHH3D

@onready var _center_of_mass:Node3D = $"CenterOfMass";
@onready var _box_body:Node3D = $"Box";
@onready var _model:Node3D = $"Box";
@onready var _mesh_fine:Graphic_Car_Armor = $"Box/Fine"
@onready var _mesh_destroyed:Graphic_Car_Armor = $"Box/Destroyed"
@onready var _mesh_supports:Graphic_Car_Support = $"Box/Supports"

var originalBasis:Basis;

var _timeTolerance:float = 0.03;
var _hitMark:float;

@export var hit_time:float = 0.4;
@export var force_intensity:float = 0.11;
@export var rotating_hit_time:float = 3.5;
@export var rotating_circular_time:float = 7;
@export var rotating_force_intensity = -0.05;
const possible_colors:ColorPairList = preload("res://elements/neutral/car/car_possible_colors.tres");

var damageDirection:Vector3;
var force:float = 0;
var rotForce:float = 0;
var count:float = 0;

var canBeHit:bool = true;

static var car_seed:int = 256;

func _ready():
	if hit_time == 0:
		hit_time = 1;
	originalBasis = _box_body.basis;
	var colorPair:ColorPair = get_random_color_pair(car_seed);
	_mesh_supports.randomize_supports(car_seed);
	_mesh_fine.set_color(colorPair.color1, colorPair.color2);
	_mesh_destroyed.set_color(colorPair.color1, colorPair.color2);
	car_seed += 1;

func get_random_color_pair(seed:int)->ColorPair:
	var colorIndex:int = rand_from_seed(seed)[0] % possible_colors.list.size();
	var pair = possible_colors.list[colorIndex];
	return pair; #TODO has to do duck typing here for no reason?

func _process(delta:float):
	_express_force(force, rotForce, count);
	#force += delta;
	force = decrease_force(force, hit_time, delta);
	rotForce = decrease_force(rotForce, rotating_hit_time, delta)
	count += delta;

func decrease_force(f:float, time:float, delta:float)->float:
	if f > 0:
		f -= delta / time;
		if f <= 0: f = 0;
	return f;

func _express_force(force:float, rot_force:float, count:float):
	var finalForceVec:Vector3 = Vector3.UP.slerp(damageDirection, force * force_intensity);

	var t:float = count * rotating_circular_time;
	finalForceVec += Vector3(sin(t), 0, cos(t)) * rot_force * rot_force * rotating_force_intensity;

	_box_body.basis = BasisUtils.rotate_from_up_to(finalForceVec).orthonormalized();

func hit(origin:Node3D):
	var timeNow:int = Time.get_ticks_msec();
	if canBeHit and (timeNow - _hitMark) > 1000 * _timeTolerance:
		_hitMark = timeNow;
		var originPosition:Vector3 = origin.global_position;

		damageDirection = (_center_of_mass.global_position - originPosition);
		damageDirection = _center_of_mass.global_basis.inverse() * damageDirection;
		damageDirection.y = 0;

		force = 1;
		rotForce = 1;

func relax():
	force = 0;
	rotForce = 0;

func set_possible_to_hit(possible:bool):
	canBeHit = possible;

func _on_health_hit(damage:Health.DamageData , health:Health):
	hit(damage.origin);

func _on_health_dead(health:Health):
	walk_health_phase();
	health.set_immunity_mark(0.5);
	health.restore();

enum HealthPhase
{
	Fine,
	Crashed,
	Destroyed
}
var currentHealthPhase:HealthPhase;
func walk_health_phase(amount:int = 1):
	currentHealthPhase += amount;
	match currentHealthPhase:
		HealthPhase.Fine:
			_mesh_fine.visible = true;
			_mesh_destroyed.visible = false;
		HealthPhase.Crashed:
			_mesh_fine.visible = false;
			_mesh_destroyed.visible = true;
		HealthPhase.Destroyed:
			_mesh_fine.visible = false;
			_mesh_destroyed.visible = true;

func get_current_health_phase()->HealthPhase:
	return currentHealthPhase;

func set_lights(lights:bool):
	print("[CRAZY CAR] setting lights!");
	_mesh_fine.set_light(lights);
	_mesh_destroyed.set_light(lights);
