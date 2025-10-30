class_name LevelObjectsController
extends Node
## Controller for getting level objects
##
## Gives a centralized way for a level to create and get it's objects through code.
## This enables for easier object and pooling management.
## It also helps to manage created objects into groups and track them easily.

static var instance:LevelObjectsController

class GroupSignals:
	signal added;
	signal killed; ## need to call _subscribe_killed() or add to the group with subscribe_to_kill as true to work.
	signal removed;

var _level_groups_dict:Dictionary = {}
var _level_groups_state_dict:Dictionary = {}

func _ready():
	instance = self
	pass

class EnemyGroup:
	var group:Array[Health];

	signal killed_all;
	signal finished;

	func add_health(h:Health):
		if h:
			group.push_back(h);
			h.dead_damage.connect(on_health_dead);
			h.tree_exited.connect(on_health_exit.bind(h));

	func add_enemy(enemy_node:Node):
		add_health(Health.FindHealth(enemy_node));

	func on_health_dead(damage:Health.DamageData, health:Health):
		group.erase(health);
		if group.size() <= 0:
			killed_all.emit();

	func on_health_exit(health:Health):
		if not _has_any_valid_in_group():
			finished.emit()

	func _has_any_valid_in_group()->bool:
		for enemy in group:
			if is_instance_valid(enemy): return true;
		return false;


func get_group_elements_count(level_group:String) -> int:
	if !_level_groups_dict.has(level_group):
		push_warning("[LEVEL OBJECTS CONTROLLER] Could not find group: " + level_group)
		return 0

	var group:Node = _level_groups_dict[level_group] as Node
	return group.get_child_count()

func has_any_objects(level_group:String)->bool:
	return get_group_elements_count(level_group) > 0;

func cmd_wait_group(level_group:String, amount_zero:int = 0) -> Level.CMD_Wait_ObjsGroup:
	return Level.CMD_Wait_ObjsGroup.new(self, level_group, amount_zero)

func cmd_wait_group_or_time(level_group:String, time:float, amount_zero:int = 0):
	return Level.CMD_Parallel.new([
		Level.CMD_Wait_Seconds.new(time),
		Level.CMD_Wait_ObjsGroup.new(self, level_group, amount_zero),
	])

func cmd_wait_group_and_time(level_group:String, time:float, amount_zero:int = 0):
	return Level.CMD_Parallel_Complete.new([
		Level.CMD_Wait_Seconds.new(time),
		Level.CMD_Wait_ObjsGroup.new(self, level_group, amount_zero),
	])

func cmd_free_group(level_group:String) -> Level.CMD:
	return Level.CMD_Callable.new(free_group_elements.bind(level_group))

func cmd_wait_group_element_remove(level_group:String):
	return Level.CMD_Wait_Signal.new(get_group_signals(level_group).removed);

func cmd_wait_group_element_killed(level_group:String):
	return Level.CMD_Wait_Signal.new(get_group_signals(level_group).killed);

func cmd_wait_group_element_added(level_group:String):
	return Level.CMD_Wait_Signal.new(get_group_signals(level_group).added);

func wait_until_group_empty(level_group:String, amount_of_objects_is_empty:int = 0):
	var group:Node = _level_groups_dict[level_group] as Node
	if group == null:
		print("[LEVEL OBJECTS CONTROLLER] Could not find group: " + level_group)
		return

	while group.get_child_count() > amount_of_objects_is_empty:
		await get_tree().process_frame


func cmd_create_object(obj_scene:PackedScene, group:String, pos_vec3:Callable, fwd:Vector3 = Vector3.ZERO, subscribe:bool = false, callable:Callable = Callable()):
	return Level.CMD_Callable.new(func create_object():
		var obj = create_object(obj_scene, group, pos_vec3.call(), fwd, subscribe);
		if callable:
			callable.call(obj);
		);

func cmd_create_object_grid(obj_scene:PackedScene, pos_grid:Vector2, lvl:Level, fwd:Vector3 = Vector3.ZERO, group:String = "", subscribe:bool = false, callable:Callable = Callable()):
	return cmd_create_object(obj_scene, group, func get_grid_pos(): return lvl.stage.get_grid(pos_grid.x, pos_grid.y), fwd, subscribe, callable);

## Creates an objects from a scene
##
## Creates the object and adds it to a group (to be child of and tracked)
## If no group is set, adds as child of self
func create_object(obj_scene:PackedScene, level_group:String = "", obj_position:Vector3 = Vector3.ZERO, obj_forward:Vector3 = Vector3.ZERO, subscribe_to_killed_element:bool = false) -> Node3D:
	if obj_scene == null:
		print("[LEVEL OBJECTS CONTROLLER] Scene cannot be null!")
		return null

	var new_obj = obj_scene.instantiate() as Node3D

	if level_group.is_empty():
		add_child(new_obj)
	else:
		get_group_node(level_group).add_child(new_obj)
		if subscribe_to_killed_element:
			_subscribe_killed(new_obj, level_group);

	get_group_signals(level_group).added.emit();

	new_obj.position = obj_position
	if obj_forward != Vector3.ZERO:
		new_obj.basis = Basis.looking_at(obj_forward, Vector3.UP, true);
		#print("[INSTANTIATE] %s direction is %s" % [new_obj, obj_forward]);
	return new_obj

func _subscribe_killed(obj:Node, level_group:String):
	var health:Health = find_health_from_node(obj);
	if health:
		health.dead_damage.connect(func(damage:Health.DamageData, health_inst:Health):
			_level_groups_state_dict[level_group].killed.emit()
			, CONNECT_ONE_SHOT)

func free_group_elements(level_group:String):
	if !_level_groups_dict.has(level_group):
		print("[LEVEL OBJECTS CONTROLLER] Could not find group: " + level_group)
		return 0

	var group:Node = _level_groups_dict[level_group] as Node
	for child in group.get_children():
		child.queue_free()

func get_group_signals(group_name:String)->GroupSignals:
	if _level_groups_state_dict.has(group_name):
		return _level_groups_state_dict[group_name];
	else:
		var gs:GroupSignals = GroupSignals.new();
		_level_groups_state_dict[group_name] = gs;
		return gs;

func get_group_node(group_name:String)->Node:
	var group:Node;
	if _level_groups_dict.has(group_name):
		group = _level_groups_dict[group_name]
	else:
		group = Node.new()
		if OS.has_feature("editor"):
			group.name = "%s_group" % group_name;
		add_child(group)
		_level_groups_dict[group_name] = group;
		var gs:GroupSignals = get_group_signals(group_name);
		group.child_exiting_tree.connect(func(c):
			gs.removed.emit();
			, CONNECT_ONE_SHOT);
	return group;

func add_to_group_node(obj:Node, group_name:String):
	if obj.get_parent():
		obj.reparent(get_group_node(group_name))
	else:
		get_group_node(group_name).add_child(obj);

static func find_health_from_node(node:Node):
	return Health.FindHealth(node, true, true, false, false);

## Deprecated in favor of create_object. Creates an objects from a scene
##
## Creates the object and adds it to a group (to be child of and tracked)
## If no group is set, adds as child of self
## @deprecated
func create_object_scn(obj_scene:PackedScene, level_group:String = "") -> Node3D:
	return create_object(obj_scene, level_group)
