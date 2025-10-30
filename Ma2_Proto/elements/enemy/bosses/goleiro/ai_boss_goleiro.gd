class_name Boss_Goleiro extends Node3D

const CAMERA_SHAKE_SMALL = preload("res://systems/screen/camera_shake_small.tres")
const PROJ_ENEMY_BASIC = preload("res://elements/enemy/projectiles/proj_basic/proj_enemy_basic.tscn")
const PROJ_ENEMY_SUPER = preload("res://elements/enemy/projectiles/proj_super/proj_enemy_super.tscn")

@onready var body: CharacterBody3D = $GoleiroBody
@onready var boss_aim: Node3D = $"GoleiroBody/Node3DShaker/BossGraphic/Boss Hand Aim"
@onready var health: Health = %BossHealth
@onready var hit_head_position: Marker3D = %BossHeadPosition
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var shaker: Node3DShaker = $GoleiroBody/Node3DShaker

@onready var idle_r: Node3D = $"GoleiroBody/Node3DShaker/BossGraphic/Boss Hand Aim/IdleR"
@onready var idle_l: Node3D = $"GoleiroBody/Node3DShaker/BossGraphic/Boss Hand Aim/IdleL"
@onready var pose_r: Node3D = $"GoleiroBody/Node3DShaker/BossGraphic/Stuck Pose/PoseR"
@onready var pose_l: Node3D = $"GoleiroBody/Node3DShaker/BossGraphic/Stuck Pose/PoseL"
@onready var stuck_pos_parent: Node3D = $"GoleiroBody/Node3DShaker/BossGraphic/Stuck Pose"

@onready var bunda: Node3D = %boss03_popo
@onready var rotator: Node3D = $GoleiroBody/Node3DShaker/BossGraphic/boss03_popo/popo
@onready var hand_l: Node3D = $"GoleiroBody/Node3DShaker/BossGraphic/Boss Hand Aim/bossGoleiro_hand_L"
@onready var hand_r: Node3D = $"GoleiroBody/Node3DShaker/BossGraphic/Boss Hand Aim/bossGoleiro_hand_R"
@onready var left_hand_destination: Marker3D = $GoleiroBody/LeftShotOrigin
@onready var right_hand_destination: Marker3D = $GoleiroBody/RightShotOrigin

@onready var shoot_spawn: Node3D = $GoleiroBody/ShootSpawn
@onready var center: Marker3D = $GoleiroBody/ShootSpawn/Center
@onready var r_1: Marker3D = $GoleiroBody/ShootSpawn/R1
@onready var l_1: Marker3D = $GoleiroBody/ShootSpawn/L1
@onready var r_2: Marker3D = $GoleiroBody/ShootSpawn/R2
@onready var l_2: Marker3D = $GoleiroBody/ShootSpawn/L2

@onready var accessibility_high_contrast_object: AccessibilityHighContrastObject = $GoleiroBody/Node3DShaker/BossGraphic/AccessibilityHighContrastObject

@onready var death_sfx: AkEvent3D = $GoleiroBody/Node3DShaker/BossGraphic/SFX/DeathSFX
@onready var goal_player_sfx: AkEvent3D = $GoleiroBody/Node3DShaker/BossGraphic/SFX/GoalPlayerSFX
@onready var goal_against_sfx: AkEvent3D = $GoleiroBody/Node3DShaker/BossGraphic/SFX/GoalAgainstSFX

@onready var score: Boss_Goleiro_Placar = %PlacarScore

@onready var spawn_area: VisibleOnScreenNotifier3D = $GoleiroBody/SpawnArea

@onready var ju_magenta: AnimatedSprite3D = %JuMagenta
var curr_animation:StringName = &"";

var _target:Node3D;

@export var velocity_depreciation:float = 1;
@export var velocity_depreciation_targetless:float = 5;
@export var velocity_add:float = 3;
@export var limit_distance:float = 4;

@export var ball_attack_velocity:float = 20;
@export var ball_attack_cooldown:float = 4;
@export var damage_per_head_hit:float = 60;

var readied:bool;

var curr_distance:float;
var curr_velocity:float;
var origin:Vector3;
var origin_global:Vector3;

signal change_locked(locked:bool);

var locked:bool;
var dead:bool;
@export var velocity_to_lock:float = 2;
@export var lock_time:float = 1.25;
@export var extra_lock_time_per_extra_velocity:float = 0.25;

func func_mesh(node:Node, callable_mesh:Callable):
	if node == null:
		return;
	if node is MeshInstance3D:
		callable_mesh.call(node as MeshInstance3D);
	for child in node.get_children():
		func_mesh(child, callable_mesh);
@export var vulnerable_color:Color;
@export var vulnerable_damage_reduction:float = 0;
@export var normal_color:Color;
@export var normal_damage_reduction:float = 0.05;
@export var velocity_ball_multiplier:float = 1;

enum State
{
	Normal,
	Vulnerable
}

var state:State = State.Normal:
	get:
		return state;
	set(value):
		state = value;
		match state:
			State.Normal:
				health.damage_reduction = normal_damage_reduction;
				_stop_ju_vulnerable();
				#func_mesh(mesh, func(m:MeshInstance3D):
					#m.get_active_material(0).set("albedo_color", normal_color);
					#)
				return;
			State.Vulnerable:
				health.damage_reduction = vulnerable_damage_reduction;
				_make_ju_vulnerable();
				#func_mesh(mesh, func(m:MeshInstance3D):
					#m.get_active_material(0).set("albedo_color", vulnerable_color);
					#)
				return;

var shake:bool = false:
	get:
		return shake;
	set(value):
		shake = value;
		shaker.shake_amplitude_ratio = 1 if shake else 0;


@export var hand_shoot_origin_l: Marker3D;
@export var hand_shoot_origin_r: Marker3D;
var hand_r_tween:Tween;
var hand_l_tween:Tween;

var speaker:TextFlowBubbleSpeaker;
@export_group("Speech")
@export var flow:TextFlowPlayerBubbles;
@export var speaker_id:String = "Ju";

@export var speech_intro:StringName = 			&"dial_lvl2_boss_intro";
@export var speech_intro_before:StringName = 	&"dial_lvl2_boss_before_intro";
@export var speech_idle:StringName = 			&"dial_lvl2_boss_idle";
@export var speech_goal_player:StringName = 	&"dial_lvl2_boss_goal_player";
@export var speech_goal_enemy:StringName = 		&"dial_lvl2_boss_goal_ju";
@export var speech_end:StringName = 			&"dial_lvl2_boss_end";
@onready var bubble_pos: Marker3D = $"GoleiroBody/Node3DShaker/BossGraphic/JuMagenta/Bubble Pos"

func _ready() -> void:
	speaker = TextFlowBubbleSpeaker.new();
	speaker.followee = bubble_pos;
	speaker.bubble_started.connect(_speech_start);
	speaker.bubble_finished.connect(_speech_end);
	speaker.voice = TextFlowBubbleSpeaker.SpeakerVoice.Ju
	flow.set_speaker(speaker, speaker_id);

	accessibility_high_contrast_object.change_group("scenery");

	await get_tree().create_timer(0.1).timeout;
	origin = position;
	origin_global = global_position;
	shake = false;
	readied = true;


func show_high_contrast():
	accessibility_high_contrast_object.change_group(&"enemy");

## Set the target for the boss to follow
func set_target(target:Node3D):
	_target = target;
	boss_aim.set_target(target);

func get_current_velocity()->Vector3:
	if locked:
		return Vector3.ZERO;
	else:
		return Vector3.RIGHT * curr_velocity;

func _process(delta: float) -> void:
	var velocity:float = curr_velocity;
	if locked: velocity = 0;
	rotator.basis = rotator.basis.rotated(Vector3.FORWARD, velocity * velocity_ball_multiplier * delta);

func _physics_process(delta: float) -> void:
	if not readied:
		return;
	if not locked:
		var target_distance:float = get_target_distance(_target);
		target_distance = clampf(target_distance, -limit_distance, limit_distance);

		var deprec:float = velocity_depreciation_targetless if _target == null else velocity_depreciation;
		curr_velocity = move_toward(curr_velocity, 0, deprec * delta);
		curr_velocity += (target_distance - curr_distance) * velocity_add * delta;
		curr_distance += curr_velocity * delta;
		if curr_distance < -limit_distance or curr_distance > limit_distance:
			var vel:float = abs(curr_velocity);
			if vel >= velocity_to_lock:
				lock(extra_lock_time_per_extra_velocity * (vel - velocity_to_lock));
				#start_stuck_pose(curr_velocity < 0);
			curr_velocity = -curr_velocity * 0.5;

		position = Vector3(curr_distance, 0, 0) + origin;
	else:
		curr_velocity = -curr_distance;

	_check_sprite_state(delta);

	attack_cooldown -= delta;

	if Input.is_key_label_pressed(KEY_K):
		health.damage(Health.DamageData.new(20));

func _check_sprite_state(delta:float):
	if curr_animation.is_empty():
		#if !was_empty:
			#print("[Ju Magenta] Now playing normal stuff %s" % [Engine.get_frames_drawn()]);
		if absf(curr_velocity) > 0.25:
			_sprite_play(&"move");
			ju_magenta.flip_h = curr_velocity > 0;
			ju_magenta.speed_scale = remap(clampf(absf(curr_velocity), 0.0, 3.0), 0.0, 3.0, 0.75, 1.5);
		else:
			_sprite_play(&"idle");
			ju_magenta.speed_scale = 1;

func _sprite_play(animation:StringName):
	if ju_magenta.animation != animation:
		#print("[JU MAGENTA] PLAY %s!! [%s]" % [anim, Engine.get_frames_drawn()]);
		ju_magenta.play(animation);

func _change_current_animation(anim:StringName, loops:bool, custom_speed:float = 1.0, wait_after:float = 0):
	curr_animation = anim;
	_sprite_play(anim);
	if not loops:
		await ju_magenta.animation_looped;
		if not is_instance_valid(ju_magenta): return;

		if curr_animation != anim:
			return;

		if wait_after > 0:
			await get_tree().create_timer(wait_after).timeout;
			if not is_instance_valid(ju_magenta): return;

		_stop_specific_sprite_animation(anim);

func _stop_sprite_animation():
	#print("[JU MAGENTA] Stop curr animation it was %s! [%s]" % [curr_animation, Engine.get_frames_drawn()]);
	#push_error("[JU MAGENTA] Stop curr animation it was %s! [%s]" % [curr_animation, Engine.get_frames_drawn()])
	curr_animation = &"";
	## this will make the next _physics_process() override the animation

func _stop_specific_sprite_animation(anim:StringName):
	if curr_animation == anim:
		_stop_sprite_animation();

var _anim_sprite_stack:Array[StringName];
func _add_sprite_stack(anim:StringName, loops:bool):
	_anim_sprite_stack.push_back(anim);
	await _check_sprite_stack(loops);
	if not loops and is_instance_valid(ju_magenta):
		_remove_sprite_stack(anim);

func _remove_sprite_stack(anim:StringName):
	_anim_sprite_stack.erase(anim);
	_check_sprite_stack(true);

func _check_sprite_stack(loops:bool):
	if _anim_sprite_stack.size() > 0:
		await _change_current_animation(_anim_sprite_stack.back(), loops);
	else:
		_stop_sprite_animation();


func _make_ju_vulnerable():
	score.do_surprise();
	_add_sprite_stack(&"vulnerable_begin", false);
	await ju_magenta.animation_looped;
	_add_sprite_stack(&"vulnerable_loop", true);

func _stop_ju_vulnerable():
	_remove_sprite_stack(&"vulnerable_loop");
	_remove_sprite_stack(&"vulnerable_begin");
	_change_current_animation(&"stand_up", false);
	await get_tree().process_frame;


func _make_ju_stuck():
	score.do_surprise();
	await _change_current_animation(&"pre_stuck", false);
	_add_sprite_stack(&"stuck", true);

func _stop_ju_stuck():
	_remove_sprite_stack(&"stuck");

func get_target_distance(target:Node3D)->float:
	if target == null:
		return 0;
	else:
		return clampf((target.global_position - origin_global).x, -limit_distance, limit_distance);

func lock(extra_time:float):
	locked = true;
	shake = true;

	_make_ju_stuck();
	change_locked.emit(true);
	await get_tree().create_timer(lock_time + extra_time).timeout;
	if is_instance_valid(self) and not dead:
		_stop_ju_stuck();
		_change_current_animation(&"stand_up", false);
		locked = false;
		shake = false;
		change_locked.emit(false);



func hit_in_the_head():
	set_vulnerable();
	score.hurt();
	health.damage(Health.DamageData.new(damage_per_head_hit, self, true, false))
	CAMERA_SHAKE_SMALL.screen_shake()
	anim.play(&"hit_head");
	await anim.animation_finished;
	anim.play(&"RESET");


func set_vulnerable(vulnerable:bool = true):
	if vulnerable:
		state = State.Vulnerable;
	else:
		state = State.Normal;

func shoot_arrow():
	var to_wait:int = 1;
	for shot_pos:Vector3 in [
		center.global_position,
		r_1.global_position,
		l_1.global_position,
		r_2.global_position,
		l_2.global_position
	]:
		InstantiateUtils.InstantiatePositionRotation(PROJ_ENEMY_BASIC, shot_pos, Vector3.BACK);
		to_wait -= 1;
		if to_wait <= 0:
			to_wait = 2;
			await get_tree().create_timer(0.05).timeout;
			if not is_instance_valid(shoot_spawn):
				return;

var shoot_commands:Array[Callable] = [
	shoot_arrow,
	shoot_arrow,
	shoot_arrow,
	func shoot_super():
		InstantiateUtils.InstantiateInTree(PROJ_ENEMY_SUPER, center);
		,
]
var randomized_shoot:bool = false;
var command_index:int = 0;
func shoot():
	var len:int = shoot_commands.size()
	#if not randomized_shoot and command_index > len:
		#seed(Player.instance.get_seed_based_on_equipped_items(2));
		#shoot_commands.shuffle();
		#randomized_shoot = true;
	shoot_commands[command_index % len].call();
	command_index += 1;


func _on_boss_goleiro_ball_goal_allied() -> void:
	score.add_score(0,1);
	goal_player_sfx.post_event();
	_change_current_animation(&"pre_vulnerable", true);


func _on_boss_goleiro_ball_hit_boss() -> void:
	pass;


func _on_boss_goleiro_ball_goal_enemy() -> void:
	score.add_score(1,0);
	goal_against_sfx.post_event();
	_change_current_animation(&"cheer", false, 1.0, 3.0);


func _on_boss_goleiro_ball_started() -> void:
	#_stop_sprite_animation();
	pass;

func speak(id:StringName, loops:bool = false):
	flow.start_flow(id, loops);

func cmd_speak_wait(id:StringName)->Level.CMD:
	return Level.CMD_Sequence.new([
		Level.CMD_Callable.new(func():
			speak(id, false);
			),
		Level.CMD_Wait_Signal.new(speaker.bubble_finished),
	]);

func _speech_start() -> void:
	if curr_animation.is_empty():
		_add_sprite_stack(&"speech", true);

func _speech_end() -> void:
	_remove_sprite_stack(&"speech");


var captured_area_ball:Boss_Goleiro_Ball;
func _on_ball_sensor_body_entered(body: Node3D) -> void:
	if body is Boss_Goleiro_Ball and can_attack():
		captured_area_ball = body as Boss_Goleiro_Ball;
		start_attack();

func _on_ball_sensor_body_exited(body: Node3D) -> void:
	if body == captured_area_ball:
		captured_area_ball = null;

var attack_cooldown:float;
func can_attack()->bool:
	return attack_cooldown <= 0.0 and curr_animation.is_empty();

func start_attack():
	attack_cooldown = ball_attack_cooldown;
	await _change_current_animation(&"pre_attack", false);
	_change_current_animation(&"attack", false);
	attack_feedback();
	if captured_area_ball:
		#captured_area_ball.set_damaging(); ## Useless?
		captured_area_ball.set_ball_velocity((captured_area_ball.global_position - self.global_position).normalized() * ball_attack_velocity);

func bumped_ball():
	bump_feedback();

func bump_feedback():
	create_tween().tween_method(func(value:float):
		bunda.position = VectorUtils.rand_vector3_range(-value, value) * 0.2;
		,1.0, 0.0, 0.175).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE);

func attack_feedback():
	score.do_something();
	bunda.scale = Vector3.ONE * 1.25;
	create_tween().tween_property(bunda, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT);
	return;

func left_hand_attack():
	hand_l_tween = await generic_hand_attack(hand_l, hand_l_tween, left_hand_destination, hand_shoot_origin_l);

func right_hand_attack():
	hand_r_tween = await generic_hand_attack(hand_r, hand_r_tween, right_hand_destination, hand_shoot_origin_r);

func left_hand_machine_gun(amount:int, interval:float):
	hand_l_tween = await generic_hand_machine_gun(hand_l, hand_l_tween, left_hand_destination, hand_shoot_origin_l, amount, interval);

func right_hand_machine_gun(amount:int, interval:float):
	hand_r_tween = await generic_hand_machine_gun(hand_r, hand_r_tween, right_hand_destination, hand_shoot_origin_r, amount, interval);

func generic_hand_attack(hand:Node3D, hand_tween:Tween, target:Node3D, shot_origin:Node3D)->Tween:
	if locked: return;
	hand.process_mode = Node.PROCESS_MODE_DISABLED;
	if hand_tween and hand_tween.is_running():
		await hand_tween.finished;
	var orig:Transform3D = hand.transform;
	var original_transform = hand.global_transform;
	hand_tween = create_tween();
	hand_tween.tween_method(func(value:float):
		hand.global_transform = original_transform.interpolate_with(target.global_transform, value);
		,0.0, 1.0, 0.5).set_ease(Tween.EASE_OUT);
	hand_tween.tween_interval(0.5);
	hand_tween.tween_callback(func():
		var tiro = InstantiateUtils.InstantiateInTree(PROJ_ENEMY_SUPER, shot_origin, Vector3.ZERO, false);
		tiro.global_position.y = 0.25;
		tiro.global_basis = tiro.global_basis.looking_at(Plane.PLANE_XZ.project(-tiro.global_basis.z));
		);
	TweenUtils.tween_jump_vector3_dynamic(
		hand, hand_tween, "global_position",
		func(): return target.global_position,
		func(): return target.global_position,
		Vector3.FORWARD * 2, 0.5
		).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT);
	hand_tween.tween_interval(0.25);
	hand_tween.tween_property(hand, "transform", orig, 0.5).set_ease(Tween.EASE_OUT);
	hand_tween.tween_interval(0.25);
	hand_tween.tween_callback(func():
		print("process mode is back");
		hand.process_mode = Node.PROCESS_MODE_INHERIT;
		)
	return hand_tween;

func generic_hand_machine_gun(hand:Node3D, hand_tween:Tween, target:Node3D, shot_origin:Node3D, amount:int, interval:float)->Tween:
	if locked: return;
	hand.process_mode = Node.PROCESS_MODE_DISABLED;
	if hand_tween and hand_tween.is_running():
		await hand_tween.finished;
	var orig_local:Transform3D = hand.transform;
	var orig_global:Transform3D = hand.global_transform;
	hand_tween = create_tween();
	hand_tween.tween_method(func(value:float):
		hand.global_transform = orig_global.interpolate_with(target.global_transform, value);
		,0.0, 1.0, 0.5).set_ease(Tween.EASE_OUT);
	hand_tween.tween_interval(0.5);
	while amount > 0:
		hand_tween.tween_callback(func():
			var tiro = InstantiateUtils.InstantiateInTree(PROJ_ENEMY_BASIC, shot_origin, Vector3.ZERO, false);
			tiro.global_position.y = 0.25;
			var dir:Vector3 = Plane.PLANE_XZ.project(-tiro.global_basis.z);
			dir = dir.rotated(Vector3.UP, deg_to_rad(randf_range(-5, 5)));
			tiro.global_basis = tiro.global_basis.looking_at(dir);
			);
		TweenUtils.tween_jump_vector3_dynamic(
			hand, hand_tween, "global_position",
			func(): return target.global_position,
			func(): return target.global_position,
			Vector3.FORWARD * 0.2, interval * 0.85
			).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT);
		hand_tween.tween_interval(interval * 0.15);
		amount-=1;
	hand_tween.tween_property(hand, "transform", orig_local, 0.5).set_ease(Tween.EASE_OUT);
	hand_tween.tween_interval(0.25);
	hand_tween.tween_callback(func():
		print("process mode is back");
		hand.process_mode = Node.PROCESS_MODE_INHERIT;
		)
	return hand_tween;

var hurt_tween:Tween;
var death_awaiting_id = {

}
func await_for_death(tween:Tween, hand:Node3D, orig_local:Transform3D):
	if hurt_tween != null and hurt_tween.is_running():
		return;
	if death_awaiting_id.has(hand):
		death_awaiting_id[hand] += 1;
	else:
		death_awaiting_id[hand] = 0;
	var curr_id:int = death_awaiting_id[hand];
	hand.restore();
	await hand.died;
	if curr_id != death_awaiting_id[hand]:
		return;
	if hurt_tween != null and hurt_tween.is_running():
		return;
	if tween != null and tween.is_running():
		tween.kill();

		hurt_tween = create_tween();
		hurt_tween.tween_property(hand, "transform", orig_local, 0.25)\
				.set_ease(Tween.EASE_OUT)\
				.set_trans(Tween.TRANS_ELASTIC);

func _kill_tween_if_exists(t:Tween):
	if t and t.is_running():
		t.kill();


var stuck_pose_tween:Tween;
func start_stuck_pose(inverted:bool):
	## Was using
	stuck_pos_parent.scale.x = -1.0 if inverted else 1.0;
	_kill_tween_if_exists(stuck_pose_tween);
	_kill_tween_if_exists(hand_l_tween);
	_kill_tween_if_exists(hand_r_tween);
	stuck_pose_tween = create_tween();
	stuck_pose_tween.set_parallel();
	hand_l.process_mode = Node.PROCESS_MODE_DISABLED;
	hand_r.process_mode = Node.PROCESS_MODE_DISABLED;
	var duration:float = 0.15;
	if inverted:
		stuck_pose_tween.tween_property(hand_l, "transform", pose_l.transform, duration).set_ease(Tween.EASE_IN_OUT);
		stuck_pose_tween.tween_property(hand_r, "transform", pose_r.transform, duration).set_ease(Tween.EASE_IN_OUT);
	else:
		stuck_pose_tween.tween_property(hand_l, "transform", pose_l.transform, duration).set_ease(Tween.EASE_IN_OUT);
		stuck_pose_tween.tween_property(hand_r, "transform", pose_r.transform, duration).set_ease(Tween.EASE_IN_OUT);

	while locked:
		await get_tree().process_frame;
	end_stuck_pose();


func end_stuck_pose():
	_kill_tween_if_exists(stuck_pose_tween);
	stuck_pose_tween = create_tween();
	stuck_pose_tween.set_parallel();
	var duration:float = 0.25;
	var hand_to_destination = func hand_to_destination(value:float, hand:Node3D, origin:Transform3D, destination:Node3D):
		hand.transform = origin.interpolate_with(destination.transform, value);
	stuck_pose_tween.tween_method(hand_to_destination.bind(hand_l, hand_l.transform, idle_l), 0.0, 1.0, duration).set_ease(Tween.EASE_IN_OUT);
	stuck_pose_tween.tween_method(hand_to_destination.bind(hand_r, hand_r.transform, idle_r), 0.0, 1.0, duration).set_ease(Tween.EASE_IN_OUT);
	stuck_pose_tween.chain().tween_callback(func():
		hand_l.process_mode = Node.PROCESS_MODE_INHERIT;
		hand_r.process_mode = Node.PROCESS_MODE_INHERIT;
		)

func die():
	dead = true;
	locked = true;
	shake = true;
	death_sfx.post_event();
	speak(speech_end);
	_add_sprite_stack(&"stuck", true);
	_sprite_play(&"stuck");
	score.dead();
	await VFX_Utils.make_boss_explosion(body, spawn_area);
	var death_tween = create_tween();
	death_tween.tween_property(body, "position:y", 40, 3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC);
