class_name Boss_EvilHand extends LHH3D

const BOSS_5_A = preload("res://systems/boss/boss_5_a.tres")
const BossHandAnimationTree = preload("res://elements/enemy/bosses/hand/boss_hand_animation_tree.gd")
const COPTER = preload("res://elements/enemy/copter/enemy_roboto_copter.tscn")

@onready var boss_health: Health = $CharacterBody3D/Health
@onready var body: CharacterBody3D = $CharacterBody3D
@onready var shaker: Node3DShaker = $CharacterBody3D/Node3DShaker
@onready var animation_tree: BossHandAnimationTree = $CharacterBody3D/Node3DShaker/boss_hand/AnimationTree
@onready var death_marker: Marker3D = %DeathMarker
@onready var death_aabb: VisibleOnScreenNotifier3D = %DeathAABB
@onready var eva_car: Node3D = %eva_car
@onready var eva_car_dest: Node3D = $eva_car_dest
@onready var eva_outside: AnimatedSprite3D = %EvaOutside

@onready var dial_lvl_4_mid_boss_intro_1: QuickDialogue = %dial_lvl4_mid_boss_intro_1
@onready var dial_lvl_4_mid_boss_intro_2: QuickDialogue = %dial_lvl4_mid_boss_intro_2
@onready var dial_lvl_4_mid_boss_intro_3: QuickDialogue = %dial_lvl4_mid_boss_intro_3
@onready var dial_lvl_4_mid_boss_monologue_1: QuickDialogue = %dial_lvl4_mid_boss_monologue_1
@onready var dial_lvl_4_mid_boss_monologue_2: QuickDialogue = %dial_lvl4_mid_boss_monologue_2
@onready var dial_lvl_4_mid_boss_monologue_attack: QuickDialogue = %dial_lvl4_mid_boss_monologue_attack
@onready var dial_lvl_4_mid_boss_idle: QuickDialogue = %dial_lvl4_mid_boss_idle
@onready var dial_lvl_4_mid_boss_end: QuickDialogue = %dial_lvl4_mid_boss_end

@onready var sfx_appear: AkEvent3D = $CharacterBody3D/Sounds/SFX_Appear
@onready var sfx_appear_punch_pre: AkEvent3D = $CharacterBody3D/Sounds/SFX_Appear_Punch_Pre
@onready var sfx_appear_punch: AkEvent3D = $CharacterBody3D/Sounds/SFX_Appear_Punch
@onready var sfx_death: AkEvent3D = $CharacterBody3D/Sounds/SFX_Death
@onready var sfx_death_leave: AkEvent3D = $CharacterBody3D/Sounds/SFX_Death_Leave
@onready var sfx_tap_lift: AkEvent3D = $CharacterBody3D/Sounds/SFX_Tap_Lift
@onready var sfx_tap_hit: AkEvent3D = $CharacterBody3D/Sounds/SFX_Tap_Hit
@onready var sfx_punch_prepare: AkEvent3D = $CharacterBody3D/Sounds/SFX_Punch_Prepare
@onready var sfx_punch_attack: AkEvent3D = $CharacterBody3D/Sounds/SFX_Punch_Attack
@onready var sfx_hold: AkEvent3DLoop = $CharacterBody3D/Sounds/SFX_Hold
@onready var sfx_shoot:AkEvent3D = $CharacterBody3D/Sounds/SFX_Shoot

@export var shot:PackedScene;
@export var tap_shot:PackedScene;
@export var shake_on_tap:CameraShakeData;
@export var shake_on_punch:CameraShakeData;
@export var punch_height:float = -1;
@export var primary_shot_origin:Node3D;
@export var secondary_shot_origin:Node3D;
@export var key_kill:Key = Key.KEY_K;
@export var boss_phase_percentage:float = 0.4;

@export_category("To be decided in level design")
@export var aabb_movement:VisibleOnScreenNotifier3D;
@export var aabb_taps:VisibleOnScreenNotifier3D;
@export var boss_death_pos:Node3D;
@export var backaway_distance:Vector3 = Vector3.BACK * 10 + Vector3.UP * 5;
@export var first_punch_distance = Vector3(0, 15, -2);
@export var center_position:Node3D;

@onready var eva_common: AnimatedSprite3D = %EvaCommon
@onready var eva_motorista: AnimatedSprite3D = %EvaMotorista

var original_position:Vector3;

var cant_attack:bool;
var cant_sub_attack:bool;

func _ready() -> void:
	original_position = body.position;
	await get_tree().create_timer(0.5).timeout;

	#QuickDialogue.assign_animation_parent(dial_lvl_4_mid_boss_intro_1, &"idle", &"speech");
	QuickDialogue.assign_animation_parent(dial_lvl_4_mid_boss_intro_2, &"idle", &"speech");
	QuickDialogue.assign_animation_parent(dial_lvl_4_mid_boss_intro_3, &"idle", &"speech");
	QuickDialogue.assign_animation_parent(dial_lvl_4_mid_boss_monologue_1, &"idle", &"speech");
	QuickDialogue.assign_animation_parent(dial_lvl_4_mid_boss_monologue_2, &"idle", &"speech");
	QuickDialogue.assign_animation_parent(dial_lvl_4_mid_boss_monologue_attack, &"idle", &"speech");
	QuickDialogue.assign_animation_parent(dial_lvl_4_mid_boss_idle, &"idle", &"speech");
	QuickDialogue.assign_animation_parent(dial_lvl_4_mid_boss_end, &"idle", &"speech");

	eva_outside.play(&"back");


func _process(delta:float):
	if Input.is_key_pressed(key_kill):
		boss_health.damage(Health.DamageData.new(boss_health.get_max_amount() * 0.05, self));

func shoot_once(origin:Node3D, direction_speed:Vector3, multiplier:float):
	var proj:ProjEnemyBasic = InstantiateUtils.InstantiateInTree(shot, body);
	proj.global_transform = Transform3D(Basis.looking_at(-direction_speed), origin.global_position + Vector3.UP * 0.5)
	proj.speedMultiplier = proj.speedMultiplier * multiplier;

func shoot_tap_shot():
	CameraShaker.screen_shake(shake_on_tap);
	var proj:Node3D = tap_shot.instantiate();
	InstantiateUtils.add_child(proj);
	var pos:Vector3 = body.global_position;
	pos.y = 0;
	proj.transform = Transform3D(Basis.looking_at(Vector3.BACK, Vector3.UP, true), pos)

func cmd_talk_while(dial:QuickDialogue, while_cmd:Level.CMD)->Level.CMD:
	return Level.CMD_Parallel_Complete.new([
		dial.cmd_dialogue(true),
		while_cmd,
	])

func cmd_intro(lvl:Level, arena_on:Callable)->Level.CMD:
	return Level.CMD_Sequence.new([
		cmd_talk_while(dial_lvl_4_mid_boss_intro_1, Level.CMD_Callable.new(func approach():
			eva_outside.play(&"back");
			body.position += backaway_distance;
			)),
		AI_Roboto_Copter.cmd_make_copters_quick(lvl, [COPTER], [0,0,0,0,0], func(): return lvl.stage.get_grid(-8, 15), Vector3.RIGHT,[4,-7,-8,7,4], "copter"),
		AI_Roboto_Copter.cmd_make_copters_quick(lvl, [COPTER], [0,0,0,0,0], func(): return lvl.stage.get_grid(8, 15), Vector3.LEFT,[-4,5,8,-5,-4], "copter"),
		Level.CMD_Await_AsyncCallable.new(func():
			eva_outside.play(&"turn");
			await get_tree().create_timer(0.4).timeout;
			eva_outside.play(&"idle");
			, self),
		dial_lvl_4_mid_boss_intro_2.cmd_dialogue(),
		cmd_talk_while(dial_lvl_4_mid_boss_intro_3, Level.CMD_Await_AsyncCallable.new(func lift_for_punch():
			var t:= create_tween();
			t.tween_callback(func():
				sfx_appear.post_event();
				)
			t.tween_property(body, "global_position", -backaway_distance, 6.5).as_relative().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT);
			t.tween_callback(func():
				sfx_appear_punch_pre.post_event();
				)
			t.tween_property(body, "global_position", first_punch_distance, 1.75).as_relative().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT);
			t.parallel().tween_property(animation_tree, "punch", 1.0, 1.25).set_delay(0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_IN_OUT);
			await t.finished;
			, self)),
		Level.CMD_Await_AsyncCallable.new(func first_punch():
			var t:= create_tween();
			eva_outside.play(&"attack");
			t.tween_callback(sfx_appear_punch.post_event);
			t.tween_property(body, "global_position", eva_outside.global_position + Vector3(3,-4,5), 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN);
			await t.finished;
			, self),
		Level.CMD_Callable.new(func():
			CameraShaker.screen_shake(shake_on_punch);
			eva_outside.queue_free();
			eva_common.visible = true;
			),

		## Hand starts to be like the fight

		Level.CMD_Wait_Seconds.new(1),
		Level.CMD_Await_AsyncCallable.new(func():
			var t:= create_tween();
			t.set_parallel();
			t.tween_property(body, "global_position", center_position.global_position, 2.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT);
			t.tween_property(animation_tree, "punch", 0.0, 1.25).set_delay(1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT);
			await t.finished;
			HUD.instance.show_boss_life(BOSS_5_A, boss_health.get_health_percentage)
			, self),
		Level.CMD_Parallel.new([
			dial_lvl_4_mid_boss_monologue_1.cmd_dialogue(true),
			Level.CMD_Sequence.new([
				cmd_normal_shooting(),
			], -1),
		]),
		Level.CMD_Parallel.new([
			dial_lvl_4_mid_boss_monologue_2.cmd_dialogue(true),
			Level.CMD_Sequence.new([
				cmd_normal_shooting(),
			], -1),
			Level.CMD_Sequence.new([
				cmd_move(get_direction(Vector3.RIGHT)),
				Level.CMD_Wait_Seconds.new(1),
				cmd_move(get_direction(Vector3.LEFT)),
				Level.CMD_Wait_Seconds.new(1.5),
				cmd_move(get_direction(Vector3.BACK)),
				Level.CMD_Wait_Seconds.new(2),
			], -1),
		]),
		Level.CMD_Parallel_Complete.new([
			Level.CMD_Callable.new(arena_on),
			Level.CMD_Sequence.new([
				dial_lvl_4_mid_boss_monologue_attack.cmd_dialogue(true),
				dial_lvl_4_mid_boss_idle.cmd_dialogue(false),
			]),
			Level.CMD_Sequence.new([
				Level.CMD_Wait_Seconds.new(1.45),
				cmd_punch(),
			])
		]),
		Level.CMD_Callable.new(func():
			boss_health.damage_reduction = 0;
			),
	]);

func cmd_boss(lvl:Level, arena_on:Callable)->Level.CMD:
	return Level.CMD_Sequence.new([
		Level.CMD_Print_Log.new("boss time"),
		Level.CMD_Parallel.new([
			Level.CMD_Sequence.new([
				Level.CMD_Parallel.new([
					cmd_intro(lvl, arena_on),
					Level.CMD_Wait_Callable.new(func():
						return Input.is_key_pressed(KEY_S);
						)
				]),
				Level.CMD_Parallel.new([
					cmd_phase_1(),
					Level.CMD_Wait_Callable.new(func phase_2_condition():
						## Condition for phase 1 to end
						return boss_health.get_health_percentage() < boss_phase_percentage;
						)
				]),
				cmd_phase_transition(),
				cmd_phase_2(),
			]),
			Level.CMD_Wait_Callable.new(func end_condition():
				return !boss_health.is_alive();
				),
		]),
		cmd_boss_end()
	]);

func cmd_phase_1()->Level.CMD:
	return Level.CMD_Parallel.new([
		## Normal shooting
		Level.CMD_Sequence_Random.new([
			cmd_normal_shooting(),
			cmd_normal_shooting(),
			cmd_normal_shooting(),
			cmd_shoot_to_player(primary_shot_origin, 0),
		], -1),

		## Movement
		Level.CMD_Sequence.new([
			Level.CMD_Print_Log.new("Hand Phase1: Movements --"),
			Level.CMD_Sequence_Random.new([
				cmd_move(Vector3.RIGHT),
				cmd_move(Vector3.LEFT),
				cmd_move(Vector3.BACK),
				cmd_move(Vector3.RIGHT + Vector3.BACK),
				cmd_move(Vector3.LEFT + Vector3.BACK),
				Level.CMD_Wait_Seconds.new(1),
				Level.CMD_Wait_Seconds.new(1.5),
				Level.CMD_Wait_Seconds.new(2),
				Level.CMD_Wait_Seconds.new(2.5),
				Level.CMD_Wait_Seconds.new(1),
				Level.CMD_Wait_Seconds.new(1.5),
				Level.CMD_Wait_Seconds.new(2),
				Level.CMD_Wait_Seconds.new(2.5),
			])
		], -1),


		## Special attacks
		Level.CMD_Sequence.new([
			Level.CMD_Print_Log.new("Hand Phase1: Special Attack random array --"),
			Level.CMD_Wait_Seconds.new(0.5),
			Level.CMD_Sequence_Random.new([
				cmd_tap_attack(0.75, 1),
				cmd_tap_attack(0.95, 2),
				Level.CMD_Wait_Seconds.new(1),
				Level.CMD_Wait_Seconds.new(2),
				Level.CMD_Wait_Seconds.new(3),
				Level.CMD_Wait_Seconds.new(4),
			]),
		], -1),
	])

func cmd_phase_transition()->Level.CMD:
	return Level.CMD_Sequence.new([
		cmd_move(Vector3.RIGHT * 0.25),
		cmd_turn_two_fingers(1),
		Level.CMD_Wait_Seconds.new(1),
	])

func cmd_phase_2()->Level.CMD:
	return Level.CMD_Parallel.new([
		Level.CMD_Sequence_Random.new([
			cmd_normal_shooting(),
		], -1),

		Level.CMD_Sequence_Random.new([
			Level.CMD_Wait_Seconds.new(2),
			Level.CMD_Wait_Seconds.new(3),
			cmd_shoot_to_player(primary_shot_origin, 1),
			cmd_shoot_to_player(secondary_shot_origin, 1),
			cmd_shoot_to_player(primary_shot_origin, 2),
			cmd_shoot_to_player(secondary_shot_origin, 2),
		], -1),


		Level.CMD_Sequence.new([
			Level.CMD_Print_Log.new("Hand Phase2: Movements --"),
			Level.CMD_Sequence_Random.new([
				cmd_move(Vector3.RIGHT, 4),
				cmd_move(Vector3.LEFT, 4),
				cmd_move(Vector3.BACK, 4),
				cmd_move(Vector3.FORWARD, 4),
				cmd_move(Vector3.RIGHT + Vector3.BACK, 3),
				cmd_move(Vector3.LEFT + Vector3.BACK, 3),
				cmd_move(Vector3.RIGHT + Vector3.FORWARD, 3),
				cmd_move(Vector3.LEFT + Vector3.FORWARD, 3),
				Level.CMD_Wait_Seconds.new(1),
				Level.CMD_Wait_Seconds.new(1.5),
				Level.CMD_Wait_Seconds.new(2),
				Level.CMD_Wait_Seconds.new(2.5),
				Level.CMD_Wait_Seconds.new(1),
				Level.CMD_Wait_Seconds.new(1.5),
				Level.CMD_Wait_Seconds.new(2),
				Level.CMD_Wait_Seconds.new(2.5),
			])
		], -1),


		## Special attacks
		Level.CMD_Sequence.new([
			Level.CMD_Print_Log.new("Hand Phase2: Special Attack random array --"),
			Level.CMD_Wait_Seconds.new(0.5),
			Level.CMD_Sequence_Random.new([
				cmd_tap_attack(0.75, 1),
				cmd_tap_attack(1, 2),
				cmd_punch(),
				cmd_punch(),
				cmd_punch(),
				cmd_tap_attack(0.95, 3),
				Level.CMD_Wait_Seconds.new(2),
				Level.CMD_Wait_Seconds.new(2.5),
				Level.CMD_Wait_Seconds.new(4),
				Level.CMD_Wait_Seconds.new(4.5),
				Level.CMD_Wait_Seconds.new(5),
				Level.CMD_Wait_Seconds.new(8),
			]),
		], -1),
	])

func cmd_boss_end()->Level.CMD:
	return Level.CMD_Sequence.new([
		Level.CMD_Callable.new(func():
			HUD.instance.make_screen_effect(HUD.ScreenEffect.LongFlash);
			Game.instance.kill_all_projectiles();
			shaker.shake_amplitude_ratio = 1.0;

			animation_tree.punch = 0.0;
			animation_tree.touching = false;
			animation_tree.attack = false;
			animation_tree.two_fingers = 0.0;

			),
		Level.CMD_Callable.new(func():
			var arr:Array = [
				dial_lvl_4_mid_boss_idle,
				dial_lvl_4_mid_boss_intro_1,
				dial_lvl_4_mid_boss_intro_2,
				dial_lvl_4_mid_boss_monologue_1,
				dial_lvl_4_mid_boss_monologue_2,
				dial_lvl_4_mid_boss_monologue_attack,
			]
			for o in arr:
				if is_instance_valid(o):
					var diag = o as QuickDialogue;
					if diag:
						diag.stop_dialogue();
			),
		Level.CMD_Await_AsyncCallable.new(func():
			var t := create_tween();
			t.tween_property(body, "global_position", boss_death_pos.global_position, 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_ELASTIC);
			t.tween_interval(0.25);
			await t.finished;
			, eva_car),
		dial_lvl_4_mid_boss_end.cmd_dialogue(true),
		Level.CMD_Await_AsyncCallable.new(func():
			var t := create_tween();
			t.tween_callback(func():
				eva_common.visible = false;
				eva_car.reparent(eva_car_dest.get_parent_node_3d());
				)
			t.tween_callback(sfx_death_leave.post_event);
			t.tween_property(eva_car, "global_transform", eva_car_dest.global_transform, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN);
			TransformUtils.tremble_up_rotation_coin(eva_car, t, 0.5, 4.2, Vector3.ZERO, 2, 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT);
			await t.finished;
			, eva_car),
		Level.CMD_Wait_Seconds.new(0.05),
		Level.CMD_Callable.new(func():
			HUD.instance.make_screen_effect(HUD.ScreenEffect.BossDeath);
			VFX_Utils.make_boss_explosion(death_marker, death_aabb);
			HUD.instance.hide_boss_life();
			AudioManager.post_music_event(AK.EVENTS.MUSIC_STOP)
			),
		Level.CMD_Wait_Seconds.new(2.5),
		Level.CMD_Callable.new(func():
			var t := create_tween();
			t.tween_property(eva_car, "global_position:z", -10, 2).as_relative().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC);
			t.tween_callback(func():
				eva_car.queue_free();
				)
			),
		Level.CMD_Wait_Seconds.new(HUD.boss_flash_duration - 2.5),
		Level.CMD_Callable.new(func():
			self.queue_free();
			)
	]);


func shoot_costellation(where_from:Node3D, vel_angle:float):
	if cant_attack:
		return;
		
	sfx_shoot.post_event();
	
	var inst := Projectile_Costellation.create_costellation_circle(14, PI, 4, deg_to_rad(vel_angle))
	InstantiateUtils.get_topmost_instantiate_node().add_child(inst);
	inst.position = where_from.global_position;
	inst.position.y = 0.5;

func get_direction(d:Vector3)->Vector3:
	return d.rotated(Vector3.UP, deg_to_rad(randf_range(-15, 15)))

func cmd_move(direction:Vector3, speed:float = 2.0):
	return Level.CMD_Await_AsyncCallable.new(func():
		var pos := center_position.global_position + direction * randf_range(1.5, 4);
		var aabb := aabb_movement.global_transform * aabb_movement.aabb
		pos.x = clampf(pos.x, aabb.position.x, aabb.position.x + aabb.size.x);
		pos.y = original_position.y;
		pos.z = clampf(pos.z, aabb.position.z, aabb.position.z + aabb.size.z);

		while cant_attack:
			await get_tree().physics_frame;

		cant_sub_attack = true;
		var t:= create_tween();
		t.tween_property(body, "global_position", pos, (pos - body.global_position).length() / speed)\
				.set_ease(Tween.EASE_IN_OUT)\
				.set_trans(Tween.TRANS_QUART);

		await t.finished;
		cant_sub_attack = false;

		, self);

func cmd_shoot_to_player(origin:Node3D, delay_after:float):
	return Level.CMD_Sequence.new([
		Level.CMD_Print_Log.new("Hand: Shoot to player"),
		Level.CMD_Callable.new(func():
			if cant_attack: return;

			sfx_shoot.post_event();

			var main_dir:Vector3 = Player.get_closest_direction(origin.global_position).normalized();
			shoot_once(origin, main_dir.rotated(Vector3.UP, deg_to_rad(-2.5)), randf_range(0.9, 1.1));
			shoot_once(origin, main_dir.rotated(Vector3.UP, deg_to_rad(0)), randf_range(0.9, 1.1));
			shoot_once(origin, main_dir.rotated(Vector3.UP, deg_to_rad(2.5)), randf_range(0.9, 1.1));
			),
		Level.CMD_Wait_Seconds.new(delay_after),
	]);

func cmd_normal_shooting()->Level.CMD:
	return Level.CMD_Branch.new(func use_two_fingers_condition():
		return animation_tree.two_fingers < 0.9;
		,
		Level.CMD_Sequence.new([
			Level.CMD_Callable.new(shoot_costellation.bind(primary_shot_origin, -15)),
			Level.CMD_Wait_Seconds.new(1.35),
		]),
		Level.CMD_Sequence.new([
			Level.CMD_Callable.new(shoot_costellation.bind(primary_shot_origin, -20)),
			Level.CMD_Wait_Seconds.new(1.05),
			Level.CMD_Callable.new(shoot_costellation.bind(secondary_shot_origin, 20)),
			Level.CMD_Wait_Seconds.new(1.05),
		]));

func cmd_turn_two_fingers(two_fingers_value:float)-> Level.CMD:
	return Level.CMD_Await_AsyncCallable.new(func():
		var t := create_tween();
		t.tween_property(animation_tree, "two_fingers", two_fingers_value, randf_range(0.5, 2.5));
		await t.finished;
		, animation_tree)

func cmd_wait_until_can_sub_attack():
	return Level.CMD_Wait_Callable.new(func(): return !self.cant_sub_attack);

func cmd_punch()->Level.CMD:
	return Level.CMD_Sequence.new([
		cmd_wait_until_can_sub_attack(),
		Level.CMD_Print_Log.new("Hand: Hand punch"),
		Level.CMD_Callable.new(func(): self.cant_attack = true),
		Level.CMD_Await_AsyncCallable.new(func():
			var t := create_tween();
			## punch prepare, close hand
			var t0 := create_tween();
			t0.set_parallel();
			t0.tween_callback(func():
				sfx_punch_prepare.post_event();
				)
			t0.tween_property(animation_tree,"punch", 1.1, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SPRING);
			t0.tween_property(body, "position:y", punch_height, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC);
			t0.tween_property(body, "position:x", 6.0, 0.75).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SPRING);
			t0.tween_property(body, "position:z", 8.0, 0.4).as_relative().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD);
			t0.tween_property(body, "rotation:z", PI * 0.5, 0.4).as_relative().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SPRING);

			## punch movement
			var t1 := create_tween();
			t1.set_parallel();
			t1.tween_callback(func():
				sfx_punch_attack.post_event();
				)
			t1.tween_property(body, "position:z", 50, 0.5).as_relative().set_ease(Tween.EASE_IN);
			t1.tween_property(body, "position:y", 30, 1.0).as_relative().set_ease(Tween.EASE_IN).set_delay(0.15);

			## punch return
			var t2:= create_tween();
			t2.set_parallel();
			t2.tween_property(body, "position:x", -25, 0.01).as_relative().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD);
			t2.chain().tween_property(body, "position:x", +25.0 - 6.0, 0.85).as_relative().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD);
			t2.tween_property(body, "position:z", -50 - 8.0, 0.45).as_relative().set_ease(Tween.EASE_OUT);
			t2.tween_property(body, "position:y", -30, 1.1).as_relative().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC);
			t2.tween_property(body, "rotation:z", -PI * 0.5, 0.4).as_relative().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SPRING);

			## open hand
			var t3:= animation_tree.create_tween();
			t3.set_parallel();
			t3.tween_property(animation_tree,"punch", 0.0, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SPRING);
			t3.tween_property(body, "position:y", original_position.y, 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CIRC);

			## the tween
			t.tween_subtween(t0);
			t.tween_subtween(t1);
			t.tween_subtween(t2);
			t.tween_subtween(t3);
			await t.finished;
			, self),
		Level.CMD_Wait_Seconds.new(0.05),
		Level.CMD_Callable.new(func(): self.cant_attack = false),
	]);

func cmd_tap_attack(think_time:float, amount_taps:int)->Level.CMD:
	return Level.CMD_Sequence.new([
		cmd_wait_until_can_sub_attack(),
		Level.CMD_Print_Log.new("Hand: Tap attack"),
		Level.CMD_Await_AsyncCallable.new(func():
			var t := create_tween();
			t.tween_callback(func():
				self.cant_attack = true;
				animation_tree.touching = true;

				sfx_tap_lift.post_event();
				);
			#t.tween_interval(think_time);
			var last_pos:Vector3 = Vector3.ONE * 9999;


			while amount_taps > 0:
				var rand_pos:Vector3 = VectorUtils.rand_vector3_in_screen_notifier(aabb_taps);
				rand_pos.y = original_position.y;
				if (last_pos - rand_pos).length() < 2.0:
					rand_pos += (rand_pos-last_pos).normalized() * 2;
				last_pos = rand_pos;

				t.tween_property(body, "global_position", rand_pos, randf_range(think_time * 0.75, think_time * 1.2)).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC);
				t.tween_callback(func():
					animation_tree.attack = true;
					sfx_tap_hit.post_event();
					)
				t.tween_interval(0.1);
				t.tween_callback(func():
					animation_tree.attack = false;
					shoot_tap_shot();
					)
				amount_taps -= 1;
				if amount_taps > 0:
					t.tween_interval(think_time * 0.25);

			t.tween_interval(think_time * 0.5);

			t.tween_callback(func():
				self.cant_attack = false;
				animation_tree.attack = false;
				animation_tree.touching = false;
				);

			await t.finished;

			, self),
	]);

func cmd_jump(height:float, time_up_min:float, time_up_max:float, time_hang_min:float, time_hang_max:float, time_down_min:float, time_down_max:float, callable_when_going_down:Callable = Callable())->Level.CMD:
	return Level.CMD_Await_AsyncCallable.new(func():
		var t := body.create_tween();
		t.tween_property(body, "global_position", Vector3.UP * height, randf_range(time_up_min, time_up_max)).set_ease(Tween.EASE_OUT).as_relative();
		t.tween_interval(randf_range(time_hang_min, time_hang_max));
		if callable_when_going_down.is_valid():
			t.tween_callback(callable_when_going_down);
		t.tween_property(body, "global_position", -Vector3.UP * height, randf_range(time_down_min, time_down_max)).set_ease(Tween.EASE_IN).as_relative();
		await t.finished;
		t = null;
		, body);


func _on_health_dead_parameterless() -> void:
	sfx_death.post_event();
