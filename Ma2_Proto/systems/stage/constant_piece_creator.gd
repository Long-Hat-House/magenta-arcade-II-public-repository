class_name ConstantPieceCreator extends Node3D

@export var direction:LevelStagePiece.AttachmentDirection;
@export var pieces:Array[PackedScene];

@export var marker_forward:Marker3D;
@export var marker_back:Marker3D;
@export var marker_right:Marker3D;
@export var marker_left:Marker3D;

@onready var notifier: VisibleOnScreenNotifier3D = $VisibleOnScreenNotifier3D

func _ready() -> void:
	LevelStageController.instance.attached_piece.connect(just_attached_piece);
	
func _on_visible_on_screen_notifier_3d_screen_entered() -> void:
	make_next_piece();
	
func _on_visible_on_screen_notifier_3d_screen_exited() -> void:
	pass # Replace with function body.

func just_attached_piece(piece:LevelStagePiece):
	match direction:
		LevelStagePiece.AttachmentDirection.FORWARD:
			global_position = piece.pivot_forward.global_position - marker_forward.position;
		LevelStagePiece.AttachmentDirection.BACKWARD:
			global_position = piece.pivot_backward.global_position - marker_back.position;
		LevelStagePiece.AttachmentDirection.RIGHT:
			global_position = piece.pivot_right.global_position - marker_right.position;
		LevelStagePiece.AttachmentDirection.LEFT:
			global_position = piece.pivot_left.global_position - marker_left.position;
			
	await get_tree().process_frame;		
			
	if notifier.is_on_screen():
		make_next_piece();
			

func make_next_piece()->void:
	print("[Constant Piece Creator] making piece [%s]" % [Engine.get_frames_drawn()]);
	print_stack();
	LevelStageController.instance.set_attachment_direction(direction);
	LevelStageController.instance.create_piece_and_attach(pieces[randi() % pieces.size()]);
