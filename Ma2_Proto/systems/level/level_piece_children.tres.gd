extends Level

@export var level_snippet: Level_Snippet_Node;

var group:String = "main";

func _ready():
	await await_for_level_ready()
	for child in get_children():
		if child is LevelStagePiece:
			self.stage.attach_piece(child);

	cmd_array([
		level_snippet.cmd(self),
		cmd_clear_measures(),
		]);

func _get_configuration_warnings() -> PackedStringArray:
	for child in get_children():
		if child is LevelStagePiece:
			return [];
	return ["Need a level stage piece as child of this!"];
