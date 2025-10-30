extends Area3D

@export var speed:float = 4;
@export var speed_absolute:float = 4;
@export var rotation_speed_angle_min:float = 10;
@export var rotation_speed_angle_max:float = 45;
@export var distance_player_min:float = 3;
@export var distance_player_max:float = 9;
@export var damage:int = 1;
@onready var model:Graphic_Car = $Model

## Callable: returns Vector3 of target's global position
var turn_target_getter:Callable;

var try_before:bool;

func _ready():
	model.set_lights(true);
	try_before = randf() < 0.5;


func _process(delta:float):
	if turn_target_getter.is_valid():
		var target:Vector3 = turn_target_getter.call();
		var distance := global_position - target;
		var direction := global_basis.z;
		var wantedAngle = -direction.signed_angle_to(distance, Vector3.UP);
		if wantedAngle != 0:
			global_basis = global_basis.rotated(Vector3.UP, sign(wantedAngle) * deg_to_rad(get_current_rotation_speed(distance)) * delta);
	global_position += global_basis.z.normalized() * speed * delta;
	global_position += Vector3.BACK * speed_absolute * delta;

func get_current_rotation_speed(targetDistance:Vector3)->float:
	var amount:float = inverse_lerp(distance_player_min, distance_player_max, targetDistance.length());
	amount = clampf(amount, 0.0, 1.0);
	if try_before:
		return lerp(rotation_speed_angle_min, rotation_speed_angle_max, amount);
	else:
		return lerp(rotation_speed_angle_min, rotation_speed_angle_max, 1.0 - amount);


func _on_body_entered(body):
	model.hit(body)
	Health.Damage(body, Health.DamageData.new(1, self));


func _on_visible_on_screen_notifier_3d_screen_exited():
	queue_free();


func _on_health_hit(damage, health):
	model.hit(damage.origin);
