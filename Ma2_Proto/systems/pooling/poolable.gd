class_name Poolable extends Node

static func FindPoolable(node:Node, includeInternal:bool = false, debug:bool = false) -> Poolable:
	if node is Poolable:
		if debug:
			print("FOUND in %s" % [node]);
		return node as Poolable;
	for child:Node in node.get_children(includeInternal):
		if debug:
			print("looking for poolable in %s's %s (%s)" % [node, child, child is Health])
		var recursivePoolable = FindPoolable(child, includeInternal, debug);
		if recursivePoolable:
			return recursivePoolable;
	if debug:
		print("found no poolable in %s" % [node]);
	return null;

#signal readyToBeUnPooled;
signal started;
signal ended;

var inObjectPooling:bool = true;

var _canBeUsed:bool = true;
var canBeUsed:bool : set = set_can_be_used, get =  get_can_be_used;
var creator:PackedScene;

func startPooled()->void:
	inObjectPooling = true;
	started.emit();
	
func endPooled()->void:
	inObjectPooling = false;
	ended.emit();
	
func _exit_tree():
	endPooled();
	
func set_creator_packed_scene(ps:PackedScene):
	creator = ps;
	
func set_can_be_used(canItBe:bool):
	#var oldCan := _canBeUsed;
	_canBeUsed = canItBe;
	#if(_canBeUsed and not oldCan):
		#readyToBeUnPooled.emit();
	

func get_can_be_used()->bool:
	return _canBeUsed;

func can_be_used()->bool:
	return true;
