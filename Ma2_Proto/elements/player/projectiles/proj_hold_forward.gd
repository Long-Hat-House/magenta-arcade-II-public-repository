extends Area3D

@export_group("Projectile")
@export var vanish_on_hit:bool = true;
@export var vanish_on_hit_area:bool = false;
@export var time_out:float = 0;
@export var hitVFX:PackedScene;
@export var reflected_projectile:PackedScene;
@export var reflected_bent_multiplier:float = 1;
@export var reflected_bent_is_directed_to_enemy:bool;
@export var reflected_bent_max_angle:float = 40;
@export var cant_damage_in_initial_seconds:float = 0.001;
@export_subgroup("Velocity")
@export var projectileVelocityRelative:Vector3 = Vector3.FORWARD * -100;
@export var projectileVelocityAbsolute:Vector3 = Vector3.FORWARD * -100;
@export var camera_multiplier:Vector3 = Vector3(1,0,1);
@export_subgroup("Tween")
enum TweenType
{
	None,
	Position,
	Velocity
}
@export var tween_on_start:TweenType = TweenType.None;
@export var projectileTweenDistance:Vector3 = Vector3.FORWARD * 5;
@export var projectileTweenDuration:float = 1;
@export var projectileTweenEase:Tween.EaseType;
@export var projectileTweenTrans:Tween.TransitionType;
@export var explode_on_tween_end:bool;

var velocity:Vector3;
var t_velocity:Vector3;
signal velocity_tween_change(value:float);
var time_existing:float;
var curr_tween:Tween;

@export_group("Damage")
@export var amountDamage:float = 0.1;
@export var damage_per_bonus:float = 0.05;
@export var bonus_resource:UpgradeInfo;
@export var damagePriority:int = 0;
@export var immunityTime:float = 0;
@export var recovers_mana:bool = true;
@export var scores:bool = true;
@export var debug_damage:bool;

var count_entered_tree:int;


func _enter_tree() -> void:
	visible = true;
	time_existing = 0.0;
	count_entered_tree = Time.get_ticks_msec();
	if tween_on_start != TweenType.None:
		if not is_node_ready():
			await ready;
		curr_tween = create_tween();
		var shot_basis:Basis = global_basis.orthonormalized();
		match tween_on_start:
			TweenType.Position:
				curr_tween.tween_property(self, "position",
						shot_basis.get_rotation_quaternion() * projectileTweenDistance,
						projectileTweenDuration
						).as_relative().set_trans(projectileTweenTrans).set_ease(projectileTweenEase);
			TweenType.Velocity:
				t_velocity = projectileTweenDistance;
				curr_tween.tween_method(func(v:float):
					t_velocity = Vector3.ZERO.lerp(projectileTweenDistance, v);
					velocity_tween_change.emit(v);

					, 1.0, 0.0, projectileTweenDuration
					).set_trans(projectileTweenTrans).set_ease(projectileTweenEase);

		if explode_on_tween_end:
			curr_tween.tween_callback(explode);
			curr_tween.tween_callback(vanish);

func _exit_tree() -> void:
	if curr_tween and curr_tween.is_running():
		curr_tween.kill();
	time_existing = 0.0;


func _physics_process(delta:float):
	if curr_tween and curr_tween.is_running() and tween_on_start == TweenType.Position:
		return;

	walk(delta);

	time_existing += delta;
	if (time_out != 0 and time_existing > time_out):
		explode();
		vanish();

func walk(delta:float):
	var shot_basis:Basis = global_basis.orthonormalized();
	velocity = shot_basis.x * (projectileVelocityRelative.x + t_velocity.x);
	velocity += shot_basis.y * (projectileVelocityRelative.y + t_velocity.y);
	velocity += shot_basis.z * (projectileVelocityRelative.z + t_velocity.z);
	velocity += projectileVelocityAbsolute;
	position += velocity * delta + LevelCameraController.instance.last_physics_step_movement * camera_multiplier;

func vanish():
	visible = false;
	ObjectPool.repool.call_deferred(self);

func get_best_direction_to(original:Vector3)->Vector3:
	var best:Vector3 = Vector3.ZERO;
	var best_angle:float = 999;
	for enemy:Node3D in get_tree().get_nodes_in_group(Game.instance.enemy_positional_node_group_name):
		var dir = enemy.global_position - self.global_position;
		var angle:float = absf(dir.signed_angle_to(-original, Vector3.UP));

		if angle < deg_to_rad(reflected_bent_max_angle) && dir.length_squared() > 1.0:
			if angle < best_angle:
				best = dir;
				best_angle = angle;


	if best != Vector3.ZERO:
		original = -best.normalized();

	return original;

func explode():
	if hitVFX:
		var inst := InstantiateUtils.InstantiateInSamePlace3D(hitVFX, self, Vector3.ZERO, true);
		InstantiateUtils.RandomizeRotation3DPlane(inst);
	if reflected_projectile:
		var refl_z:Vector3 = global_basis.z;
		refl_z.x = -refl_z.x * reflected_bent_multiplier;
		refl_z.y = 0;
		refl_z = refl_z.normalized();
		if reflected_bent_is_directed_to_enemy:
			refl_z = get_best_direction_to(refl_z);
		var inst := InstantiateUtils.InstantiateInTree(reflected_projectile, self);
		var original_scale = inst.scale;
		inst.global_basis = self.global_basis.looking_at(refl_z, Vector3.UP, true).scaled(original_scale);


func _on_visible_on_screen_notifier_3d_screen_exited():
	vanish();

func get_damage()->float:
	if bonus_resource:
		return amountDamage + bonus_resource.get_progress() * damage_per_bonus;
	else:
		return amountDamage;

func _try_damage(enemy_health:Health)->bool:
	var ddata := Health.DamageData.new(get_damage(), self, scores, recovers_mana);
	ddata.immunityPriority = damagePriority;
	ddata.immunityTime = immunityTime;
	var return_value:bool = enemy_health.damage(ddata);
	if debug_damage:
		print("[DAMAGE DEBUG] %s" % [enemy_health.debug_try_damage(ddata)]);
	return return_value;

func is_ethereal()->bool:
	return (float(Time.get_ticks_msec() - count_entered_tree) / 1000.0) < cant_damage_in_initial_seconds;

func _on_body_entered(body:Node):
	if is_ethereal(): return;
	var enemy_health:Health = Health.FindHealth(body);
	var damaged:bool = false;
	if enemy_health:
		damaged = _try_damage(enemy_health);
	if vanish_on_hit:
		if enemy_health:
			if damaged:
				explode();
				vanish();
		else:
			explode();
			vanish();
	if debug_damage:
		print("%s entered body %s to damage it!" % [self, body]);

func _on_area_entered(area: Area3D) -> void:
	if is_ethereal(): return;
	var enemy_health:Health = Health.FindHealth(area);
	var damaged:bool = false;
	if enemy_health:
		damaged = _try_damage(enemy_health);
	if vanish_on_hit_area:
		if enemy_health:
			if damaged:
				explode();
				vanish();
		else:
			explode();
			vanish();
	if debug_damage:
		print("%s entered area %s to damage it!" % [self, area]);
