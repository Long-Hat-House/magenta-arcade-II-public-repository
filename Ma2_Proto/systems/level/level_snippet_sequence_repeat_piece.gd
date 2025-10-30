class_name Level_Snippet_Sequence_RepeatPiece extends Level_Snippet_Sequence

@export var piece:LevelStagePiece;
@export var piece_scene:PackedScene;
@export var time_to_camera_to_go:float = 1;
@export var time_to_wait_before_wave:float = 0;

var used_main_piece:bool = false;

func make_piece(lvl:Level)->LevelStagePiece:
	if piece_scene: 
		return lvl.stage.create_piece_and_attach(piece_scene);
	elif piece:
		if not used_main_piece: 
			used_main_piece = true;
			lvl.stage.attach_piece(piece);
			return piece;
		else:
			var p = piece.duplicate();
			lvl.stage.attach_piece(p);
			return p;
	return null;

func cmd_after(lvl:Level)->Level.CMD:
	return lvl.cmd_clear_measures();

func cmd(lvl:Level)->Level.CMD:
	var measures = {
		arr = [],
	};
	var final_commands:Array[Level.CMD] = [
		Level.CMD_Callable.new(func():
			measures.arr = lvl.get_measures();
			
			lvl.current_measure_index = -1;
			
			var i:int = 0;
			while i < get_snippets_count():
				make_piece(lvl);
				i += 1;
			),
		Level.CMD_Callable.new(func():
			print("[PIECE] lets check the pieces!");
			for measure in get_tree().get_nodes_in_group("measure"):
				print("%s -> %s" % [measure, measure.global_position]);
			)
		];
	var commands = get_commands(lvl);
	for index_command in range(commands.size()):
		final_commands.push_back(Level.CMD_Sequence.new([
			Level.CMD_Callable.new(func():
				lvl.stage.set_pivot_offset_to_exactly_node(measures.arr[index_command]);
				),
			lvl.cmd_camera_go_to_pivot0(time_to_camera_to_go, false),
			Level.CMD_Wait_Seconds.new(time_to_wait_before_wave),
			commands[index_command],
		]))
	final_commands.push_back(lvl.cmd_clear_measures());
	return Level.CMD_Sequence.new(final_commands);
