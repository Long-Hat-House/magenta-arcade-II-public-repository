class_name EnemySlot extends Node3D

enum InstantiateStyle
{
	SAME_PARENT,
	FREE_IN_TREE
}

@export var queue_free_when_spawned:bool = true;

signal spawned(what:Node3D)

func _ready() -> void:
	visible = false;
	
static func _compare_nodes(a:Node3D, b:Node3D, where_global:Vector3):
	var dist_a = a.global_position - where_global;
	var dist_b = b.global_position - where_global;
	return dist_a.length_squared() <= dist_b.length_squared();
	
static func spawn(tree:SceneTree, scenes:Array[PackedScene], where_global:Vector3, method:Callable = Callable()):
	var nodes := tree.get_nodes_in_group(&"enemy_slot")
	nodes.sort_custom(_compare_nodes.bind(where_global));
	while scenes.size() > 0 and nodes.size() > 0:
		nodes.pop_front().spawn_here(scenes.pop_front(), InstantiateStyle.FREE_IN_TREE, method);
	
func spawn_here(scene:PackedScene, instantiate_style:InstantiateStyle = InstantiateStyle.FREE_IN_TREE, method:Callable = Callable()):
	var bicho:Node3D = scene.instantiate();
	
	match instantiate_style:
		InstantiateStyle.SAME_PARENT:
			self.get_parent_node_3d().add_child(bicho);
		InstantiateStyle.FREE_IN_TREE:
			InstantiateUtils.get_topmost_instantiate_node().add_child(bicho);
	
	bicho.global_transform = global_transform;
	method.call(bicho);
	spawned.emit(bicho);
	
	if queue_free_when_spawned:
		queue_free();
