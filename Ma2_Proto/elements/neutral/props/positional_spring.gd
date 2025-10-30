class_name PositionalSpring extends Node3D

var origin_pos:Vector3;
var origin_lpos:Vector3;
var origin_rot:Vector3;
var origin_lrot:Vector3;

@export var late_position_up = 0.6;
@export var late_position_down = 0.4;
@export var late_rotation_up = 0.1;
@export var late_rotation_down = 0.02;
@export var random_chance_wont_work:float = 0.6;

var lerp_position:float;
var lerp_rotation:float;

var readied:bool;
var first_run:bool
var canProcess:bool;

func _ready() -> void:
	readied = true;
	lerp_position = randf_range(late_position_down, late_position_up);
	lerp_rotation = randf_range(late_rotation_down, late_rotation_up);
	this_debug = debug;
	debug+=1;


func _enter_tree() -> void:
	first_run = true

var _curr_pos:Vector3;
var _curr_rot:Vector3;
var parent3D:Node3D = self.get_parent_node_3d();

static var debug:int = 0;
var this_debug:int;

func _process(delta: float) -> void:
	if not canProcess:
		return;
		
	if not readied:
		return
		
	if first_run:
		canProcess = randf() > random_chance_wont_work;
		origin_pos = global_position;
		origin_lpos = position;
		origin_rot = global_rotation;
		origin_lrot = rotation;
		_curr_pos = origin_pos;
		_curr_rot = origin_rot;
		first_run = false
	
	var originPosNow:Vector3 = parent3D.to_global(origin_lpos);
	var originRotNow:Vector3 = parent3D.global_rotation + origin_lrot;
	if originPosNow != _curr_pos:
		_curr_pos = lerp(_curr_pos, originPosNow, lerp_position);
		global_position = _curr_pos;
	if originRotNow != _curr_rot:
		_curr_rot = lerp(_curr_rot, originRotNow, lerp_rotation);
		global_rotation = _curr_rot;
		self.basis = self.basis.orthonormalized();

	#if this_debug == 5:
		#print("current position %s" % [_curr_pos]);
