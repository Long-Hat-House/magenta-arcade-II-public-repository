class_name Boss_Final extends Node3D

const BOSS_5_C = preload("res://systems/boss/boss_5_c.tres")
const COPTER = preload("res://elements/enemy/copter/enemy_roboto_copter.tscn");

@onready var boss_health: Health = %BossHealth
@onready var final_laser: FinalLaser = %FinalLaser
@onready var body: CharacterBody3D = %IvoBody
const Esteira = preload("res://elements/enemy/bosses/ivo/boss_final_ivo_esteira.gd");
@onready var esteira:Esteira = $Esteira
@onready var graphic: Boss_Ivo_Graphic = %caixao_ivo
@onready var smoke_particles: GPUParticles3D = $CameraFollow/eva_car/SmokeParticles
@onready var ending_sequence: EndingSequence = $Ending

@export var percentage_level_2:float = 0.65;
@export var percentage_level_3:float = 0.25;
@export var initial_eva_position:Node3D;

##Specific stuff
@export var opening_shake:CameraShakeData;
@export var eva_1_sine_movement:Array[SineMovement]
@export var end_camera_shake:CameraShakeData;
@export var end_duration:float = 4;
@export var end_duration_after_jump:float = 4.5;
@export var scene_rock_fall:PackedScene;
@export var explode_vfx:Array[GPUParticles3D];
@export var spawn_vfx_up:Array[GPUParticles3D];
@export var spawn_vfx_down:Array[GPUParticles3D];
@onready var eva_car: Node3D = %eva_car
@onready var eva_1: AnimatedSprite3D = %Eva1
@onready var eva_2: AnimatedSprite3D = %Eva2
@onready var eva_3: AnimatedSprite3D = %Eva3
@onready var ivo_target: Marker3D = $"CameraFollow/IvoBody/Ivo Target"
@export var crash_screen_shake:CameraShakeData;
@onready var stone_particles: GPUParticles3D = $"CameraFollow/Stone Particles"

@onready var sfx_death: AkEvent3D = $CameraFollow/IvoBody/Wobble/caixao_ivo/Sounds/SFX_Death
@onready var sfx_appear: AkEvent3DLoop = $CameraFollow/IvoBody/Wobble/caixao_ivo/Sounds/SFX_Appear
@onready var sfx_cry: AkEvent3DLoop = $CameraFollow/IvoBody/Wobble/caixao_ivo/Sounds/SFX_Cry
@onready var sfx_drag: AkEvent3DLoop = $CameraFollow/IvoBody/Wobble/caixao_ivo/Sounds/SFX_Drag
@onready var sfx_shoot: AkEvent3D = $CameraFollow/IvoBody/Wobble/caixao_ivo/Sounds/SFX_Shoot




const PIZZA = preload("res://elements/enemy/pizza/enemy_pizza_roboto_shooter.tscn")
const RUST = preload("res://elements/enemy/pizza/enemy_pizza_roboto_rusty_cannon.tscn")
const SUPER_PIZZA = preload("res://elements/enemy/pizza/enemy_pizza_shooter_super.tscn")
const LASER = preload("res://elements/enemy/laser/enemy_laser_roboto.tscn")
const JACARE = preload("res://elements/enemy/roboto_jacare/enemy_jacare.tscn")
const BRAWNY = preload("res://elements/enemy/brawny/enemy_brawny.tscn")
const TUCANO = preload("res://elements/enemy/roboto_tucano/enemy_tucano.tscn")

@export var spirit_scene:PackedScene;
@export var spirit_scene_shot:PackedScene;
@export var spirit_radius:float = 2.5;
@export var spirit_height:float = 1;

@export var camera_follow:Node3D;

@export var eva_phases:Array[Node3D];

@export var key_to_damage_cheat:Key;

@onready var deactivated_robot: Node = $DeactivatedRobot

@onready var dial_lvl_4_final_boss_chase_idle: QuickDialogue = %dial_lvl4_final_boss_chase_idle
@onready var dial_lvl_4_final_boss_crash: QuickDialogue = %dial_lvl4_final_boss_crash
@onready var dial_lvl_4_final_boss_crash_idle: QuickDialogue = %dial_lvl4_final_boss_crash_idle
@onready var dial_lvl_4_final_boss_end: QuickDialogue = %dial_lvl4_final_boss_end
@onready var dial_lvl_4_final_boss_end_prepare: QuickDialogue = %dial_lvl4_final_boss_end_prepare
@onready var dial_lvl_4_final_boss_end_jump: QuickDialogue = %dial_lvl4_final_boss_end_jump
@onready var dial_lvl_4_final_boss_intro: QuickDialogue = %dial_lvl4_final_boss_intro
@onready var dial_lvl_4_final_boss_idle: QuickDialogue = %dial_lvl4_final_boss_idle

class SceneryAnimation:
	var player:AnimationPlayer;
	var anim:StringName;
	
	func _init(p:AnimationPlayer, a:StringName) -> void:
		self.player = p;
		self.anim = a;

var initial_eva1_position:Vector3;

var scenery:Boss_Final_Ivo_Scenery;

var follow_camera:bool;

signal ended_animation;

func _ready() -> void:
	smoke_particles.emitting = false;
	set_phase(0);
	
	QuickDialogue.assign_animation_parent(dial_lvl_4_final_boss_intro, &"idle", &"speech");
	QuickDialogue.assign_animation_parent(dial_lvl_4_final_boss_idle, &"idle", &"speech");
	QuickDialogue.assign_animation_parent(dial_lvl_4_final_boss_chase_idle, &"idle", &"speech");
	QuickDialogue.assign_animation_parent(dial_lvl_4_final_boss_crash, &"idle", &"speech");
	QuickDialogue.assign_animation_parent(dial_lvl_4_final_boss_crash_idle, &"idle", &"speech");
	#QuickDialogue.assign_animation_parent(dial_lvl_4_final_boss_end, &"idle", &"speech");
	
	initial_eva1_position = eva_1.position;
	eva_1.global_position = initial_eva_position.global_position;

func play_animation(where:AnimatedSprite3D, anim:StringName, idle:StringName):
	where.play(anim);
	await where.animation_looped;
	if where.animation == anim:
		where.play(idle);

func _process(delta: float) -> void:
	if follow_camera:
		camera_follow.position += LevelCameraController.instance.last_frame_movement;

	if Input.is_key_pressed(key_to_damage_cheat):
		boss_health.damage(Health.DamageData.new(boss_health.max_amount * 0.01));
		
	if is_instance_valid(eva_1):
		eva_1.flip_h = eva_1.global_position.x > 0;
	if is_instance_valid(eva_2):
		eva_2.flip_h = eva_2.global_position.x > 0;

func cmd_boss(lvl:Level, scenery_from_lvl:Boss_Final_Ivo_Scenery)->Level.CMD:
	self.scenery = scenery_from_lvl;
	return Level.CMD_Sequence.new([
		Level.CMD_Callable.new(func():
			LevelEnvironment.set_state("final_boss");
			sfx_appear.start_loop();
			),
		intro(lvl),
		Level.CMD_Parallel.new([
			cmd_wait_for_percentage(percentage_level_2),
			static_mode(lvl),
		]),
		chase_transition(lvl),
		Level.CMD_Parallel.new([
			cmd_wait_for_percentage(percentage_level_3),
			chase_mode(lvl),
		]),
		desperate_transition(lvl),
		Level.CMD_Parallel.new([
			cmd_wait_for_percentage(0),
			desperate_mode(lvl),
		]),
		end_transition(lvl),
	]);

func cmd_wait_for_percentage(percentage:float)->Level.CMD:
	return Level.CMD_Wait_Callable.new(func():
		return boss_health.get_health_percentage() <= percentage;
		)

func intro(lvl:Level)->Level.CMD:
	return Level.CMD_Sequence.new([
		dial_lvl_4_final_boss_intro.cmd_dialogue(true),
		Level.CMD_Callable.new(func():
			var t:= create_tween();
			t.tween_property(scenery, "before_animation_speed_scale", 4, 0.75).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE);
			),
		Level.CMD_Callable.new(func():
			sfx_appear.stop_loop();
			LevelEnvironment.set_tree_parameter("boss_phase", Level4_AnimationTree.LastBossPhase.LAB);
			),
		Level.CMD_Parallel_Complete.new([
			Level.CMD_Sequence.new([
				Level.CMD_Wait_Seconds.new(1),
				Level.CMD_Callable.new(func():
					for part in explode_vfx: part.emitting = true;
					HUD.instance.make_screen_effect(HUD.ScreenEffect.LongFlash);
					CameraShaker.screen_shake(opening_shake);
					scenery.do_after();
					),
			]),
			Level.CMD_Await_AsyncCallable.new(func():
				var t := create_tween();
				t.tween_property(eva_1, "position", initial_eva1_position, 1.2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD);
				await t.finished;
				for sine in eva_1_sine_movement: 
					sine.stopped = false;
				, self),
			
		]),
		Level.CMD_Callable.new(func():
			reparent(InstantiateUtils.get_topmost_instantiate_node());
			follow_camera = true;
			HUD.instance.show_boss_life(
				BOSS_5_C,
				boss_health.get_health_percentage,
				AK.EVENTS.MUSIC_BOSS_FINAL_PHASE1_START
				)
			),
	])


func static_mode(lvl:Level)->Level.CMD:
	return Level.CMD_Sequence.new([
		Level.CMD_Callable.new(set_phase.bind(0)),
		Level.CMD_Parallel_Complete.new([
			Level.CMD_Sequence.new([
				cmd_laser(1.5, 1.0, 2.0, 0.0, false),
			]),
			Level.CMD_Sequence.new([
				Level.CMD_Callable.new(make_stone_enemy),
				Level.CMD_Wait_Seconds.new(2),
				Level.CMD_Callable.new(make_stone_enemy),
			]),
			Level.CMD_Sequence.new([
				dial_lvl_4_final_boss_idle.cmd_dialogue(false),
			])
		]),
		Level.CMD_Wait_Seconds.new(2),
		Level.CMD_Parallel.new([
			Level.CMD_Sequence.new([ 
				cmd_laser(1.5, 2.25, 2.0, 8.25, true),
			], -1),
			Level.CMD_Sequence.new([
				Level.CMD_Callable.new(make_spirit),
				Level.CMD_Wait_Seconds_Dynamic.new(func():
					return lerpf(1, 4, boss_health.get_health_percentage() * randf_range(0.9, 1.1))
					),
			], -1),
			Level.CMD_Sequence.new([
				Level.CMD_Callable.new(make_stone_enemy),
				Level.CMD_Wait_Seconds_Dynamic.new(func():
					var random_time:float = lerpf(4, 7, boss_health.get_health_percentage() * randf_range(0.9, 1.1))
					return random_time;
					),
			], -1)
		])
	])


func chase_transition(lvl:Level)->Level.CMD:
	return Level.CMD_Sequence.new([
		dial_lvl_4_final_boss_idle.cmd_stop_dialogue(),
		Level.CMD_Await_AsyncCallable.new(func():
			Wwise.post_event_id(AK.EVENTS.MUSIC_BOSS_FINAL_PHASE2_START, AudioManager as Node);
			
			for sine in eva_1_sine_movement: 
				sine.stopped = true;
			var t1:= create_tween();
			TransformUtils.tween_jump_global(eva_1, t1, eva_2.global_position,Vector3.UP * 2, 0.75).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD);
			
			var t2 := create_tween();
			var old_distance:Vector3 = ivo_target.global_position - body.global_position;
			t2.tween_callback(func():
				sfx_drag.start_loop();
				)
			t2.tween_property(body, "position", ivo_target.position, 1.5).as_relative().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD);
			t2.tween_callback(func():
				body.reparent(eva_car);
				body.basis = Basis.IDENTITY;
				var t3 = create_tween();
				t3.tween_property(eva_car, "position", -old_distance + Vector3.BACK * 2, 5.0).as_relative().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD);
				
				)
			
			await t1.finished;
			set_phase(1);
			TransformUtils.tremble_up_rotation_coin(eva_car, eva_car.create_tween(), 1, 4.5, Vector3.RIGHT * 0.5, 1.25, 1);
			,eva_1),
		lvl.cam.cmd_speed(-12.50, 5.0, LevelCameraController.MovementAxis.Z, Tween.TRANS_SINE, Tween.EASE_IN),
		Level.CMD_Callable.new(final_laser.set_mode.bind(FinalLaser.Mode.NONE)),
		Level.CMD_Wait_Seconds.new(2.9),
	])

func chase_mode(lvl:Level)->Level.CMD:
	var objs := {};
	objs.count = 0;
	objs.force = 0;
	return Level.CMD_Sequence.new([
		
		##First intro sequence that can be skippable
		Level.CMD_Wait_Seconds.new(0.1),
		dial_lvl_4_final_boss_chase_idle.cmd_dialogue(false),
		Level.CMD_Parallel.new([
			Level.CMD_Sequence.new([
				Level.CMD_Callable.new(final_laser.set_mode.bind(FinalLaser.Mode.PRE)),
				Level.CMD_Wait_Seconds.new(1),
				Level.CMD_Callable.new(final_laser.set_mode.bind(FinalLaser.Mode.ON)),
				Level.CMD_Wait_Seconds.new(0.5),
				cmd_laser_squiggly_treat(0.45, 1.75, 0.30),
				Level.CMD_Wait_Seconds.new(1),
				cmd_laser_squiggly(true, 1),
				Level.CMD_Wait_Seconds.new(1.5),
				Level.CMD_Callable.new(final_laser.set_mode.bind(FinalLaser.Mode.NONE)),
				Level.CMD_Wait_Seconds.new(2.0),
			]),
			Level.CMD_Process.new(func(delta:float):
				direct_laser_to(delta, Vector3.BACK, 360);
				return false;
				),
		]),
		
		## The mode itself
		Level.CMD_Parallel.new([
			Level.CMD_Sequence.new([
				Level.CMD_Callable.new(play_animation.bind(eva_2, &"attack", &"idle")),
				cmd_laser(2.75, 3.5, 1.0, -2.5, false),
				Level.CMD_Wait_Seconds_Dynamic.new(func(): return randf_range(0.4, 0.8)),
			],-1),
			Level.CMD_Sequence.new([
				Level.CMD_Callable.new(make_spirit),
				Level.CMD_Wait_Seconds_Dynamic.new(func(): return randf_range(1.6, 3.0)),
			], -1),
			Level.CMD_Sequence.new([
				Level.CMD_Wait_Callable.new(func():
					return boss_health.get_health_percentage() < lerpf(percentage_level_3, percentage_level_2, 0.45); 
					),
				Level.CMD_Callable.new(make_pillar_fall.bind(1.25)),
				Level.CMD_Wait_Seconds_Dynamic.new(func(): return randf_range(6.0, 8.0)),
			], -1),
			
			## Zig zag
			Level.CMD_Sequence.new([
				Level.CMD_Wait_Callable.new(func():
					return boss_health.get_health_percentage() < lerpf(percentage_level_3, percentage_level_2, 0.75); 
					),
				Level.CMD_Process.new(func(delta:float):
					const amount_move:float = 2.25;
					var future_dif = (sin(objs.count + PI * 0.25) - sin(objs.count)) * amount_move;
					var multiplier:float = smoothstep(0, 2.0, objs.force);
					eva_car.position.x = sin(objs.count) * amount_move * multiplier;
					eva_car.basis = Basis.looking_at(Vector3(future_dif * multiplier, 0, -10));
					objs.force += delta;
					objs.count += delta;
					return false;
					),
			])
		])
	])

func desperate_transition(lvl:Level)->Level.CMD:
	return Level.CMD_Sequence.new([
		Level.CMD_Print_Log.new("O BOSS VAI PARAR"),
		Level.CMD_Callable.new(final_laser.set_mode.bind(FinalLaser.Mode.NONE)),
		Level.CMD_Callable.new(func():
			final_laser.set_mode(FinalLaser.Mode.NONE);
			Wwise.post_event_id(AK.EVENTS.MUSIC_BOSS_FINAL_PHASE3_START, AudioManager as Node);
			),
		dial_lvl_4_final_boss_chase_idle.cmd_stop_dialogue(),
		Level.CMD_Await_AsyncCallable.new(func():
			stone_particles.emitting = true;
			
			final_laser.set_mode(FinalLaser.Mode.NONE);
			var t := create_tween();
			var old_pos := eva_car.position;
			t.tween_property(eva_car, "position", Vector3(0, eva_car.position.y,-37), 1.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART);
			lvl.cam.tween_speed(-16, 1.5, LevelCameraController.MovementAxis.Z,  Tween.TRANS_SINE, Tween.EASE_IN);
			t.tween_callback(func():
				eva_car.basis = Basis.looking_at(Vector3.BACK + Vector3.LEFT * 0.35, Vector3.UP, true)
				eva_car.position.x = 2.75;
				
				smoke_particles.emitting = true;
				
				CameraShaker.screen_shake(crash_screen_shake);
				sfx_drag.stop_loop();
				set_phase(2);
				eva_car.reparent(camera_follow.get_parent());
				lvl.cam.tween_speed(0, 4.0, LevelCameraController.MovementAxis.Z, Tween.TRANS_SINE, Tween.EASE_IN_OUT);
				);
			await t.finished;
			, self),
	])

func desperate_mode(lvl:Level)->Level.CMD:
	return Level.CMD_Parallel_Complete.new([
		Level.CMD_Sequence.new([
			Level.CMD_Callable.new(sfx_cry.start_loop),
			dial_lvl_4_final_boss_crash.cmd_dialogue(true),
			dial_lvl_4_final_boss_crash_idle.cmd_dialogue(false),
		]),
		Level.CMD_Sequence.new([
			Level.CMD_Sequence.new([
				Level.CMD_Callable.new(make_spirit),
				Level.CMD_Wait_Seconds_Dynamic.new(func(): return 0.15 + randf_range(1.05, 2.35) * boss_health.get_health_percentage()),
			], 6),
			Level.CMD_Wait_Seconds.new(2.85),
		], -1),
		Level.CMD_Sequence.new([
			Level.CMD_Wait_Seconds.new(4),
			Level.CMD_Sequence.new([
				Level.CMD_Callable.new(func shoot_circle():
					var difficulty:float = 1.0 - inverse_lerp(0, percentage_level_3, boss_health.get_health_percentage());
					var amount:int = roundi(lerpf(2, 7, difficulty));
					var speed:float = lerpf(5, 2, difficulty);
					var angle_speed:float = PI * 0.025;
					sfx_shoot.post_event();
					make_shot_circle(amount, PI, speed, angle_speed);
					make_shot_circle(ceili(amount/2), PI, speed, -angle_speed);
					),
				Level.CMD_Wait_Seconds.new(1.25),
				#Level.CMD_Wait_Seconds_Dynamic.new(func(): return 0.15 + randf_range(1.05, 2.35) * boss_health.get_health_percentage()),
			], 10),
		], -1),
		
		## random copters
		Level.CMD_Sequence.new([
			Level.CMD_Wait_Callable.new(func():
				return boss_health.get_health_percentage() < percentage_level_3 * 0.85;
				),
			Level.CMD_Sequence.new([
				Level.CMD_Callable.new(func():
					var is_right:bool = randf() > 0.5;
					var entry:Vector2 = Vector2(8 if is_right else -8, roundf(randf_range(1, 6)));
					var dir:Vector3 = Vector3.LEFT if is_right else Vector3.RIGHT;
					var copters:Array[int] = [0,0,0,0,0];
					var distances:Array[float] = [];
					for i in range(roundi(randf_range(2, 5))):
						var value:float = roundf(randf_range(2,6))
						if i == 0: 
							value += 5;
							if is_right: value = -value;
						else:
							if randf() < 0.5: 
								value = -value;
						distances.append(value);
					distances[distances.size() - 1] *= 100;
					print("Making %s in %s to %s distances %s" % [copters, entry, dir, distances]);
					AI_Roboto_Copter.make_copters_quick(lvl, [COPTER], copters, lvl.cam.get_stage_grid_pos(lvl.stage, entry.x, entry.y), dir, distances, "copter");
					),
				Level.CMD_Wait_Seconds_Dynamic.new(func():
					return roundf(randf() * 1.5 + lerpf(3, 8, inverse_lerp(0, percentage_level_3, boss_health.get_health_percentage())));
					),
			], -1),
		]),
	]);
	
func end_transition(lvl:Level)->Level.CMD:
	return Level.CMD_Sequence.new([
		Level.CMD_Callable.new(func():
			Game.instance.kill_all_projectiles();
			HUD.instance.show_boss_death();
			
			sfx_cry.stop_loop();
			sfx_death.post_event();
			
			HUD.instance.make_screen_effect(HUD.ScreenEffect.LongFlash);
			stone_particles.amount = 80;
			end_camera_shake.durationIn = end_duration + end_duration_after_jump;
			CameraShaker.screen_shake(end_camera_shake)
			),
		dial_lvl_4_final_boss_crash.cmd_stop_dialogue(),
		dial_lvl_4_final_boss_crash_idle.cmd_stop_dialogue(),
		cmd_make_pillars_of_light(7, end_duration * 0.8),
		dial_lvl_4_final_boss_end_prepare.cmd_dialogue(true),
		Level.CMD_Await_AsyncCallable.new(func():
			eva_3.play("pre_defeat");
			await eva_3.animation_finished;
			, eva_3),
		Level.CMD_Parallel_Complete.new([
			dial_lvl_4_final_boss_end_jump.cmd_dialogue(true),
			Level.CMD_Await_AsyncCallable.new(func():
				eva_3.play("defeat");
				
				var t:= eva_3.create_tween();
				eva_3.speed_scale = 100.0;
				eva_3.no_depth_test = true;
				var target_pos:Vector3 = body.global_position + Vector3.LEFT + Vector3.BACK;
				eva_3.global_position -= (target_pos - eva_3.global_position).normalized() * 0.5;
				t.set_parallel();
				t.tween_property(eva_3,"speed_scale", 0.15, end_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
				t.tween_property(eva_3, "global_position", target_pos, end_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC);
				t.tween_callback(func():
					ended_animation.emit();
					).set_delay(end_duration);
				await ended_animation;
				, eva_3),
		]),
		Level.CMD_Callable.new(func():
			eva_3.speed_scale = 1;
			eva_3.play("pos_defeat");
			await AwaitUtils.any([eva_3.animation_looped, eva_3.animation_finished]);
			eva_3.play("end");
			),
		Level.CMD_Parallel_Complete.new([
			dial_lvl_4_final_boss_end.cmd_dialogue(false),
			cmd_make_pillars_of_light(5, end_duration_after_jump * 0.8),
			Level.CMD_Callable.new(func():
				var rock:Node3D = scene_rock_fall.instantiate();
				add_sibling(rock);
				rock.global_position = LevelCameraController.instance.get_pos();
				),
			Level.CMD_Wait_Seconds.new(end_duration_after_jump),
			Level.CMD_Callable.new(func():
				HUD.instance.make_screen_add(Color.TRANSPARENT, Color.WHITE, end_duration_after_jump,
						Tween.EASE_IN, Tween.TRANS_QUART, true);
				),
			Level.CMD_Callable.new(func():
				var t := LevelCameraController.instance.main_camera.create_tween();
				t.tween_property(LevelCameraController.instance.main_camera, "position:y", 2, end_duration_after_jump)\
						.as_relative().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CIRC);
				),
		]),
		Level.CMD_Await_AsyncCallable.new(func():
			await ending_sequence.ending_sequence();
			, ending_sequence),
	])

func cmd_laser_squiggly(on:bool, time:float):
	return Level.CMD_Callable.new(final_laser.set_squiggly.bind(on, time));

func cmd_laser_squiggly_treat(intensity01:float, time:float, percentage_in:float):
	return Level.CMD_Sequence.new([
		Level.CMD_Callable.new(final_laser.make_squiggly_treat.bind(intensity01, time, percentage_in)),
		Level.CMD_Wait_Seconds.new(time),
	])


func cmd_laser(pre_time:float, on_time:float, off_time:float, laser_angle_velocity:float, direct_to_player:bool):
	return Level.CMD_Sequence.new([
		Level.CMD_Parallel.new([
			Level.CMD_Process.new(func(delta:float):
				if direct_to_player:
					direct_laser_to_player(delta, laser_angle_velocity);
				return false;
				),
			Level.CMD_Sequence.new([
				Level.CMD_Callable.new(final_laser.set_mode.bind(FinalLaser.Mode.PRE)),
				Level.CMD_Wait_Seconds.new(pre_time),
				Level.CMD_Callable.new(final_laser.set_mode.bind(FinalLaser.Mode.ON)),
				Level.CMD_Wait_Seconds.new(on_time),
			]),
		]),
		Level.CMD_Callable.new(final_laser.set_mode.bind(FinalLaser.Mode.NONE)),
		Level.CMD_Wait_Seconds.new(off_time),
	]);

func direct_laser_to(delta:float, direction:Vector3, velocity_angle:float):
	var z:Vector3 = final_laser.global_basis.z;
	var signed_angle = z.signed_angle_to(direction, Vector3.UP);
	var angle:float = move_toward(0, signed_angle, delta * deg_to_rad(velocity_angle) * randf_range(-0.25, 2.25));
	final_laser.global_basis = final_laser.global_basis.rotated(Vector3.UP, angle);

func direct_laser_to_player(delta:float, velocity_angle:float):
	var player_pos:Vector3 = Player.get_closest_position(final_laser.global_position, true, final_laser.global_position + Vector3.BACK * 10);
	var direction := player_pos - final_laser.global_position;
	direction.y = 0;
	direct_laser_to(delta, direction.normalized(), velocity_angle);


func make_spirit():
	var superior:bool = randf() > 0.5;
	var where:Node3D = graphic.instantiate_place_sup if superior else graphic.instantiate_place_inf;
	graphic.bump(superior, 0.25, 
			Tween.EASE_OUT, Tween.TRANS_SINE, 0.15,
			Tween.EASE_IN, Tween.TRANS_CIRC, 0.6);
	if superior:
		for vfx in spawn_vfx_up: vfx.emitting = true;
	else:
		for vfx in spawn_vfx_down: vfx.emitting = true;
	
	var spirit:Projectile_IvoSpirit = InstantiateUtils.InstantiateInSamePlace3D(spirit_scene, body.get_parent_node_3d());
	spirit.global_position = where.global_position;
	var t:= spirit.create_tween();
	var direction = {
		value = Player.get_closest_direction(spirit.global_position, true),
	};
	t.tween_property(spirit, "position",
			VectorUtils.get_circle_point(randf_range(-PI, PI) * 0.5) * randf_range(0.75, 1.0) * spirit_radius +\
			Vector3.UP * spirit_height,
			2).as_relative().set_ease(Tween.EASE_IN_OUT);
	spirit.self_create();
	spirit.warned.connect(func():
		direction.value = Player.get_closest_direction(spirit.global_position, true)
		)
	spirit.created.connect(func():
		var free_enemy:Node3D = deactivated_robot.get_free_enemy();
		if free_enemy:
			spirit.tween_to_something(free_enemy, func():
				deactivated_robot.activate(free_enemy);
				spirit.heal_feedback();
				)
		else:
			spirit.global_basis = Basis.looking_at(direction.value, Vector3.UP, true);
			spirit.attack_feedback(body);
			InstantiateUtils.InstantiateInTree(spirit_scene_shot, spirit);
			spirit.queue_free();
		,CONNECT_ONE_SHOT);

var enemies:Array = [
	[
		PIZZA,
		PIZZA,
		PIZZA,
		PIZZA,
		LASER,
		LASER,
		LASER,
		LASER,
		JACARE,
	],
	[
		LASER,
		LASER,
		LASER,
		LASER,
		SUPER_PIZZA,
		SUPER_PIZZA,
		SUPER_PIZZA,
		SUPER_PIZZA,
		JACARE,
		JACARE,
		JACARE,
		JACARE,
		BRAWNY,
		BRAWNY,
	]
];

var current_array:int = -1;



func get_next_enemy()->PackedScene:
	if current_array >= enemies.size():
		return RUST;
	if current_array < 0 or enemies[current_array].size() == 0:
		current_array += 1;	
		if current_array < enemies.size():
			enemies[current_array].shuffle();
	if current_array >= enemies.size():
		return RUST;
	else:
		return enemies[current_array].pop_back();

func make_pillar_fall(duration:float):
	Boss_Ivo_Pillar.throw_one_pillar(duration);

func make_stone_enemy():
	esteira.add_enemy(get_next_enemy().instantiate());

func set_phase(phase:int):
	LevelEnvironment.set_tree_parameter("boss_phase", phase);
	var i:int = 0;
	for node in eva_phases:
		node.visible = i == phase;
		i += 1;

func cmd_point_laser_to_player(velocity_angle:float)->Level.CMD:
	return Level.CMD_Nop.new();
	
func cmd_make_pillars_of_light(amount:int, duration:float)->Level.CMD:
	return Level.CMD_Callable.new(func():
		var pillars_place:SpawnArea = %PillarsOfLight;
		VFX_Utils.make_vfxs_in_region_directional(
				create_tween(), 
				[VFX_Utils.VFX_PILLAR_OF_LIGHT], 
				pillars_place, 
				pillars_place,
				amount,
				duration)
		);
		
func cmd_shot_circle(amount_shots:int, angle:float, speed_angle:float)->Level.CMD:
	return Level.CMD_Callable.new(make_shot_circle.bind(amount_shots, angle, speed_angle));
		
func make_shot_circle(amount_shots:int, angle:float, speed:float, speed_angle:float):
	var inst := Projectile_Costellation.create_costellation_circle(amount_shots, angle, speed, speed_angle)
	InstantiateUtils.get_topmost_instantiate_node().add_child(inst);
	inst.position = body.global_position;
	inst.position.y = 0.5;
