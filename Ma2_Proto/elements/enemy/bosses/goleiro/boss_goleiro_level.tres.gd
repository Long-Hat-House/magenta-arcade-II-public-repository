extends Level

const BOSS_2 = preload("res://systems/boss/boss_2.tres")

const BOSS_GOLEIRO_BALL = preload("res://elements/enemy/bosses/goleiro/boss_goleiro_ball.tscn")
## enemies
const ENEMY_PIZZA_ROBOTO = preload("res://elements/enemy/pizza/enemy_pizza_roboto.tscn")
const ENEMY_PIZZA_ROBOTO_SHOOTER = preload("res://elements/enemy/pizza/enemy_pizza_roboto_shooter.tscn")
const ENEMY_JACARE = preload("res://elements/enemy/roboto_jacare/enemy_jacare.tscn")



var group:String = "main";

@export var boss: Boss_Goleiro;
@export var boss_occlusion_material:StandardMaterial3D;

@export var piece:LevelStagePiece;
@export var campo:Node3D;
@export var ball:Boss_Goleiro_Ball;
var ball_camera_offset = Vector3.BACK * 20;
@export var camera_border:Vector2 = Vector2(6,5);
@export var camera_border_offset:Vector2 = Vector2(0,-1);
@export var camera_speed:Vector2 = Vector2(3, 2.65)
@onready var ball_origin: Marker3D = %"Ball Origin"
@export var sfx_reveal: AkEvent3D;


var cam_targets:Array[Node3D] = []
var curr_dist:Vector3;
enum FieldSide
{
	BOSS,
	ALLY
}

var last_win:FieldSide = FieldSide.ALLY;

func cam_boss_position_process(delta:float)->Vector3:
	var dist:Vector3 = cam_get_free_vector();
	dist.x = signf(dist.x) * minf(absf(dist.x + camera_border_offset.x), camera_border.x);
	dist.z = signf(dist.z) * minf(absf(dist.z + camera_border_offset.y), camera_border.y);
	var distance_length:float = (curr_dist - dist).length();
	var distance_length_multiplier = distance_length * delta;
	curr_dist.x = move_toward(curr_dist.x, dist.x, distance_length_multiplier * camera_speed.x);
	curr_dist.z = move_toward(curr_dist.z, dist.z, distance_length_multiplier * camera_speed.y);
	return curr_dist;

func cam_get_free_vector()->Vector3:
	var dist:Vector3 = Vector3.ZERO;
	var count:int = 0;
	for thing in cam_targets:
		dist += thing.global_position - (campo.global_position + ball_camera_offset)
		count += 1;
	if count > 0:
		dist /= count;
	return dist;

@onready var hand_attacks_easy:Array = [
	boss.right_hand_attack,
	boss.left_hand_attack,
	boss.right_hand_machine_gun.bind(8, 0.25),
	boss.left_hand_machine_gun.bind(8, 0.25),
]

@onready var hand_attacks_hard:Array = [
	boss.right_hand_attack,
	boss.left_hand_attack,
	boss.right_hand_machine_gun.bind(4, 0.5),
	boss.left_hand_machine_gun.bind(4, 0.5),
	boss.right_hand_machine_gun.bind(12, 0.1),
	boss.left_hand_machine_gun.bind(12, 0.1),
]

var all_hand_attacks:Array;
var current_hand_attack:int;

func _ready():
	await await_for_level_ready()

	hand_attacks_easy.shuffle();
	hand_attacks_hard.shuffle();
	all_hand_attacks = hand_attacks_easy + hand_attacks_hard;

	current_measure_index = 0;
	stage.attach_piece(piece);
	stage.repivot();

	boss_occlusion_material.albedo_color = MA2Colors.BLACK;


	cmd_array([
		CMD_Sequence.new([
			CMD_Callable.new(func():
				cam.tween_position_vector(get_current_measure().global_position, 4, Tween.TRANS_SINE, Tween.EASE_IN);
				print("[BOSS] checking it on %s -> %s (%s)" % [current_measure_index, get_current_measure(), get_current_measure().global_position]);
				),
			CMD_Parallel.new([
				CMD_Wait_Seconds.new(4.1),
				CMD_Sequence.new([
					CMD_Wait_Callable.new(func wait_press_r():
						return Input.is_key_pressed(KEY_S),
						),
					CMD_Callable.new(func instantly_get_there():
						cam.stop_all_camera_movement();
						cam.tween_position_vector(get_current_measure().global_position, 0.1, Tween.TRANS_SINE, Tween.EASE_IN);
						),
				])
			]),
			CMD_Wait_Seconds.new(0.25),
			boss.cmd_speak_wait(boss.speech_intro_before),
			CMD_Callable.new(func():
				walk_measure();
				cam.tween_position_vector(get_current_measure().global_position, 2.5, Tween.TRANS_QUART, Tween.EASE_IN);
				HUD.instance.make_screen_effect(HUD.ScreenEffect.LongFlash);
				sfx_reveal.post_event();
				var t := create_tween();
				t.tween_property(boss_occlusion_material, "albedo_color", Color(0.15, 0.15, 0, 0), 0.15);
				),
			CMD_Level_Environment.new("boss"),
			boss.cmd_speak_wait(boss.speech_intro),
			CMD_Wait_Seconds.new(1.5),
			]),
		boss_cmd(),
		CMD_Wait_Seconds.new(1),
		CMD_Callable.new(func():
			clear_measures();
			),
		])
		#objs.cmd_wait_group(group)


func boss_cmd()->Level.CMD:
	return Level.CMD_Sequence.new([
		Level.CMD_Callable.new(func boss_opening():
			HUD.instance.show_boss_life(BOSS_2, func():
				return boss.health.get_health_percentage();
				)
			ball_camera_offset = ball_origin.global_position - campo.global_position;
			boss.set_target(ball);
			boss.show_high_contrast();
			cam.add_dynamic_positioner(self.cam_boss_position_process);
			),
		Level.CMD_Parallel.new([ ## While boss is alive
			Level.CMD_Wait_Callable.new(func check_boss_alive():
				return not boss.health.is_alive();
				),
			Level.CMD_Sequence.new([
				Level.CMD_Wait_Seconds.new(1),
				Level.CMD_Sequence.new([
					cmd_wait_ball_or_time(1.0),
					cmd_launch_ball(),
				], -1)
			]),
			Level.CMD_Sequence.new([
				Level.CMD_Wait_Callable.new(func check_boss_hard_mode():
					return boss.health.get_health_percentage() <= 0.9;
					),
				Level.CMD_Wait_Seconds.new(1),
				Level.CMD_Parallel.new([
					Level.CMD_Sequence.new([
						Level.CMD_Wait_Seconds_Dynamic.new(func(): return randf_range(1.5 + boss.health.get_health_percentage() * 2, 2.0 + boss.health.get_health_percentage() * 3.0)),
						cmd_boss_shoot_hand(),
					], -1),
				]),
				Level.CMD_Wait_Forever.new(),
			])
		]),
		# BOSS DEATH
		CMD_Callable.new(func boss_death():
			HUD.instance.show_boss_death()
			cam_targets.clear();
			cam_targets.push_back(boss.body);
			),
		CMD_Await_AsyncCallable.new(boss.die, boss),
	]);

func cmd_boss_shoot()->CMD:
	return CMD_Callable.new(func boss_shoot():
		boss.shoot();
		)


func cmd_boss_shoot_hand()->CMD:
	return CMD_Callable.new(func boss_shoot_hand():
		all_hand_attacks[self.current_hand_attack % all_hand_attacks.size()].call();
		self.current_hand_attack += 1;
		)

var _vulnerable_index:int = 0;

func cmd_wait_ball_or_time(time:float, if_waited_cmd:CMD = CMD.Nop())->CMD:
	return Level.CMD_Parallel.new([
		Level.CMD_Sequence.new([
			Level.CMD_Wait_Seconds.new(1.25),
			if_waited_cmd
		]),
		Level.CMD_Wait_Callable.new(func wait_until_ball_active():
			return ball.active;
			),
		])

func cmd_launch_ball()->Level.CMD:
	return Level.CMD_Sequence.new([
		Level.CMD_Callable.new(func start_ball():
			boss.set_target(null);
			ball.stop();
			),
		cmd_wait_ball_or_time(1.25, Level.CMD_Callable.new(func set_field_side_ally():
			ball.start(self.last_win == FieldSide.ALLY)
			)),
		Level.CMD_Callable.new(func start_following_boss():
			boss.set_target(ball);
			boss.speak(boss.speech_idle, true);
			cam_targets.push_back(ball);
			),
		Level.CMD_Parallel.new([
			## --- GOL DOS AMIGOS ---
			Level.CMD_Sequence.new([
				Level.CMD_Wait_Signal.new(ball.goal_allied),
				Level.CMD_Print_Log.new("gol de você!", "cyan"),
				Level.CMD_Callable.new(func goal_allied_happened():
					self.last_win = FieldSide.ALLY;
					boss.speak(boss.speech_goal_player);

					_vulnerable_index += 1;
					var my_index:int = _vulnerable_index;
					cam_targets.push_back(boss.body);
					await get_tree().create_timer(5).timeout;
					if is_instance_valid(boss) and _vulnerable_index == my_index:
						boss.set_vulnerable(false);
					),
				cmd_wait_ball_or_time(3.0),
				Level.CMD_Callable.new(func stop_following_boss():
					cam_targets.erase(boss.body);
					)
			]),

			## --- GOL DOS INIMIGOS ---
			Level.CMD_Sequence.new([
				Level.CMD_Wait_Signal.new(ball.goal_enemy),
				CMD_Callable.new(func goal_enemy_happened():
					boss.speak(boss.speech_goal_enemy);
					self.last_win = FieldSide.BOSS;
					),
				Level.CMD_Print_Log.new("gol do inimigo!", "magenta"),
				cmd_call_enemy(),
			])
		]),
		Level.CMD_Callable.new(func end_ball():
			boss.set_target(null);
			ball.stop();
			cam_targets.erase(ball);
			cam_targets.erase(boss.body);
			),
	])

var possible_enemies = [
	{
		group = "pizza_1",
		enemies = [
			{
				which = ENEMY_PIZZA_ROBOTO_SHOOTER,
				where_x = -1,
				where_z = 3,
			},
			{
				which = ENEMY_PIZZA_ROBOTO_SHOOTER,
				where_x = 1,
				where_z = 3,
			},
		]
	},
	{
		group = "pizza_2",
		enemies = [
			{
				which = ENEMY_PIZZA_ROBOTO_SHOOTER,
				where_x = -4,
				where_z = 3,
			},
			{
				which = ENEMY_PIZZA_ROBOTO_SHOOTER,
				where_x = 4,
				where_z = 3,
			},
		]
	},
	{
		group = "pizza_left",
		enemies = [
			{
				which = ENEMY_PIZZA_ROBOTO_SHOOTER,
				where_x = -7,
				where_z = 3,
			},
			{
				which = ENEMY_PIZZA_ROBOTO_SHOOTER,
				where_x = -9,
				where_z = 3,
			},
		]
	},
	{
		group = "pizza_right",
		enemies = [
			{
				which = ENEMY_PIZZA_ROBOTO_SHOOTER,
				where_x = 7,
				where_z = 3,
			},
			{
				which = ENEMY_PIZZA_ROBOTO_SHOOTER,
				where_x = 9,
				where_z = 3,
			},
		]
	},
	{
		group = "jac_right",
		enemies = [
			{
			which = ENEMY_JACARE,
			where_x = 2.5,
			where_z = 2,
			},
		]
	},
	{
		group = "jac_left",
		enemies = [
			{
			which = ENEMY_JACARE,
			where_x = -2.5,
			where_z = 2,
			},
		]
	},
]
var shuffled:bool = false;
var index_now:int = 0;
func cmd_call_enemy()->Level.CMD:
	if not shuffled:
		seed(Player.instance.get_seed_based_on_equipped_items());
		possible_enemies.shuffle();
	return CMD_Sequence.new([
		CMD_Branch.new(func are_there_no_enemies_in_this_index():
			self.index_now = (index_now + 1) % possible_enemies.size();
			return objs.get_group_elements_count(possible_enemies[index_now].group) <= 0;
			,
		CMD_Callable.new(func create_enemies():
			var now = possible_enemies[index_now];
			for enemy in now.enemies:
				var obj = objs.create_object(enemy.which, now.group, stage.get_grid(enemy.where_x, enemy.where_z + 12));
				var wd := obj as AI_WalkAndDo;
				if wd:
					wd.distanceMax = 4;
					wd.walkAndStop = true;
					wd.process_mode = Node.PROCESS_MODE_DISABLED;
					var t := get_tree().create_tween();
					print("[boss] created enemy %s" % wd);
					TransformUtils.tween_fall(wd, t);
					t.tween_callback(func():
						if is_instance_valid(wd):
							print("[boss] enemy fell %s" % wd);
							wd.process_mode = Node.PROCESS_MODE_INHERIT;
						)
			),
		cmd_boss_shoot_hand()),
	])
