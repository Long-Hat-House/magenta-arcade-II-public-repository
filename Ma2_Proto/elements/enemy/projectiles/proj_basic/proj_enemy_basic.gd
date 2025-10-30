class_name ProjEnemyBasic extends Area3D

@export var relativeVelocity:Vector3;
@export var amountDamage:float = 0.2;
@export var global_tag:String;
@export var time_to_expire:float;
@export var accompany_screen:bool;
@export var explode_on_hit:bool = true;
@export var vfx_explode:PackedScene;
@export var vfx_create:PackedScene;
@export var target_height:float = 0.5;
@export var velocity_to_target_height:float = 0;
@onready var graphic: Node3D = %Graphic

var expire_count:float;

var speedMultiplier:float = 1;
var speedMultiplierAcceleration:float = 0;

var readied:bool = false;

func _physics_process(delta:float) -> void:
	walk(delta);

	if time_to_expire > 0:
		expire_count += delta;
		if expire_count >= time_to_expire:
			explode();
			vanish();

func set_velocity_multiplier(mult:float):
	speedMultiplier = mult;

func set_velocity_multiplier_acceleration(accel:float):
	speedMultiplierAcceleration = accel;

func accelerate_to_been_born_in(usec_mark:int)->void:
	walk((Time.get_ticks_usec() - usec_mark) * 0.000001);

func walk(delta:float) -> void:
	var translation:Vector3 = Vector3.ZERO;
	var velocity = global_transform.basis * relativeVelocity * speedMultiplier;
	speedMultiplier += speedMultiplierAcceleration * delta;

	translation += velocity * delta;

	if velocity_to_target_height != 0:
		translation += Vector3.UP * (move_toward(position.y, target_height, velocity_to_target_height * delta) - position.y);

	position += translation;


func _process(delta: float) -> void:
	if accompany_screen and LevelCameraController.instance:
		position += LevelCameraController.instance.last_frame_movement;


func _ready():
	readied = true;

func _enter_tree() -> void:
	if not readied:
		await ready;
	expire_count = 0;
	await get_tree().process_frame;
	if vfx_create:
		InstantiateUtils.InstantiateInTree(vfx_create, self);
	graphic.basis = Basis.looking_at(relativeVelocity);

func _exit_tree():
	speedMultiplier = 1;
	speedMultiplierAcceleration = 0;

func _on_visible_notifier_screen_exited():
	vanish();

func attack(node:Node)->bool:
	var dd := Health.DamageData.new(amountDamage, self, false, false);
	dd.immunityTime = 0;
	return Health.Damage(node, dd, true);

func _on_body_entered(body):
	attack(body);
	if explode_on_hit:
		explode();
		vanish();

func _on_area_entered(area: Area3D) -> void:
	if attack(area) and explode_on_hit:
		explode();
		vanish();

func explode():
	if vfx_explode:
		InstantiateUtils.InstantiateInSamePlace3D(vfx_explode, self);

func vanish():
	ObjectPool.repool(self);
