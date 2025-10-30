class_name LevelStageController
extends Node

static var instance:LevelStageController

@export_group("Debug Setup")
@export var visuals_black:Node3D
@export var visuals_red:Node3D
@export var visuals_white:Node3D
@export var visual_labelZ:Label3D
@export var visual_labelX:Label3D

var _visuals_container:Node3D

var _debug_requires_update:bool = true
var _visuals_current_pivot:Node3D

var _stage_pivot:Vector3 = Vector3(0,0,0)
var _stage_pivot_offset:Vector3
var _stage_size:Vector3

var _grid_spacing:Vector3 = Vector3(1,0,1)

var _direction:LevelStagePiece.AttachmentDirection = LevelStagePiece.AttachmentDirection.FORWARD
var _reference_piece:LevelStagePiece

signal attached_piece(piece:LevelStagePiece);

enum Axis
{
	X,
	Y,
	Z,
}

func _ready() -> void:
	instance = self

func _update_stage_debug():
	if !_debug_requires_update:
		return

	if !DevManager.get_setting(DevManager.SETTING_STAGE_VISUALS_ENABLED):
		return

	_debug_requires_update = false

	if !_visuals_container:
		_visuals_container = Node3D.new()
		add_child(_visuals_container)

	for child in _visuals_container.get_children():
		child.queue_free()

#region BORDERS
	var red:Node3D
	# UP
	red = visuals_red.duplicate()
	_visuals_container.add_child(red)
	red.position = Vector3.ZERO
	red.scale = Vector3(_stage_size.x, 1, 0.1)

	# DOWN
	red = visuals_red.duplicate()
	_visuals_container.add_child(red)
	red.position = Vector3(0, 0, _stage_size.z)
	red.scale = Vector3(_stage_size.x, 1, 0.1)

	# LEFT
	red = visuals_red.duplicate()
	_visuals_container.add_child(red)
	red.position = Vector3(-_stage_size.x/2, 0, _stage_size.z/2)
	red.scale = Vector3(0.1, 1, _stage_size.z)

	# RIGHT
	red = visuals_red.duplicate()
	_visuals_container.add_child(red)
	red.position = Vector3(_stage_size.x/2, 0, _stage_size.z/2)
	red.scale = Vector3(0.1, 1, _stage_size.z)
#endregion

#region GRID
	# HORIZONTAL GRID
	for i in range(1, _stage_size.z/_grid_spacing.z):
		var black:Node3D = visuals_black.duplicate()
		_visuals_container.add_child(black)
		black.scale = Vector3(_stage_size.x, 1, 0.1)
		black.position = Vector3.BACK * i * (_grid_spacing.z)

	# HORIZONTAL LABELS
	for i in range(0, (_stage_size.z/_grid_spacing.z)):
		var label:Label3D = visual_labelZ.duplicate()
		_visuals_container.add_child(label)
		label.position = Vector3.BACK * i * (_grid_spacing.z) + Vector3.BACK * (_grid_spacing.z/2.0)
		label.set_text("%d" % i)

	# VERTICAL GRID
	for i in range(0, (_stage_size.x / _grid_spacing.x) / 2):
		var right:Node3D = visuals_black.duplicate()
		_visuals_container.add_child(right)
		right.scale = Vector3(0.1, 1, _stage_size.z)
		right.position.x = i * _grid_spacing.x + _grid_spacing.x/2
		right.position.z = _stage_size.z/2
		right.position.y = 0

		var left:Node3D = visuals_black.duplicate()
		_visuals_container.add_child(left)
		left.scale = Vector3(0.1, 1, _stage_size.z)
		left.position.x = -i * _grid_spacing.x - _grid_spacing.x/2
		left.position.z = _stage_size.z/2
		left.position.y = 0

	# VERTICAL LABELS
	for i in range(-(_stage_size.x/_grid_spacing.x)/2, (_stage_size.x/_grid_spacing.x)/2):
		var label:Label3D = visual_labelX.duplicate()
		_visuals_container.add_child(label)
		label.position = Vector3.RIGHT * i * (_grid_spacing.x) + Vector3.BACK * (_grid_spacing.x/2.0)
		label.position.z = _stage_size.z/2.0
		label.set_text("%d" % i)
#endregion

	# PIVOT
	_visuals_current_pivot = visuals_white.duplicate()
	_visuals_container.add_child(_visuals_current_pivot)

func _process(delta):
	if DevManager.get_setting(DevManager.SETTING_STAGE_VISUALS_ENABLED):
		_update_stage_debug() #only does it if required

		_visuals_container.show()

		if _visuals_container != null:
			_visuals_container.global_position = get_pos()

		if is_instance_valid(_visuals_current_pivot) && is_instance_valid(_reference_piece):
			_visuals_current_pivot.global_position = _reference_piece.get_attachment_pivot(_direction).global_position + Vector3.UP * 0.1

	elif _visuals_container && _visuals_container.visible:
		_visuals_container.hide()


func set_pivot_offset(offset:Vector3):
	_stage_pivot_offset = offset

func set_pivot_offset_to_exactly(where:Vector3):
	_stage_pivot_offset = where - _stage_pivot

func set_pivot_offset_to_exactly_node(where:Node3D):
	var pos := where.global_position;
	pos.y = 0;
	set_pivot_offset_to_exactly(pos);

func set_pivot_offset_x(offset:float):
	_stage_pivot_offset.x = offset;

func set_pivot_offset_y(offset:float):
	_stage_pivot_offset.y = offset;

func set_pivot_offset_z(offset:float):
	_stage_pivot_offset.z = offset;

func get_pivot_offset()->Vector3:
	return _stage_pivot_offset;

func add_pivot_offset(offset:Vector3):
	set_pivot_offset(_stage_pivot_offset + offset);

func invert_pivot_offset(axis:Axis = Axis.X):
	match axis:
		Axis.X:
			_stage_pivot_offset.x = -_stage_pivot_offset.x;
		Axis.Y:
			_stage_pivot_offset.y = -_stage_pivot_offset.y;
		Axis.Z:
			_stage_pivot_offset.z = -_stage_pivot_offset.z;


func set_stage_size(size:Vector3):
	_stage_size = size
	_debug_requires_update = true

func set_grid_spacing(x:float, z:float):
	_grid_spacing = Vector3(x, 0, z)
	_debug_requires_update = true

func get_grid_distance(x:float, z:float) -> Vector3:
	return Vector3(
		_grid_spacing.x * x,
		 0,
		_grid_spacing.z * z + _grid_spacing.z * 0.5
		);

func get_grid(x:float, z:float) -> Vector3:
	return get_pos() + get_grid_distance(x, z);

func get_grid_in_offset_direction(x:int, z:int, x_in_direction:bool = true, z_in_direction:bool = false) -> Vector3:
	if x_in_direction:
		if _stage_pivot_offset.x < 0:
			x = -x;
	if z_in_direction:
		if _stage_pivot_offset.z < 0:
			z = -z;
	return get_grid(x, z);

func get_grid_line(x:int, z:int) -> Vector3:
	var ret_x
	if x == 0:
		ret_x = 0
	elif x > 0:
		ret_x = (x-1) * _grid_spacing.x + _grid_spacing.x/2
	else:
		ret_x = (x+1) * _grid_spacing.x - _grid_spacing.x/2

	var ret_z = z * _grid_spacing.z
	return get_pos() + Vector3(ret_x, 0, ret_z)

func get_pos() -> Vector3:
	return _stage_pivot + _stage_pivot_offset

func get_pos_z() -> float:
	return get_pos().z

func get_pos_x() -> float:
	return get_pos().x

func get_pivot_position(direction:LevelStagePiece.AttachmentDirection) -> Vector3:
	if _reference_piece == null:
		return Vector3.ZERO;

	var pivot:Node3D;
	match direction:
		LevelStagePiece.AttachmentDirection.FORWARD:
			pivot = _reference_piece.pivot_forward;
		LevelStagePiece.AttachmentDirection.BACKWARD:
			pivot = _reference_piece.pivot_backward;
		LevelStagePiece.AttachmentDirection.RIGHT:
			pivot = _reference_piece.pivot_right;
		LevelStagePiece.AttachmentDirection.LEFT:
			pivot = _reference_piece.pivot_left;

	if pivot:
		return pivot.global_position;
	else:
		return _reference_piece.global_position;

func repivot():
	if _reference_piece == null:
		return

	var forward = LevelStagePiece.AttachmentDirection.FORWARD

	match _direction:
		LevelStagePiece.AttachmentDirection.FORWARD:
			_stage_pivot = _reference_piece.get_attachment_pivot(_direction).global_position
		LevelStagePiece.AttachmentDirection.BACKWARD:
			_stage_pivot =  _reference_piece.get_attachment_pivot(_direction).global_position
			_stage_pivot.z -= _stage_size.z
		LevelStagePiece.AttachmentDirection.RIGHT:
			_stage_pivot = _reference_piece.get_attachment_pivot(_direction).global_position
			_stage_pivot.x -= _stage_size.x/2
			_stage_pivot.y = _reference_piece.get_attachment_pivot(forward).global_position.y
		LevelStagePiece.AttachmentDirection.LEFT:
			_stage_pivot = _reference_piece.get_attachment_pivot(_direction).global_position
			_stage_pivot.x += _stage_size.x/2
			_stage_pivot.y = _reference_piece.get_attachment_pivot(forward).global_position.y

func set_attachment_direction(direction:LevelStagePiece.AttachmentDirection):
	_direction = direction

	var new_ref:LevelStagePiece = _reference_piece
	while new_ref != null:
		_reference_piece = new_ref
		new_ref = _reference_piece.get_attached_piece(direction)

func attach_piece(new_piece:LevelStagePiece):
	new_piece.position = Vector3(100,-100,0);
	if _reference_piece == null:
		new_piece.position = _stage_pivot
	else:
		new_piece.attach_to_piece(_reference_piece, _direction)

	_reference_piece = new_piece

	if !new_piece.get_parent():
		add_child(new_piece)
	elif new_piece.get_parent() != self:
		new_piece.reparent(self)

	new_piece._on_piece_just_attached()
	attached_piece.emit(new_piece);

func create_piece_and_attach(piece_scene:PackedScene) -> LevelStagePiece:
	if piece_scene == null:
		print_debug("[LEVEL STAGE CONTROLLER] Scene cannot be null!")
		return null

	var new_piece = piece_scene.instantiate() as LevelStagePiece

	if new_piece is not LevelStagePiece:
		print_debug("[LEVEL STAGE CONTROLLER] Level Stage piece was not actually a piece! Will destroy and not add")
		new_piece.queue_free()
		return null

	attach_piece(new_piece)

	return new_piece


func fill_with(piece_scene_set:Array[PackedScene], distance:float):
	if _reference_piece == null:
		create_piece_and_attach(piece_scene_set[randi() % piece_scene_set.size()])

	var check = func(new_pos:Vector3, ref_pos:Vector3) -> bool:
		#print_debug("new pos: ", new_pos, ", ref pos: ", ref_pos)
		match(_direction):
			LevelStagePiece.AttachmentDirection.FORWARD:
				return new_pos.z <= ref_pos.z - distance
			LevelStagePiece.AttachmentDirection.BACKWARD:
				return new_pos.z >= ref_pos.z + distance
			LevelStagePiece.AttachmentDirection.RIGHT:
				return new_pos.x >= ref_pos.x + distance
			LevelStagePiece.AttachmentDirection.LEFT:
				return new_pos.x <= ref_pos.x - distance
		return true

	var piece = _reference_piece
	while !check.call(\
			piece.get_attachment_pivot(_direction).global_position,\
			get_pos()
			):
		piece = create_piece_and_attach(piece_scene_set[randi() % piece_scene_set.size()])

##Get all positions of an grid of 0 and 1s with offsets.
func get_grid_positions(grid:Array[Array], offsetGridX:int = 0, offsetGridZ:int = 0)->Array[Vector3]:
	var arr:Array[Vector3] = [];
	for z in range(grid.size()):
		for x in range(grid[z].size()):
			if grid[z][x] != 0:
				arr.push_front(get_grid(x + offsetGridX, z + offsetGridZ));
	return arr;
