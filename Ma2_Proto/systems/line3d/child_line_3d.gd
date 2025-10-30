@tool
class_name ChildLine3D extends Node3D

const MARKER = preload("res://elements/editor/marker/editor_simple_marker.tscn")

@export var editor_color:Color = Color.DARK_CYAN;
var betweens_amount:int = 3;
var markers:Array[Node3D];
var making_markers:bool = false;
var betweens:Array[Array] = [];
var floating_marker:Node3D;
var floating_marker_pos:float = 0;

func _ready():
	if Engine.is_editor_hint():
		remake_markers();
		floating_marker = MARKER.instantiate();
		floating_marker.set_ball_color(editor_color.lerp(Color.LIGHT_CYAN, 0.5));
		add_child(floating_marker, false, Node.INTERNAL_MODE_BACK);
	else:
		clear_markers();
	self.child_order_changed.connect(on_change_children);
	
func remake_markers():
	making_markers = true;
	clear_markers();
	make_markers();
	making_markers = false;
	
func on_change_children():
	if making_markers:
		return;
	else:
		clear_markers();
	
func get_line()->Array:
	return get_children(false);
	
func _process(delta:float):
	if not Engine.is_editor_hint(): return;
	
	floating_marker_pos = fmod(floating_marker_pos + delta * 10, get_line_length());
	floating_marker.global_position = get_position_in_line(floating_marker_pos);
	
func clear_markers():
	if markers:
		for mark in markers:
			mark.queue_free();
	if betweens:
		for bArray in betweens:
			for bet in bArray:
				bet.queue_free();
	markers.clear();
	betweens.clear();
		
func make_markers():
	var index:int = 0;
	if not betweens:
		betweens = [];
	var range_betweens = range(betweens_amount);
	for node in get_children():
		var node3D:Node3D = node as Node3D;
		if node3D:
			var marker:Editor_SimpleMarker = _make_marker();
			markers.push_back(marker);
			marker.global_position = node.global_position;
			marker.set_ball_color(editor_color);
			
			#Betweens code
			if index > 0:
				var bIndex:int = index - 1;
				while bIndex >= betweens.size():
					betweens.push_back([]);
				var orig:Vector3 = markers[bIndex].position;
				var end:Vector3 = marker.position;
				for b in range_betweens:
					if b >= betweens[bIndex].size():
						var bet:Editor_SimpleMarker = _make_marker();
						bet.set_ball_color(editor_color.lerp(Color.BLACK, 0.5));
						bet.scale = Vector3.ONE * 0.25;
						betweens[bIndex].push_back(bet);
					betweens[bIndex][b].position = orig.lerp(end, (b + 0.5) / betweens_amount);
			index += 1;
				
	_cleanse_markers(index);
	
func _make_marker()->Editor_SimpleMarker:
	var mark := MARKER.instantiate() as Editor_SimpleMarker
	add_child(mark, true, Node.INTERNAL_MODE_BACK);
	return mark;
		
func _get_marker(i:int)->Editor_SimpleMarker:
	if markers.size() <= i:
		markers.push_back(MARKER.instantiate());
		push_warning("%s markers" % markers.size())
		add_child(markers[i], true, Node.INTERNAL_MODE_BACK);
	push_warning("%s markers" % markers.size())
	return markers[i] as Editor_SimpleMarker;
	
func _cleanse_markers(from:int = 0):
	while markers.size() > from:
		markers.pop_back().queue_free();
	
	var bFrom := from - 1;
	while betweens.size() > bFrom:
		if betweens[betweens.size() - 1]:
			for bArray in betweens.pop_back():
				for b in bArray:
					b.queue_free();
				bArray.clear();
			
func invert_x():
	for node in get_line():
		node.position.x = -node.position.x;

func invert_z():
	for node in get_line():
		node.position.z = -node.position.z;
		
func get_position_values()->Array[Vector3]:
	var arr:Array[Vector3] = [];
	for node in get_line():
		arr.push_back(node.global_position);
	return arr;

func get_position_in_line(positionLine:float) -> Vector3:
	var amountWalked:float = 0;
	var line:Array = get_line();
	if line.is_empty():
		return Vector3.ZERO;
	for index:int in range(line.size() - 1):
		var segmentA := line[index] as Node3D;
		var segmentB := line[index + 1] as Node3D;
		if !is_instance_valid(segmentA) or !is_instance_valid(segmentB):
			continue;
		var segment:Vector3 = segmentB.global_position - segmentA.global_position;
		var segmentSize := segment.length();
		if positionLine < (amountWalked + segmentSize):
			var answer:Vector3 = segmentA.global_position + segment.normalized() * (positionLine - amountWalked);
			#print("[CHILDLINE_3D] found segment %s from %s (%s of %s) -> %s" % [segmentA.name, segmentB.name, positionLine, amountWalked, answer]);
			return answer;
		amountWalked += segmentSize;
	return line[line.size() - 1].global_position;
	
func get_position_in_line_percentage(percentage:float)->Vector3:
	return get_position_in_line(get_line_length() * percentage);
	
func get_direction_in_line_position(pos:float)->Vector3:
	var amountWalked:float = 0;
	var line:Array = get_line();
	var direction:Vector3 = Vector3.ZERO;
	if line.is_empty():
		return Vector3.ZERO;
	for index:int in range(line.size() - 1):
		var segmentA := line[index] as Node3D;
		var segmentB := line[index + 1] as Node3D;
		if !is_instance_valid(segmentA) or !is_instance_valid(segmentB):
			continue;
		var segment:Vector3 = segmentB.global_position - segmentA.global_position;
		var segmentSize := segment.length();
		direction = segment.normalized();
		if pos <= (amountWalked + segmentSize):
			return direction;
		amountWalked += segmentSize;
	return direction;
	
func get_direction_in_line_percentage(percentage:float):
	return get_direction_in_line_position(get_line_length() * percentage);
	
static func get_position_in_position_array(array:Array[Vector3], positionLine:float) -> Vector3:
	var amountWalked:float = 0;
	if array.is_empty():
		return Vector3.ZERO;
	for index in range(array.size() - 1):
		var segmentA := array[index];
		var segmentB := array[index + 1];
		var segment:Vector3 = segmentB - segmentA;
		var segmentSize := segment.length();
		if positionLine < (amountWalked + segmentSize):
			var answer:Vector3 = segmentA + segment.normalized() * (positionLine - amountWalked);
			return answer;
		amountWalked += segmentSize;
	return array[array.size() - 1];
	
	
	
var _cacheLength:float;
var _gotCacheLength:bool;
##Get the total length of the line.
func get_line_length()->float:
	if _gotCacheLength:
		return _cacheLength;
	var line = get_line();
	var amountWalked:float = 0;
	for index in range(line.size() - 1):
		var segmentA := line[index] as Node3D;
		var segmentB := line[index + 1] as Node3D;
		if !is_instance_valid(segmentA) or !is_instance_valid(segmentB):
			continue;
		var segment:Vector3 = segmentB.global_position - segmentA.global_position;
		var segmentSize := segment.length();
		amountWalked += segmentSize;
	_gotCacheLength = true;
	_cacheLength = amountWalked;
	return amountWalked;
	

static func get_position_array_length(array:Array[Vector3]) -> float:
	var amountWalked:float = 0;
	for index in range(array.size() - 1):
		var segmentA := array[index];
		var segmentB := array[index + 1];
		var segment:Vector3 = segmentB - segmentA;
		var segmentSize := segment.length();
		amountWalked += segmentSize;
	return amountWalked;
