class_name InstantiateUtils

static func add_child(node:Node, force_readable_name:bool = false, node_interal_mode:Node.InternalMode = 0):
	get_topmost_instantiate_node().add_child(node, force_readable_name, node_interal_mode);

static func get_topmost_instantiate_node()->Node:
	return LevelManager.get_topmost_node();

static func InstantiateInSamePlace3D(what:PackedScene, where:Node3D,
		positionOffset:Vector3 = Vector3(0,0,0), ignoreRotation:bool = false, objectPooling:bool = true) -> Node3D:

	var inst := Instantiate(what, where.get_parent(), objectPooling);
	inst.position = where.position + positionOffset;
	if not ignoreRotation:
		inst.rotation = where.rotation;
	return inst;

static func InstantiateInTree(what:PackedScene, where:Node3D,
		positionOffset:Vector3 = Vector3(0,0,0), ignoreRotation:bool = false, objectPooling:bool = true) -> Node3D:

	var inst := Instantiate(what, get_topmost_instantiate_node(), objectPooling);
	inst.global_position = where.global_position + positionOffset;
	if not ignoreRotation:
		inst.global_rotation = where.global_rotation;
	return inst;

static func RandomizeRotation3DPlane(inst:Node3D) -> void:
	inst.rotation = Vector3.UP * 360 * randf();

static func InstantiatePositionRotation(what:PackedScene, pos:Vector3, rot:Vector3 = Vector3.ZERO, parent:Node3D = null, objectPooling:bool = true) -> Node3D:
	if parent == null:
		parent = get_topmost_instantiate_node();
	var inst := Instantiate(what, parent, objectPooling);
	inst.global_position = pos;
	inst.global_rotation = rot;
	return inst;

static func InstantiateTransform3D(what:PackedScene, where:Transform3D, parent:Node3D = null, objectPooling:bool = true):
	if parent == null:
		parent = get_topmost_instantiate_node();
	var inst := Instantiate(what, parent, objectPooling);
	inst.global_transform = where;
	return inst;

static func Instantiate(what:PackedScene, parent:Node, objectPooling:bool) -> Node3D:
	var node:Node;
	if objectPooling:
		var inst := ObjectPool.instantiate(what);
		node = inst.node as Node;
	else:
		node = what.instantiate() as Node;
	parent.add_child(node);
	return node;
