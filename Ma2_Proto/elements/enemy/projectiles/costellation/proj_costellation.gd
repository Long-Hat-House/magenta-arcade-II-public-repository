class_name Projectile_Costellation extends LHH3D

const PROJ_COSTELLATION = preload("res://elements/enemy/projectiles/costellation/proj_costellation.tscn")
const PROJ_ENEMY_BASIC_COSTELLATION = preload("res://elements/enemy/projectiles/proj_basic/proj_enemy_basic_costellation.tscn")

static func create_constellation_circle_custom(
		proj:PackedScene, amount:int, arc_rad:float, range:float, object_pooling:bool,
		rotation_per_second:float = 0, scale_per_second:Vector3 = Vector3(1,0,1)
		)->Node3D:
	var costellation = PROJ_COSTELLATION.instantiate();
	costellation.ready.connect(func():
		costellation.create_projectiles_circle(proj, amount, arc_rad, range, object_pooling);
		costellation.scale_direction = scale_per_second.normalized();
		costellation.expand(scale_per_second.length(), rotation_per_second);
		, CONNECT_ONE_SHOT);
	return costellation;

static func create_costellation_circle(amount:int, arc_rad:float, range:float, rotation_per_second:float = 0, scale_per_second:Vector3 = Vector3(1,0,1))->Node3D:
	return create_constellation_circle_custom(PROJ_ENEMY_BASIC_COSTELLATION, amount, arc_rad, range, true, rotation_per_second, scale_per_second);


const SMALL:float = 0.001;

@export var scale_expand_velocity:float = 1.0;
@export var rotation_angle_velocity:float;
var rotation_rad_velocity:float;
@export var scale_direction:Vector3 = Vector3(1,0,1);
@export var scale_max:float = 100.0;

@export var projectile_scene:PackedScene;
@export var object_pooling:bool = true;
@export var initial_number_of_projectiles:int;
@export var initial_base_range:float;

@export var follow_camera:bool;

const uses_object_pooling:bool = false;

signal projectile_instantiated(instance:Node3D, index:int);
signal projectile_dead(instance:Node3D, index:int);

func _ready():
	rotation_rad_velocity = deg_to_rad(rotation_angle_velocity);

	if projectile_scene != null:
		create_projectiles_circle(projectile_scene, deg_to_rad(90.0), initial_number_of_projectiles, initial_base_range, object_pooling);
		expand(scale_expand_velocity, rotation_rad_velocity);

func _physics_process(delta: float) -> void:
	if follow_camera:
		position += LevelCameraController.instance.last_physics_step_movement;


var amount_projectiles_left:int;

func start_marking_projectiles():
	self.amount_projectiles_left = 0;

func mark_projectile_started():
	self.amount_projectiles_left += 1;
	#print("[COSTELLATION] Projectile entered %s" % [self.amount_projectiles_left]);

func delete():
	self.queue_free();

func mark_projectile_ended():
	self.amount_projectiles_left -= 1;
	#print("[COSTELLATION] Projectile left %s" % [self.amount_projectiles_left]);
	if self.amount_projectiles_left <= 0:
		#print("[COSTELLATION] DELETED");
		delete();

func create_projectiles_line(scene:PackedScene, amount:int, from:Vector3, to:Vector3):
	var segment:Vector3 = to - from;
	var i:int = 0;
	start_marking_projectiles();
	while i < amount:
		var inst:Node3D = InstantiateUtils.Instantiate(scene, self, true);
		if amount == 1:
			inst.position = from.lerp(to, 0.5);
		else:
			inst.position = from + segment * (i / (amount - 1))
		add_child(inst);
		projectile_instantiated.emit(inst, i);
		mark_projectile_started();
		inst.tree_exiting.connect(func():
			self.projectile_dead.emit(inst, i);
			mark_projectile_ended();
			, CONNECT_ONE_SHOT);

func create_projectiles_circle(scene:PackedScene, amount:int, arc_rad:float, range:float, use_object_pooling:bool):
	var angle:float;
	var initial_angle:float;
	if amount > 0:
		angle = arc_rad / (amount - 1.0);
		initial_angle = -arc_rad * 0.5;
	else:
		angle = 0;
		initial_angle = 0;
	var i:int = 0;
	start_marking_projectiles();
	while i < amount:
		var inst:Node3D;
		if use_object_pooling:
			inst = ObjectPool.instantiate(scene).node;
		else:
			inst = scene.instantiate();
		inst.position = Vector3(sin(initial_angle + angle * i), 0, cos(initial_angle + angle * i)) * range;
		add_child(inst);
		projectile_instantiated.emit(inst, i);
		mark_projectile_started();
		inst.tree_exited.connect(func():
			self.projectile_dead.emit(inst, i);
			mark_projectile_ended();
			CONNECT_ONE_SHOT)
		i += 1;


func expand(scale_per_second:float, rotation_per_second:float):
	if scale_per_second != 0:
		scale = Vector3.ONE * SMALL;
		var sca_t := create_tween();
		sca_t.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS);
		sca_t.tween_property(self, "scale", Vector3.ONE, 1.0 / scale_per_second).set_trans(Tween.TRANS_LINEAR);
		sca_t.tween_property(self, "scale", Vector3.ONE + scale_direction * scale_max, scale_max / scale_per_second).set_trans(Tween.TRANS_LINEAR);

	if rotation_per_second != 0:
		var rot_t := create_tween();
		rot_t.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS);
		rot_t.tween_property(self, "rotation", Vector3.UP * rotation_per_second, 1.0).set_trans(Tween.TRANS_LINEAR).as_relative();
		rot_t.set_loops(-1);
