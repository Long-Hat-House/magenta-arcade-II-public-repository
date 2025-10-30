class_name AI_Cannon extends Marker3D

@export var disabled:bool = false;
@export var projectile:PackedScene;
@export var firstDelay:float = 0.75;
@export var delayBetweenProjectiles:float = 1.65;
@export var delay_after_shooting:float = 0;
@export var projectile_speed_multiplier:float = 1;
@export var save_position_in_interval_beginning:bool;
## The delay interval, 0 means shoot, 1 means one delay, and it cycles. -1 will emit from the interval_emmiter!
@export var shoot_delay_interval:Array[int] = [0, 1];
@export var lerpAngle:float = 0;
@export var lookAtPlayer:bool;
@export var vfxOnDie:PackedScene;
@export var absolute_forward:Vector3 = Vector3.FORWARD;
@export var max_angle_from_front:float = 90;

var max_angle_from_front_radians:float;
var original_position:Transform3D;

var count:float = 0;
var inScreen:bool = false;
var shoot_count:int = 0;

signal shot;
signal shot_projectile(proj:Node3D);
signal interval_emmiter;
signal interval_begin;

func _ready() -> void:
	count = firstDelay;
	shoot_count = 0;
	max_angle_from_front_radians = deg_to_rad(max_angle_from_front);
	if lookAtPlayer:
		self.global_transform.basis = self.global_transform.basis.looking_at(Vector3.FORWARD);

func set_delay(delay:float):
	firstDelay = delay;
	count = delay;

func _physics_process(delta: float) -> void:
	##shooting
	if inScreen:
		count -= delta;
	if disabled:
		return;
	while count < 0:
		if save_position_in_interval_beginning and is_interval_beginning(shoot_count):
			original_position = get_instantiate_place().global_transform;
			interval_begin.emit();
		var delay_or_shoot:int = get_delay_or_shoot(shoot_count);
		shoot_count += 1;
		if delay_or_shoot < 0:
			interval_emmiter.emit();
		else:
			if delay_or_shoot == 0:
				shoot();
				count += delay_after_shooting;
			count += delayBetweenProjectiles * delay_or_shoot;

	##looking at player
	if lookAtPlayer:
		var playerDist:Vector3 = Player.get_closest_direction(self.global_transform.origin);
		var currentDist = self.global_transform.basis.z;
		var lerpedDist:Vector3;

		if lerpAngle != 0:
			lerpedDist = Math.vector3_rotate_to(-currentDist, -playerDist, lerpAngle * delta);
		else:
			lerpedDist = -playerDist;

		if max_angle_from_front < 180:
			var angle_from_forward:float = absolute_forward.signed_angle_to(lerpedDist, Vector3.UP);
			if absf(angle_from_forward) > max_angle_from_front_radians:
				lerpedDist = absolute_forward.rotated(Vector3.UP, signf(angle_from_forward) * max_angle_from_front_radians)

		if lerpedDist.length() != 0:
			var targetBasis:Basis = self.global_transform.basis.looking_at(lerpedDist);
			self.global_transform.basis = targetBasis;

func shoot() -> void:
	var proj:Node3D = InstantiateUtils.Instantiate(projectile, LevelManager.current_level, true);
	#self.get_tree().root.add_child(proj);
	if save_position_in_interval_beginning:
		proj.global_transform = original_position;
	else:
		proj.global_transform = get_instantiate_place().global_transform;
	if proj is ProjEnemyBasic:
		proj.speedMultiplier = projectile_speed_multiplier;
	shot.emit();
	shot_projectile.emit(proj);

func get_instantiate_place()->Node3D:
	return $InstantiatePlace as Node3D;

func _on_health_dead(health):
	if vfxOnDie:
		InstantiateUtils.InstantiateInTree(vfxOnDie, self);
	queue_free();


func _on_can_shoot_screen_entered():
	inScreen = true;


func _on_can_shoot_screen_exited():
	inScreen = false;

func is_interval_beginning(count:int)->bool:
	return (count % shoot_delay_interval.size()) == 0;

func get_delay_or_shoot(count:int):
	return shoot_delay_interval[count % shoot_delay_interval.size()];
