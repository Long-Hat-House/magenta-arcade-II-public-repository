extends Node3D

@onready var area_3d: Area3D = $WaveMovement/Area3D

@export_group("Projectile")
@export var vanish_on_hit:bool = true;
@export var vanish_on_area_hit:bool = true;
@export var time_out:float = 0;
@export var time_out_range:float = 0;
var actual_time_out:float;
@export var hitVFX:PackedScene;
@export var time_outVFX:PackedScene;

@export_group("Velocity and follow")
@export var linear_velocity_min:float = 5;
@export var linear_velocity_max:float = 5;
@export var camera_multiplier:Vector3 = Vector3(0,0,1);
@export var linear_velocity_multiplier:float = 1.0;
@export var full_turning_speed:float = 600;
@export var turning_speed_multiplier:float = 1.0;
@export var who:Game.Target_Style;
@export var type:Target_Type;
@export var time_until_full_follow:float;
@export var turning_speed_duration_multiplier:float = 1.0;
@export var ease_full_follow:Tween.EaseType;
@export var trans_full_follow:Tween.TransitionType;
var full_follow:float = 1;
var full_tween:Tween;

enum Target_Type{
	Player,
	Enemy
}

var time_existing:float;
var curr_tween:Tween;

@export_group("Damage")
@export var amountDamage:float = 0.1;
@export var damage_per_bonus:float;
@export var bonus_resource:UpgradeInfo;
@export var damagePriority:int = 0;
@export var immunityTime:float = 0;
@export var recovers_mana:bool = true;
@export var scores:bool = true;

var ground_plane:Plane = Plane(Vector3.UP);

func get_full_follow_duration()->float:
	return time_until_full_follow * turning_speed_duration_multiplier;

func _enter_tree() -> void:
	time_existing = 0;
	actual_time_out = time_out + randf_range(-0.5, 0.5) * time_out_range;
	var dur:float = get_full_follow_duration();
	if dur > 0:
		if full_tween and full_tween.is_running():
			full_tween.kill();
		full_follow = 0;
		full_tween = create_tween();
		full_tween.tween_property(self, "full_follow", 1.0, dur)\
				.set_ease(ease_full_follow)\
				.set_trans(trans_full_follow)

func get_target()->Vector3:
	match type:
		Target_Type.Player:
			return Game.get_target_from_vector(get_origin(),
					Player.instance.currentTouches.map(
							func(touch:Player.TouchData): return touch.instance
					),
					who);
		Target_Type.Enemy:
			if Game.instance:
				return Game.instance.get_best_direction_to(get_origin(), Game.instance.enemy_positional_node_group_name, who);
	return Vector3.ZERO;

func get_origin()->Node3D:
	return area_3d;

func _physics_process(delta:float):
	if curr_tween and curr_tween.is_running():
		return;

	walk(delta);

	time_existing += delta;
	if time_out != 0 and time_existing > actual_time_out:
		explode(time_outVFX);
		vanish();

func walk(delta:float):
	var speed:Vector3 = -self.basis.z.normalized() * get_linear_velocity();

	var target:Vector3 = get_target();
	if target.length_squared() > 0.001:
		var direction:Vector3 = target - get_origin().global_position;

		speed += ground_plane.project(direction.normalized() * get_turning_speed() * delta);
		speed = speed.normalized() * get_linear_velocity();

	var frame_displacement:Vector3 = speed * delta + LevelCameraController.instance.last_physics_step_movement * camera_multiplier;
	transform = Transform3D(Basis.looking_at(speed), position + frame_displacement)

func vanish():
	ObjectPool.repool.call_deferred(self);

func explode(vfx:PackedScene):
	if vfx:
		var inst := InstantiateUtils.InstantiateInSamePlace3D(vfx, self, Vector3.ZERO, true);
		InstantiateUtils.RandomizeRotation3DPlane(inst);

func get_turning_speed()->float:
	return full_turning_speed * turning_speed_multiplier * full_follow;

func get_linear_velocity()->float:
	return lerpf(linear_velocity_min, linear_velocity_max, full_follow) * linear_velocity_multiplier;

func _on_visible_on_screen_notifier_3d_screen_exited():
	vanish();

func _try_hit(node:Node, vanish_if_hit:bool):
	#node = node.get_parent();
	var ddata := Health.DamageData.new(get_damage(), self, scores, recovers_mana);
	ddata.immunityPriority = damagePriority;
	ddata.immunityTime = immunityTime;
	Health.Damage(node, ddata, true, false);
	if vanish_if_hit:
		explode(hitVFX);
		vanish();

func get_damage()->float:
	if bonus_resource:
		return amountDamage + bonus_resource.get_progress() * damage_per_bonus;
	else:
		return amountDamage;

func _on_area_3d_body_entered(body: Node3D) -> void:
	_try_hit(body, vanish_on_hit);

func _on_area_3d_area_entered(area: Area3D) -> void:
	_try_hit(area, vanish_on_area_hit);
