extends Level_Snippet_Node

@export var altar_scene:PackedScene;
@export var button_scene:PackedScene;
@export var wait_after_send_all:float = 4;
@export var open_times:Array[float] = [
	0
]
## The amount of positions possible. The amount is double that, limited by the amount_first_part/second_part.
@export var positions_x_positive:Array[float] = [
	2, 4.5
]

@export var amount_first_part:int = 4;
@export var amount_second_part:int = 4;

@export var copter_ok:PackedScene;
@export var copters1:Array[int];
@export var copters2:Array[int];
@export var copters_pos1:Vector2 = Vector2(-7.5, 10);
@export var copters_pos2:Vector2;
@export var copter_delay:float = 6;
@export var copters12_delay:float = 2;
@export var copters_line1:Array[float];
@export var copters_line2:Array[float];

var altars:Array[AltarTweenable]

func make_altar()->AltarTweenable:
	var altar:AltarTweenable = altar_scene.instantiate();
	InstantiateUtils.get_topmost_instantiate_node().add_child(altar);
	altar.carry(button_scene.instantiate())
	altars.push_back(altar);
	return altar;
	
func make_pos(target:Array[float], positive:Array[float], negative:Array[float], amount:int):
	positive.shuffle();
	negative.shuffle();
	target.clear();
	for i in range(positive.size()):
		target.append(positive[i]);
		target.append(-negative[i]);
	if target.size() > amount:
		target.resize(amount);

func _cmd(level:Level)->Level.CMD:
	var positions_x_negative:Array[float] = positions_x_positive.duplicate(true);
	
	var cam := level.cam;
	var stage := level.stage;
	
	var do_positions = func do_positions(pos:Array[float]):
		while open_times.size() < pos.size():
			open_times.append(randf_range(0.25, 1.0));
		open_times.shuffle();
		
		for index in range(pos.size()):
			var altar := make_altar();
			altar.position = cam.get_pos() + Vector3(pos[index], 0, 35);
			altar.queue_free_on_out_of_screen = true;
			altar.keep_moving(Vector3.FORWARD, randf_range(7, 12), randf_range(25,40), Tween.TRANS_SINE, Tween.EASE_OUT_IN);
			if open_times[index] > 0:
				altar.open(open_times[index])
			await get_tree().create_timer(randf_range(0.5, 3.5)).timeout;
	return Level.CMD_Parallel.new([
		Level.CMD_Sequence.new([
			Level.CMD_Wait_Seconds.new(copter_delay),
			Level.CMD_Parallel_Complete.new([
					AI_Roboto_Copter.cmd_make_copters_quick(level, [copter_ok], copters1, func(): return stage.get_grid(copters_pos1.x, copters_pos1.y), Vector3.RIGHT, copters_line1, "copter"),
					Level.CMD_Sequence.new([
						Level.CMD_Wait_Seconds.new(copters12_delay),
					AI_Roboto_Copter.cmd_make_copters_quick(level, [copter_ok], copters2, func(): return stage.get_grid(copters_pos2.x, copters_pos2.y), Vector3.LEFT, copters_line2, "copter"),
					]),
					Level.CMD_Wait_Forever.new(),
				]),
			]),
		Level.CMD_Await_AsyncCallable.new(func():
			var positions_x:Array[float];
			
			make_pos(positions_x, positions_x_positive, positions_x_negative, amount_first_part);
			await do_positions.call(positions_x);
			
			cam.tween_position(stage.get_grid(0, -5).z, 2);
			
			make_pos(positions_x, positions_x_positive, positions_x_negative, amount_second_part);
			await do_positions.call(positions_x);
			if is_inside_tree():
				await get_tree().create_timer(wait_after_send_all).timeout;
			for altar:AltarTweenable in altars:
				if is_instance_valid(altar):
					altar.destroy();
			
			, self)
	])
			
