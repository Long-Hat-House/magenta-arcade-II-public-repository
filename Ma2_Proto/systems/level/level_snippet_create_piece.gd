class_name Level_Snippet_ChangeDirection_AttachPiece extends Level_Snippet_Node

@export var piece:LevelStagePiece;
@export var direction:LevelStagePiece.AttachmentDirection;

func get_piece()->LevelStagePiece:
	if piece == null:
		for child in get_children():
			if child is LevelStagePiece:
				piece = child;
				break;
	return piece;

func _cmd(level:Level)->Level.CMD:
	return Level.CMD_Callable.new(func change_direction_attach_piece():
		level.stage.set_attachment_direction(direction);
		var piece := get_piece();
		if piece != null:
			level.stage.attach_piece(piece);
		)
