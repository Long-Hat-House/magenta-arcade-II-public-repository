class_name LevelStagePiece
extends LHH3D

enum AttachmentDirection {
	FORWARD,
	BACKWARD,
	RIGHT,
	LEFT
}

@export var pivot_forward:Node3D;
@export var pivot_backward:Node3D;
@export var pivot_right:Node3D;
@export var pivot_left:Node3D;

var attached_piece_dict:Dictionary = {}

static func get_opposite_direction(direction:AttachmentDirection) -> AttachmentDirection:
	match direction:
		AttachmentDirection.FORWARD:
			return AttachmentDirection.BACKWARD
		AttachmentDirection.BACKWARD:
			return AttachmentDirection.FORWARD
		AttachmentDirection.RIGHT:
			return AttachmentDirection.LEFT
		AttachmentDirection.LEFT:
			return AttachmentDirection.RIGHT
		_:
			return AttachmentDirection.FORWARD

func get_attachment_pivot(direction:AttachmentDirection) -> Node3D:
	match direction:
		AttachmentDirection.FORWARD:
			return pivot_forward
		AttachmentDirection.BACKWARD:
			return pivot_backward
		AttachmentDirection.RIGHT:
			return pivot_right
		AttachmentDirection.LEFT:
			return pivot_left
		_:
			return self

func get_attached_piece(direction:AttachmentDirection) -> LevelStagePiece:
	if attached_piece_dict.has(direction) && is_instance_valid(attached_piece_dict[direction]):
		return attached_piece_dict[direction]
	return null

func attach_to_piece(other:LevelStagePiece, direction:AttachmentDirection):
	var opposite_direction:AttachmentDirection = get_opposite_direction(direction)

	other.set_attached_piece(self, direction)
	set_attached_piece(other, opposite_direction)

	position = \
		other.get_attachment_pivot(direction).global_position - \
		get_attachment_pivot(opposite_direction).position

func set_attached_piece(other:LevelStagePiece, direction:AttachmentDirection):
	detach_piece(direction)
	attached_piece_dict[direction] = other

func detach_piece(direction:AttachmentDirection):
	if attached_piece_dict.has(direction):
		var other = attached_piece_dict[direction]
		attached_piece_dict.erase(direction)
		if is_instance_valid(other):
			(other as LevelStagePiece).detach_piece(get_opposite_direction(direction))

var _in_screen_mark:int = 0
var _in_screen:bool = false;
var _destruction_timer:Timer;
var _can_destroy:bool = false

func _exit_tree() -> void:
	_can_destroy = false
	_in_screen_mark = Time.get_ticks_msec();
	_stop_destruction_timer()

func _on_piece_just_attached():
	_can_destroy= true
	_in_screen_mark = Time.get_ticks_msec();
	_stop_destruction_timer()

func _on_screen_entered():
	_in_screen_mark = Time.get_ticks_msec();
	_in_screen = true;

func _on_screen_exited():
	_in_screen = false;
	if !_can_destroy: return
	var time_in_screen:int = Time.get_ticks_msec() - _in_screen_mark;
	if time_in_screen > 300:
		_start_destruction_timer()

func _start_destruction_timer():
	if !_can_destroy: return
	if is_instance_valid(_destruction_timer): return

	_destruction_timer = Timer.new()
	add_child(_destruction_timer)
	_destruction_timer.timeout.connect(_check_for_destruction)
	_destruction_timer.start(2)

func _stop_destruction_timer():
	if _destruction_timer:
		_destruction_timer.stop()
		_destruction_timer.queue_free()
		_destruction_timer = null

func _check_for_destruction():
	if !_in_screen and is_instance_valid(self):
		queue_free()
