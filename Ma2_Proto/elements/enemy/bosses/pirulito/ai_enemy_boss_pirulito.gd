class_name Boss_Pirulito
extends Node3D

const BOSS_1 = preload("res://systems/boss/boss_1.tres")

const ENEMY_BOSS_PIRULITO_PIZZA = preload("res://elements/enemy/bosses/pirulito/enemy_boss_pirulito_pizza.tscn")
const ENEMY_BOSS_PIRULITO_NANDO_SIDEKICK = preload("res://elements/enemy/bosses/pirulito/enemy_boss_pirulito_nando_sidekick.tscn")
const PROJ_ENEMY_BASIC = preload("res://elements/enemy/projectiles/proj_basic/proj_enemy_basic.tscn")
const PROJ_ENEMY_BASIC_GLOBAL = preload("res://elements/enemy/projectiles/proj_basic/proj_enemy_basic_global.tscn")
const ENEMY_ROBOTO_COPTER = preload("res://elements/enemy/copter/enemy_roboto_copter.tscn")

@onready var boss_hand_eva_shield: Element_EvaShield = $BossHand_Eva_Shield
@export var posteShotDirectionRight:Vector3 = Vector3.BACK;
@onready var graphic:Node3D = $Node3D
@onready var pirulito_graphic:Graphic_Boss_Pirulito = $pirulito
var sprite: Graphic_Boss_Pirulito_NandoENene:
	get:
		return pirulito_graphic.nando_e_nene;
@onready var pirulito_destroyed: Node3D = $pirulito_destroyed

@onready var hand_r:Boss_Pirulito_Lamp = pirulito_graphic.lamp_right;
@onready var hand_l:Boss_Pirulito_Lamp = pirulito_graphic.lamp_left;
@onready var arm_space_r:Node3D = $ArmSpaceR
@onready var arm_space_l:Node3D = $ArmSpaceL
@onready var health:Health = %Health
@onready var global_shot_origin: Marker3D = %GlobalShotOrigin
var poste_shot_origin_right:Node3D:
	get:
		return pirulito_graphic.shot_right_origin;
var poste_shot_origin_left:Node3D:
	get:
		return pirulito_graphic.shot_left_origin;
@onready var nando_destination: Marker3D = $"Nando Destination"
@export var _flow_player:TextFlowPlayerBubbles
@onready var explosion_region: VisibleOnScreenNotifier3D = $"Explosion Region"
@export var vfx_explosion:Array[PackedScene];
@export var vfx_pointed_explosion:Array[PackedScene];
@export var cannon_middle_surprise:AI_Cannon;
@export var amount_life_phase_2:float = 0.3 * 120;
@export var cannon_baby_middle_percentage:float = 0.15;
@onready var lights_parent: Node3D = $lights_parent

@onready var sfx_first_phase: AkEvent3D = $Sounds/SFX_FirstPhase
@onready var sfx_second_phase: AkEvent3D = $Sounds/SFX_SecondPhase
@onready var sfx_death: AkEvent3D = $Sounds/SFX_Death

@export var copter_lines:Array[ChildLine3D] = [];


var _bubble_speaker:TextFlowBubbleSpeaker
var _speaker_id:StringName = &"pirulito_nando";

const dialogue_intro:StringName = &"dial_lvl1_boss_part1_intro"
const dialogue_intro_interrupt:StringName = &"dial_lvl1_boss_part1_intro_finish"
const dialogue_1_idle:StringName = &"dial_lvl1_boss_part1_idle"
const dialogue_1_open:StringName = &"dial_lvl1_boss_part1_open_idle"
const dialogue_1_end:StringName = &"dial_lvl1_boss_part1_end"
const dialogue_2_intro:StringName = &"dial_lvl1_boss_part2_intro"
const dialogue_2_idle:StringName = &"dial_lvl1_boss_part2_idle"
const dialogue_2_end:StringName = &"dial_lvl1_boss_part2_end"
const dialogue_final_end:StringName = &"dial_lvl1_boss_nando_end";

enum Phase{
	Phase_Intro,
	Phase_1,
	Phase_2,
	Phase_Losing,
}

var phase:Phase:
	get:
		return phase;
	set(value):
		sprite.clear_stack();
		match value:
			Phase.Phase_Intro:
				sprite.add_stack(sprite.animation_intro_idle);
				sfx_first_phase.post_event();
			Phase.Phase_1:
				sprite.add_stack(sprite.animation_1_idle);
			Phase.Phase_2:
				sprite.add_stack(sprite.animation_2_idle);
				sfx_second_phase.post_event();
			Phase.Phase_Losing:
				sprite.add_stack(sprite.animation_losing_idle);
				sfx_death.post_event();
		phase = value;

var crowd_group:String = "crowd";

func _ready():
	set_vulnerable(false);
	cannon_middle_surprise.disabled = true;
	_bubble_speaker = TextFlowBubbleSpeaker.new();
	_bubble_speaker.followee = sprite.position_bubble;
	_bubble_speaker.bubble_started.connect(_animate_talk);
	_bubble_speaker.bubble_finished.connect(_animate_stop_talk);
	_flow_player.set_speaker(_bubble_speaker, _speaker_id);
	_bubble_speaker.voice = TextFlowBubbleSpeaker.SpeakerVoice.Nando
	boss_hand_eva_shield.set_on(false, false);

func _process(delta:float):
	_cheat_process(delta);
	pass;

var _cheat_did:bool;
func _cheat_process(delta:float):
	if Input.is_key_pressed(KEY_K) and not _cheat_did:
		_cheat_did = true;
		health.damage(Health.DamageData.new(50, self))
	else:
		_cheat_did = false;

func _invert(v:Vector3)->Vector3:
	return Vector3(-v.x, v.y, v.z);

func _destroyed_graphic():
	pirulito_graphic.hide_main_graphic();
	pirulito_destroyed.show();

func cmd_boss(level:Level)->Level.CMD:

	var pizza_matrix_0:Array = [
		[0, 1, 0],
		[1, 0, 1],
		[0, 1, 0],
		[1, 0, 1],
		[1, 0, 1],
		[0, 1, 0],
	]

	var pizza_matrix_l:Array = [
		[0, 0, 0],
		[0, 1, 1],
		[1, 0, 0]
	]

	var pizza_matrix_r:Array = [
		[0, 0, 0],
		[1, 1, 0],
		[0, 0, 1]
	]

	var show_boss_health = func show_b_health():
		HUD.instance.show_boss_life(BOSS_1, func(): return health.get_health_percentage())

	var nando:Array = [];

	var lasers:Array[Array] = [[hand_l,true], [hand_r,false]]
	lasers.shuffle();

	return Level.CMD_Sequence.new([
		## Dead air
		Level.CMD_Wait_Seconds.new(0.15),
		Level.CMD_Callable.new(func():
			phase = Phase.Phase_Intro;
			pirulito_graphic.set_lights(true);
			),
		Level.CMD_Wait_Seconds.new(1.00),
		Level.CMD_Callable.new(func():
			pirulito_graphic.set_open_sound(true);
			),
		Level.CMD_Wait_Seconds.new(1.25),
		## Intro
		Level.CMD_Parallel.new([
			##The sequence of pizzas
			Level.CMD_Sequence.new([
				Level.CMD_Callable.new(func():
					#pirulito_graphic.set_shield_started(true);
					boss_hand_eva_shield.set_on(true);
					),
				cmd_make_pizzas_and_wait(level, pizza_matrix_0, pizza_matrix_0, 2, Level.CMD.NopEternally()),
			]),
			##The cutscene, interruptable by vulnerable
			Level.CMD_Parallel.new([
				##Interrupt
				Level.CMD_Sequence.new([
					level.objs.cmd_wait_group(crowd_group),
					Level.CMD_Callable.new(func():
						show_boss_health.call();
						pirulito_graphic.set_open(true);
						##Interrupt dialogue here
						start_talk(dialogue_intro_interrupt, false);
						),
					Level.CMD_Wait_Forever.new(),
				]),
				##The cutscene
				Level.CMD_Sequence.new([
					Level.CMD_Wait_Seconds.new(2),
					Level.CMD_Callable.new(func():
						show_boss_health.call();
						pirulito_graphic.set_open(true);
						),
					Level.CMD_Wait_Seconds.new(1),
					cmd_talk(dialogue_intro),
					Level.CMD_Wait_Forever.new(),
				]),
			])
		]),

		## Phase 1 -------
		Level.CMD_Callable.new(func():
			phase = Phase.Phase_1;
			),
		Level.CMD_Parallel.new([
			Level.CMD_Wait_Callable.new(func(): return health.get_health() < amount_life_phase_2),
			Level.CMD_Sequence.new([
				cmd_phase_1_shooting_phases(level, false, 2, 1),
				Level.CMD_Parallel.new([
					cmd_phase_1_shooting_phases(level, true, 0, -1),
					Level.CMD_Sequence.new([
						cmd_laser(level, lasers[0][0], lasers[0][1]),
						Level.CMD_Wait_Seconds.new(3.5),
						cmd_laser(level, lasers[1][0], lasers[1][1]),
						Level.CMD_Wait_Seconds.new(3.5),
					], -1)
				])
			])
		]),

		## Phase 2 intro
		Level.CMD_Callable.new(func():
			print("boss phase 2 start");
			phase = Phase.Phase_2;
			pirulito_graphic.explode_tvs();
			pirulito_graphic.set_open(true);
			pirulito_graphic.set_open_sound(true);
			hand_r.set_flight(true, false);
			hand_l.set_flight(true, true);
			hand_r.set_flight_alternate(true);
			hand_l.set_flight_alternate(true);
			),
		Level.CMD_Sequence.new([
			Level.CMD_Callable.new(func():
				Game.instance.kill_all_enemies();
				nando.push_back(ENEMY_BOSS_PIRULITO_NANDO_SIDEKICK.instantiate());
				self.get_parent().add_child(nando[0]);
				nando[0].jump(self.global_position, nando_destination.global_position);
				),
		]),
		## Phase 2 -------
		Level.CMD_Parallel.new([
			Level.CMD_Sequence.new([
				cmd_talk(dialogue_2_intro, true),
				Level.CMD_Callable.new(func():
					start_talk(dialogue_2_idle, true, true);
					),
				Level.CMD_Wait_Forever.new(),
			]),
			Level.CMD_Sequence.new([
				Level.CMD_Wait_Callable.new(func(): return health.get_health_percentage() < cannon_baby_middle_percentage),
				Level.CMD_Callable.new(func():
					cannon_middle_surprise.disabled = false;
					),
				Level.CMD_Wait_Forever.new(),
			]),
			Level.CMD_Wait_Callable.new(func(): return not health.is_alive()),
			_cmd_shoot_constant(level, amount_life_phase_2 / health.max_amount),
		]),

		##Boss death animation
		Level.CMD_Callable.new(func():
			print("boss finished");
			phase = Phase.Phase_Losing;
			cannon_middle_surprise.disabled = true;

			if hand_l and is_instance_valid(hand_l):
				hand_l.stop_laser_constant();
			if hand_r and is_instance_valid(hand_r):
				hand_r.stop_laser_constant();

			nando[0].pre_lose();
			start_talk(dialogue_2_end, false, true);
			HUD.instance.show_boss_death()
			HUD.instance.make_screen_effect(HUD.ScreenEffect.LongFlash);
			Game.instance.kill_all_projectiles();

			pirulito_graphic.feedback_shake(true);
			),
		Level.CMD_Await_AsyncCallable.new(VFX_Utils.make_boss_explosion.bind(self, explosion_region), self),
		Level.CMD_Callable.new(func():
			pirulito_graphic.destroy();
			nando[0].hide();
			lights_parent.hide();
			pirulito_graphic.feedback_shake(false);
			_destroyed_graphic();
			start_talk(dialogue_final_end, false);
			),
		Level.CMD_Wait_Seconds.new(2.25),
		Level.CMD_Callable.new(func():
			await get_tree().create_timer(5).timeout;
			if is_instance_valid(self):
				self.queue_free();
			)

	]);

func cmd_phase_1_shooting_phases(level:Level, shuffle:bool, less_amount:int, repeats:int = -1)->Level.CMD:

	var pizza_matrix_1:Array = [
		[1, 0, 1],
		[0, 1, 0],
		[1, 0, 1]
	]
	var pizza_matrix_2:Array = [
		[0, 0, 0],
		[1, 0, 1],
		[0, 1, 0]
	]

	var cmds_phases:Array[Level.CMD] = [
		cmd_make_pizzas_and_wait(level, pizza_matrix_1, pizza_matrix_1, 2, Level.CMD_Sequence.new([
			cmd_shotgun(level, poste_shot_origin_left, pirulito_graphic.sfx_shot_left, [0, 15, 30], posteShotDirectionRight.normalized()),
			Level.CMD_Wait_Seconds.new(1),
			cmd_shotgun_in_player_direction(level, poste_shot_origin_right, pirulito_graphic.sfx_shot_right, [0, 15, 30]),
			Level.CMD_Wait_Seconds.new(1),
		], -1)),
		cmd_make_pizzas_and_wait(level, pizza_matrix_2, pizza_matrix_2, 3, Level.CMD_Sequence.new([
			cmd_machine_gun(level, 240, 0.05, 90, 18, 12, 6),
			Level.CMD_Wait_Seconds.new(2),
		], -1)),
		cmd_make_pizzas_and_wait(level, pizza_matrix_2, pizza_matrix_2, 2, Level.CMD_Sequence.new([
			cmd_shotgun(level, poste_shot_origin_left, pirulito_graphic.sfx_shot_left, [0, 22], posteShotDirectionRight.normalized()),
			Level.CMD_Wait_Seconds.new(0.45),
			cmd_shotgun(level, poste_shot_origin_right, pirulito_graphic.sfx_shot_right, [0, 22],  _invert(posteShotDirectionRight.normalized())),
			Level.CMD_Wait_Seconds.new(0.9),
		], -1)),
		cmd_make_pizzas_and_wait(level, pizza_matrix_2, pizza_matrix_2, 3, Level.CMD_Sequence.new([
			cmd_machine_gun(level, 120, 0.05, 90, 18, 12, 6),
			Level.CMD_Wait_Seconds.new(2),
		], -1)),
	]

	if shuffle:
		cmds_phases.shuffle();

	while less_amount > 0:
		cmds_phases.pop_back();
		less_amount -= 1;

	return Level.CMD_Sequence.new(cmds_phases, repeats);

func _cmd_shoot_constant(level:Level, when_percentage_begins:float = 0.5)->Level.CMD:
	var possiblePatterns:Array[Array] = [
		[1,1,1,1,1,0,0,0,0],
		[1,1,1,1,1,0,0,0,0],
		[1,1,1,1,1,0,0,0,0],
		[1,1,1,1,1,0,0,0,0],

		[1,1,1,1,1,1,0,0,0],
		[1,1,1,1,1,1,0,0,0],

		[0,0,0,1,1,1,0,0,0],
		[0,0,0,1,1,1,0,0,0],

		[1,1,1,1,0,0,0,1,1],
		[1,1,1,0,0,0,1,1,1]
	]

	var used_patterns:Array = [];
	var distance_between_shots:float = 0.45;
	var shots_to_leave_screen:int = 5;

	var tag:String = "boss";
	var timeCount:Array = [0, 0];
	var invertedBool:Array[bool] = [false];

	var cmd_shoot = func(shotLine):
		return Level.CMD_Callable.new(func():

			)


	return Level.CMD_Sequence.new([
		Level.CMD_Callable.new(func():
			ProjEnemyBasic_Global.get_data(tag).can_leave_screen = true;
			ProjEnemyBasic_Global.get_data(tag).speed_multiplier = 0.5;

			set_vulnerable(true);
			),
		Level.CMD_Parallel.new([
			Level.CMD_Process.new(func shot_line_process(delta:float):
					var wasBelowZero:bool = timeCount[0] < 0;
					timeCount[0] += delta * ProjEnemyBasic_Global.get_data(tag).speed_multiplier;
					var isBelowZero:bool = timeCount[0] < 0;
					if timeCount[0] > distance_between_shots or (wasBelowZero and not isBelowZero):
						timeCount[0] -= distance_between_shots;
						invertedBool[0] = not invertedBool[0];
						_pick_shot_line(possiblePatterns.pick_random(), invertedBool[0], true,
								shots_to_leave_screen, distance_between_shots, used_patterns);
					if timeCount[0] < -distance_between_shots or (not wasBelowZero and isBelowZero):
						timeCount[0] += distance_between_shots;
						invertedBool[0] = not invertedBool[0];
						_pick_shot_line(possiblePatterns.pick_random(), invertedBool[0], false,
								shots_to_leave_screen, distance_between_shots, used_patterns);

					ProjEnemyBasic_Global.get_data(tag).speed_multiplier = cos(timeCount[1] * 0.25) * 0.5;

					return false;
					),
			Level.CMD_Sequence.new([
				Level.CMD_Parallel.new([
					Level.CMD_Wait_Callable.new(_has_touches_in_place),
					Level.CMD_Sequence.new([
						Level.CMD_Wait_Seconds.new(0.25),
						#cmd_laser(level, hand_l if randf() > 0.5 else hand_r),
					], -1)
				]),
				Level.CMD_Parallel.new([
					Level.CMD_Wait_Callable.new(func():
						return not _has_touches_in_place();
						),
					cmd_laser_constant(hand_l, func(delta:float):
						return hand_l.center_position.global_position + Vector3.BACK * 10 - Vector3(randf(),0 ,randf()) * 0.15 + Vector3(sin(timeCount[1]), 0, cos(timeCount[1])) * 0.75;
						),
					cmd_laser_constant(hand_r, func(delta:float):
						return hand_r.center_position.global_position + Vector3.BACK * 10 + Vector3(randf(),0 ,randf()) * 0.15 + Vector3(cos(timeCount[1]), 0, sin(timeCount[1])) * 0.75;
						),
					Level.CMD_Process.new(func (delta:float):
						timeCount[1] += delta;
						),
					Level.CMD_Sequence.new([
						Level.CMD_Parallel.new([
							Level.CMD_Wait_Seconds.new(4.5),
							Level.CMD_Process.new(func(delta:float):
								ProjEnemyBasic_Global.get_data(tag).speed_multiplier = 0.41;
								),
						]),
						Level.CMD_Callable.new(func():
							var value = ProjEnemyBasic_Global.get_data(tag).speed_multiplier;
							timeCount[1] = acos(fmod(value / 0.5, 1)) / 0.25;
							),
						Level.CMD_Parallel.new([
							Level.CMD_Wait_Callable.new(func(): return health.get_health_percentage() < when_percentage_begins * 0.5),
							Level.CMD_Process.new(func(delta:float):
								ProjEnemyBasic_Global.get_data(tag).speed_multiplier = cos(timeCount[1] * 0.25) * 0.5;
								),
						]),
						Level.CMD_Callable.new(func():
							var value = ProjEnemyBasic_Global.get_data(tag).speed_multiplier;
							timeCount[1] = acos(fmod(value / 0.6, 1)) / 0.3;
							),
						Level.CMD_Parallel.new([
							#Level.CMD_Wait_Callable.new(func(): return health.get_health_percentage() < when_percentage_begins * 0.25),
							Level.CMD_Process.new(func(delta:float):
								ProjEnemyBasic_Global.get_data(tag).speed_multiplier = cos(timeCount[1] * 0.3) * 0.6;
								),
						]),
					], -1)
				]),
				Level.CMD_Sequence.new([
					cmd_stop_laser_constant(hand_l),
					cmd_stop_laser_constant(hand_r),
					Level.CMD_Callable.new(func():
						ProjEnemyBasic_Global.get_data(tag).speed_multiplier = 0.4;
						timeCount[1] = 0;
						),
				])
			],-1),
		])
	]);

func _has_touches_in_place()->bool:
	return Player.instance.currentTouches.size() > 0;

func _pick_shot_line(pattern:Array, inverted:bool, going_forward:bool, shots_to_leave_screen:int, distance_between_shots:float, used_patterns:Array):
	var eliminated:Node3D = null;
	if going_forward:
		used_patterns.push_back(_spawn_shot_line(pattern, inverted, Vector3.UP * 0.5));
		while used_patterns.size() > shots_to_leave_screen:
			eliminated = used_patterns.pop_front();
			eliminated.queue_free();
	else:
		used_patterns.push_front(_spawn_shot_line(pattern, inverted, Vector3.UP * 0.5 + Vector3.BACK * 8 * shots_to_leave_screen * distance_between_shots));
		while used_patterns.size() > shots_to_leave_screen:
			eliminated = used_patterns.pop_back();
			eliminated.queue_free();


func _spawn_shot_line(shotLine:Array, inverted:bool, offset:Vector3)->Node3D:
	pirulito_graphic.sfx_shot_middle.post_event();
	var parent:Node3D = Node3D.new();
	self.add_child(parent);
	var comparative:int = 1 if inverted else 0;
	for shotIndex:int in range(shotLine.size()):
		if shotLine[shotIndex] != comparative:
			var shot = shoot(PROJ_ENEMY_BASIC_GLOBAL, global_shot_origin, Vector3.BACK, shotIndex * 0.5 * Vector3.RIGHT, func(shot:ProjEnemyBasic_Global): shot.tag = "boss");
			var pos:Vector3 = shot.global_position;
			shot.get_parent().remove_child(shot);
			parent.add_child(shot);
			shot.global_position = pos + offset;
	return parent;

func _instantiate_matrix(level:Level, what:Array, matrix:Array, offset_grid_x:float, offset_grid_z:float):
	for y:int in range(matrix.size()):
		for x:int in range(matrix[y].size()):
			var index:int = matrix[y][x];
			if index > 0:
				var pizza = level.objs.create_object(what[index - 1], crowd_group, self.global_position + level.stage.get_grid_distance(offset_grid_x + x, offset_grid_z + y * 1.2));
				if pizza is Boss_Pirulito_Pizza:
					var bPizza = pizza as Boss_Pirulito_Pizza;
					if offset_grid_x < 0:
						bPizza.come_from_left();
					else:
						bPizza.come_from_right();

func _make_pizzas_show(level:Level, matrix_left:Array, matrix_right:Array, distance:float):
	_instantiate_matrix(level, [ENEMY_BOSS_PIRULITO_PIZZA], matrix_left, -1 + distance, 4);
	_instantiate_matrix(level, [ENEMY_BOSS_PIRULITO_PIZZA], matrix_right, -1 - distance, 4);

func cmd_make_pizzas_and_wait(level:Level, pizza_l:Array, pizza_r:Array, distance:float, cmd_while:Level.CMD):
	return Level.CMD_Sequence.new([
		Level.CMD_Callable.new(_make_pizzas_show.bind(level, pizza_l, pizza_r, distance)),
		Level.CMD_Wait_Seconds.new(0.8),
		Level.CMD_Parallel.new([
			level.objs.cmd_wait_group(crowd_group),
			cmd_while,
			Level.CMD_Sequence.new([
				Level.CMD_Wait_Seconds.new(0.65),
				Level.CMD_Callable.new(func(): set_vulnerable(false)),
			])
		], 2),
		cmd_vulnerable(level),
	])

func cmd_vulnerable(level:Level, seconds:float = 3, make_invulnerable_again:bool = false)->Level.CMD:
	var args:Array[Level.CMD] = [
		Level.CMD_Callable.new(func(): set_vulnerable(true)),
		Level.CMD_Wait_Seconds.new(seconds),
	]
	if make_invulnerable_again:
		args.push_back(Level.CMD_Callable.new(func(): set_vulnerable(false)))

	var vulnerability:Level.CMD = Level.CMD_Sequence.new(args);
	var if_less_life_then_copters:Level.CMD = Level.CMD_Branch.new(
		func(): return health.get_health_percentage() < 1.0,
		cmd_copters(level, 0),
		Level.CMD_Nop.new())
	return Level.CMD_Parallel_Complete.new([vulnerability, if_less_life_then_copters])

func cmd_copters(level:Level, repeats:int = 0)->Level.CMD:
	return Level.CMD_Sequence.new([
				Level.CMD_Wait_Seconds.new(0.15),
				Level.CMD_Sequence.new([
					Level.CMD_Callable.new(func():
						var line:ChildLine3D = copter_lines.pick_random();
						var index:int = 2;
						while index > 0:
							var copter:AI_Roboto_Copter = level.objs.create_object(ENEMY_ROBOTO_COPTER);
							copter.set_line(line);
							copter.linePos = -index * 1;
							copter.velocityLine *= 0.5;
							index -= 1;
						),
					Level.CMD_Wait_Seconds.new(2),
				], repeats)
			])


func cmd_laser(level:Level, hand:Boss_Pirulito_Lamp, negative_flight:bool)->Level.CMD:
	return Level.CMD_Sequence.new([
		Level.CMD_Callable.new(func():
			hand.set_flight(true, negative_flight);
			hand.use_laser();
			),
		Level.CMD_Process.new(func(delta:float):
			hand.point_laser_to(Player.get_closest_position(hand.global_position, true))
			return not hand.is_using_laser();
			),
	])

func cmd_laser_constant(hand:Boss_Pirulito_Lamp, funcAimWhereVector3WithDelta:Callable)->Level.CMD:
	return Level.CMD_Sequence.new([
		Level.CMD_Wait_Callable.new(func(): return not hand.is_using_laser()),
		Level.CMD_Callable.new(func(): hand.start_laser_constant()),
		Level.CMD_Process.new(func(delta:float):
			hand.point_laser_to(funcAimWhereVector3WithDelta.call(delta));
			return not hand.is_using_laser();
			),
	])

func cmd_stop_laser_constant(hand:Boss_Pirulito_Lamp)->Level.CMD:
	return Level.CMD_Callable.new(func(): hand.stop_laser_constant());

func set_vulnerable(vulnerable:bool):
	var anim:String;
	##Base anim
	match phase:
		Phase.Phase_Intro:
			anim = pirulito_graphic.nando_e_nene.animation_intro_idle;
		Phase.Phase_1:
			anim = pirulito_graphic.nando_e_nene.animation_1_open_idle;
		Phase.Phase_2:
			anim = pirulito_graphic.nando_e_nene.animation_2_idle;
	if anim and not anim.is_empty():
		if vulnerable:
			pirulito_graphic.nando_e_nene.add_stack(anim);
		else:
			pirulito_graphic.nando_e_nene.erase_stack(anim);

	##Talking
	match phase:
		Phase.Phase_1:
			if vulnerable:
				start_talk(dialogue_1_open, true);
			else:
				start_talk(dialogue_1_idle, true);

	boss_hand_eva_shield.set_on(!vulnerable);
	pirulito_graphic.set_vulnerable(vulnerable);
	HUD.instance.make_screen_effect(HUD.ScreenEffect.ShortFlash);
	#health.invulnerable = not vulnerable;

func is_vulnerable()->bool:
	return not health.invulnerable;

func cmd_shotgun(level:Level, origin:Node3D, sfx_origin:AkEvent3D, shotgun_angles:Array[float], direction:Vector3 = Vector3.BACK)->Level.CMD:
	return Level.CMD_Callable.new(func():
		sfx_origin.post_event();
		shoot_multiple_angles(origin, shotgun_angles, direction)
		)

func cmd_shotgun_in_player_direction(level:Level, origin:Node3D, sfx_origin:AkEvent3D, shotgun_angles:Array[float])->Level.CMD:
	return Level.CMD_Callable.new(func():
		sfx_origin.post_event();
		shoot_multiple_angles(origin, shotgun_angles, Player.get_closest_direction(origin.global_position, true))
		)

func shoot_multiple_angles(origin:Node3D, angles:Array[float], direction:Vector3 = Vector3.BACK, funcShot:Callable = Callable()):
	for angle:float in angles:
		if angle != 0:
			shoot_angle(origin, -angle, direction, funcShot);
		shoot_angle(origin, angle, direction, funcShot);

func cmd_machine_gun(level:Level, shots:int, time_between_shots:float, angle_opening:float, shots_in_line:int, hole_index:int, hole_size:int)->Level.CMD:
	var cmds:Array[Level.CMD] = [];
	var max_angle:float = angle_opening * 0.5;
	var min_angle:float = -max_angle;
	var angle_interval:float = angle_opening / shots_in_line;
	var actualShots:int = 0;
	var shotsBetweenHoles:int = 0;

	var time := {
		mark = Time.get_ticks_usec()
	}
	cmds.append(Level.CMD_Callable.new(func():
			pirulito_graphic.set_open_sound_central(true);
			time.mark = Time.get_ticks_usec();
			));
	var i:int = 0;
	while shots >= 0:
		var shotIndex:int = i % (shots_in_line * 2); ## forwards then backwards;
		var angleNow:float = min_angle + angle_interval * pingpong(shotIndex, shots_in_line);

		cmds.append(Level.CMD_Callable.new(shoot_angle.bind(pirulito_graphic.get_middle_shot_origin(), angleNow, Vector3.BACK,
				func(shot:ProjEnemyBasic):
					shot.speedMultiplier = 0.48 + 0.008 * shotsBetweenHoles;
					shot.accelerate_to_been_born_in(time.mark + 1000000 * i * time_between_shots)
					)));
		cmds.append(Level.CMD_Wait_Seconds.new(time_between_shots));
		i += 1;
		actualShots += 1;
		shotsBetweenHoles += 1;
		shots -= 1;
		if hole_index != 0 and (actualShots % hole_index) == 0:
			cmds.append(Level.CMD_Wait_Seconds.new(time_between_shots * hole_size));
			i += hole_size;
			shots -= hole_size;
			shotsBetweenHoles = 0;
	return Level.CMD_Sequence.new(cmds);

func shoot_angle(origin:Node3D, angle:float, direction:Vector3 = Vector3.BACK, funcShot:Callable = Callable())->Node3D:
	return shoot(PROJ_ENEMY_BASIC, origin, direction.rotated(Vector3.UP, deg_to_rad(angle)), Vector3.ZERO, funcShot);

func shoot(shotScene:PackedScene, origin:Node3D, shot_direction:Vector3, offsetPosition:Vector3, funcShot:Callable = Callable())->Node3D:
	var shot:Node3D = InstantiateUtils.InstantiateInTree(shotScene, origin);
	var z := shot_direction.normalized();
	var y := Vector3.UP;
	var x := z.cross(y);
	shot.global_basis = Basis(x, y, z)
	shot.global_position += offsetPosition;
	if funcShot:
		funcShot.call(shot);
	return shot;

func _on_health_dead(health):
	phase = Phase.Phase_Losing;
	pass;

func cmd_talk_loop(id:StringName, voice_nene:bool = false)->Level.CMD:
	return Level.CMD_Sequence.new([
		Level.CMD_Callable.new(func():
			start_talk(id, true, voice_nene);
			),
	]);

func cmd_talk(id:StringName, voice_nene:bool = false)->Level.CMD:
	return Level.CMD_Sequence.new([
		Level.CMD_Callable.new(func():
			start_talk(id, false, voice_nene);
			),
		Level.CMD_Wait_Signal.new(_bubble_speaker.bubble_finished),
	]);

func start_talk(id:StringName, loop:bool, voice_nene:bool = false):
	if voice_nene:
		_bubble_speaker.voice = TextFlowBubbleSpeaker.SpeakerVoice.Nene
	else:
		_bubble_speaker.voice = TextFlowBubbleSpeaker.SpeakerVoice.Nando
	_flow_player.start_flow(id, loop);

func stop_talk():
	_flow_player.kill_flow();

func _animate_talk():
	match phase:
		Phase.Phase_Intro:
			sprite.add_stack(sprite.animation_intro_speak);
		Phase.Phase_1:
			if is_vulnerable():
				sprite.add_stack(sprite.animation_1_open_speak);

func _animate_stop_talk():
	sprite.erase_stack(sprite.animation_intro_speak);
	sprite.erase_stack(sprite.animation_1_open_speak);

func _on_health_hit(damage:Health.DamageData , health: Health) -> void:
	pirulito_graphic.feedback_get_shot(damage.origin);
	match phase:
		Phase.Phase_Intro:
			sprite.play(sprite.animation_1_open_hurt);
			#stop_talk();
		Phase.Phase_1:
			sprite.play(sprite.animation_1_open_hurt);
			#stop_talk();
		Phase.Phase_2:
			sprite.play(sprite.animation_2_hurt);
