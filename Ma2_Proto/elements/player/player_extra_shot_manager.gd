class_name Player_ExtraShotManager extends Node

@onready var player: Player = $".."

var power_count:float;
var current_power:int:
	get:
		return shots.size();


@export var level_up_time_absolute:float = 1.5;
@export var level_up_time_per_level:float = 0;
@export var level_down_time_absolute:float = 0.25;
@export var level_down_time_per_level:float = 0.0;
@export var projectile:PackedScene;

@export var time_between_shots_base:float = 0.35;
@export var extra_time_between_shots_per_ball:float = 0.05;
@export var time_between_shots_multiplier_per_ball:float = 0.85;
var shoot_count:float;

@export var angle_velocity_base:float = 105;
@export var angle_velocity_multiplier_per_ball:float = 0.75;

var shots:Array[Projectile_Player_Extra] = []

func _ready() -> void:
	player.just_holded_any.connect(_just_holded);
	player.just_released_after.connect(_just_released);

func is_powering()->bool:
	return player.equippedHold != null and player.currentTouches.any(func(element:Player.TouchData):
		return !element.instance.has_presseable()
		);

func start_powering():
	pass;

func end_powering():
	pass;
	power_count = 0;

func level_up_time()->float:
	return level_up_time_absolute + current_power * level_up_time_per_level;

func level_down_time()->float:
	return level_down_time_absolute + current_power * level_down_time_per_level;

func get_time_between_shots()->float:
	var shots_size:int = shots.size();
	return (time_between_shots_base + extra_time_between_shots_per_ball * shots_size) * pow(time_between_shots_multiplier_per_ball, shots_size);

func get_amount_of_valid_shots()->int:
	return shots.reduce(func(count:int, next:Projectile_Player_Extra): return count + 1 if next != null and is_instance_valid(next) else count, 0)

func get_angle_speed()->float:
	return angle_velocity_base * pow(angle_velocity_multiplier_per_ball, shots.size() - 1);

func set_circular_speed():
	var speed:float = get_angle_speed();
	for touch in Player.instance.currentTouches:
		touch.instance.set_extra_shot_speed(speed);

func _physics_process(delta: float) -> void:
	if is_powering():
		var power:int = current_power;
		## Power up
		if power < player.currentState.extra_shot_level:
			power_count += delta / level_up_time();
			while power_count > 1.0:
				var shot := create_shot();
				if shot:
					shots.append(shot);
					set_circular_speed();
				power_count -= 1.0;

		## Shooting
		if power > 0:
			shoot_count += delta;
			var shot_delay:float = get_time_between_shots();
			while shoot_count > get_time_between_shots():
				shoot_count -= shot_delay;
				shoot(maxf(fmod(-shoot_count, shot_delay), 0.0));

	## Power down
	elif !shots.is_empty():
		power_count -= delta / level_down_time();
		while power_count < 0.0:
			eliminate_shot(shots);
			power_count += 1.0;

func create_shot()->Projectile_Player_Extra:
	var target:Node3D = get_next_target();
	if target != null:
		var inst_shot:Projectile_Player_Extra = InstantiateUtils.InstantiateInTree(projectile, target.get_parent_node_3d());
		inst_shot.set_target(target);
		inst_shot.tree_exiting.connect(func():
			shots.erase(inst_shot); ## Important that the only way it takes it off from the array is through here.
			set_circular_speed();
			, CONNECT_ONE_SHOT);
		return inst_shot;
	else:
		return null;

func eliminate_shot(arr:Array[Projectile_Player_Extra]):
	for elem:Projectile_Player_Extra in arr:
		if elem.is_on():
			elem.set_on(false);
			return;

func get_next_target()->Node3D:
	var least:PlayerToken;
	var least_value:int = 9999;
	for touch:Player.TouchData in player.currentTouches:
		var amount:int = touch.instance.current_extra_projectile_target_amount();
		if amount < least_value:
			least_value = amount;
			least = touch.instance;

	#print("[EXTRA SHOT] made new target! Now best has %s for %s shots" % [least.current_extra_projectile_target_amount() + 1, shots.size()]);
	if least != null:
		var what_index:int = least.extra_projectile_positions.get_children().find_custom(func find_free(elem:Node):
			return not shots.any(func(shot:Projectile_Player_Extra):
				return shot.followee == elem;
				)
			);
		if what_index >= 0:
			return least.extra_projectile_positions.get_child(what_index);
		else:
			return least.add_extra_projectile_target();
	else:
		return null;

func rebalance_targets():
	#print("[EXTRA SHOT] calling rebalance targets! [%s] [%s]" % [shots, Engine.get_physics_frames()]);
	var touches:int = player.currentTouches.size();
	var amount_shots:int = shots.size();
	for projectile in shots:
		if is_instance_valid(projectile) and projectile.is_on():
			if projectile.followee != null and is_instance_valid(projectile.followee) and not projectile.followee.is_queued_for_deletion():
				var amount_shots_in_this_finger:int = projectile.followee.get_parent().get_child_count();
				if amount_shots_in_this_finger > ((amount_shots / touches) + signi(amount_shots % touches)):
					projectile.followee.queue_free();
					projectile.set_target(get_next_target());
			else:
				var target := get_next_target();
				projectile.set_target(target);
			#print("[EXTRA SHOT] setting %s's target as %s" % [projectile, projectile.followee]);
	#print("[EXTRA SHOT] Finished! Now has %s shots rebalanced!" % [shots.size()]);

var _last_shot:int = -1;
func shoot(extra_delta:float):
	var now_shot:int = (_last_shot + 1) % shots.size();
	if is_instance_valid(shots[now_shot]):
		shots[now_shot].shoot(extra_delta);
		_last_shot = now_shot;
	else:
		shots.remove_at(now_shot);

var was_powering:bool;
func _just_holded():
	var size:int = player.currentTouches.size();

	var powering:bool = is_powering();
	if powering and not was_powering:
		start_powering();
	rebalance_targets();
	was_powering = powering;

func _just_released():
	var size:int = player.currentTouches.size();
	var powering:bool = is_powering();
	if was_powering and not powering:
		end_powering();
	else:
		rebalance_targets();
	was_powering = powering;
