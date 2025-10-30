extends Level

## game elements
const ENEMY_BOSS_PIRULITO = preload("res://elements/enemy/bosses/pirulito/enemy_boss_pirulito.tscn")

## stage pieces
const STAGE_PIECE_AFONSO_PENA_P_7 = preload("res://elements/stage_pieces/stage_piece_afonso_pena_p7.tscn")

## dialogue player
const TEXT_FLOW_PLAYER_BUBBLES = preload("res://modules/text_flow/scenes/text_flow_player_bubbles.tscn")
var dialogue_flow_challenge:TextFlowPlayerBubbles

@export var _wait_group:String = "WaitGroup"
@export var going_to_lollypop_waves:Array[LevelWave] = [];

func _ready():
	await await_for_level_ready()

	scene_6_boss();

func scene_6_boss():
	var boss:Array[Boss_Pirulito] = []
	cmd_array([
		CMD_Music_Event.new(AK.EVENTS.MUSIC_LEVEL2_GAMEPLAY_END),
		CMD_Callable.new(func boss_call():
			stage.create_piece_and_attach(STAGE_PIECE_AFONSO_PENA_P_7);
			stage.set_pivot_offset(Vector3.ZERO);
			stage.repivot();

			boss.append(objs.create_object(ENEMY_BOSS_PIRULITO, _wait_group, stage.get_grid(0, 12)) as Boss_Pirulito);

			cmd(cam.cmd_position_vector(stage.get_grid(0,2), 3));
			),
		CMD_Wait_Seconds.new(3),
		CMD_Callable.new(func():
			cmd(boss[0].cmd_boss(self));
			),
	], false)
