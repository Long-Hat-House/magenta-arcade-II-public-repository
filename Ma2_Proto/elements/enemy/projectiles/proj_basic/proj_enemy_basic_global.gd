class_name ProjEnemyBasic_Global extends Area3D

@export var relativeVelocity:Vector3;
@export var amountDamage:int = 1;
@export var _global_tag:String;

var tag:String:
	get:
		return _global_tag;
	set(value):
		_global_tag = value;
		ProjEnemyBasic_Global._check_tag(value);
		

class GlobalData:
	var speed_multiplier:float = 1;
	var can_leave_screen:bool = false;
	
static var common_global_data:GlobalData = GlobalData.new();
static var global_projectile_data:Dictionary = {};

var speedMultiplier:float = 1;
var speedMultiplierAcceleration:float = 0;

func get_global_data()->GlobalData:
	if _global_tag and not _global_tag.is_empty():
		return get_data(_global_tag);
	else:
		return common_global_data;
		
func _ready() -> void:
	ProjEnemyBasic_Global._check_tag(_global_tag);
		
static func get_data(_tag:String)->GlobalData:
	ProjEnemyBasic_Global._check_tag(_tag);
	return global_projectile_data[_tag];

func _physics_process(delta:float) -> void:
	var global_data := get_global_data();
	var velocity = global_transform.basis * relativeVelocity * speedMultiplier * global_data.speed_multiplier;
	speedMultiplier += speedMultiplierAcceleration * delta;
	
	position += velocity * delta;
	
static func _check_tag(_tag:String):
	if not _tag.is_empty() and not global_projectile_data.has(_tag):
		global_projectile_data[_tag] = GlobalData.new();
	
func _exit_tree():
	speedMultiplier = 1;
	speedMultiplierAcceleration = 0;
	
func _on_visible_notifier_screen_exited():
	if should_repool_on_screen_exit():
		ObjectPool.repool(self);
	
func should_repool_on_screen_exit()->bool:
	return not get_global_data().can_leave_screen;

func _on_body_entered(body):
	var node:Node = body as Node;
	node = node.get_parent();
	Health.Damage(node, Health.DamageData.new(amountDamage, self), true);
	ObjectPool.repool(self);
