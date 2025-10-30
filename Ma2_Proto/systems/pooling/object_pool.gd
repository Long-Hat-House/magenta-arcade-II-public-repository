class_name ObjectPool extends Node

class PooledObject:
	var node;
	var pooledObject:Poolable;

	func _init(obj):
		node = obj;
		if obj is Node:
			pooledObject = Poolable.FindPoolable(obj as Node);

	func can_be_used()->bool:
		return node != null and is_instance_valid(node) and node.get_parent() == null;

	func queue_free():
		pooledObject = null;
		if node and is_instance_valid(node):
			node.queue_free();

class Pool:
	var creator:PackedScene;
	var instances:Array[PooledObject] = [];
	var pool_name:String;

	func _init(scene:PackedScene):
		creator = scene;
		pool_name = "ObjectPool/" + scene.resource_path.get_file()

	func find_next()->PooledObject:
		for instance:PooledObject in instances:
			if instance.node == null or !is_instance_valid(instance.node):
				instance.node = creator.instantiate();
				push_warning("'%s->%s' was queue_free()d instead of ObjectPool.repool()ed !!" % [creator, creator.resource_name])
			if instance.can_be_used():
				if instance.pooledObject:
					instance.pooledObject.startPooled();
				return instance;
		return _create_next();

	func _create_next()->PooledObject:
		var newInstance = PooledObject.new(creator.instantiate());
		instances.append(newInstance);
		return newInstance;

	func get_amount_instances()->int:
		if instances:
			return instances.size();
		else:
			return 0;


	func clear():
		for instance in instances:
			instance.queue_free();
		instances.clear();

static var _singleton:ObjectPool;
var _dict:Dictionary[PackedScene, Pool] = {}; #packedscene -> pool

var _readied:bool = false
var _destroyed:bool = false

func _ready():
	if _readied:
		print("[OBJECT POOL] Readying again??");
		return
	Performance.add_custom_monitor(&"ObjectPool/Total Pooled Objects", get_total_pooled_objects);
	Performance.add_custom_monitor(&"ObjectPool/Total Pooled Valid Objects", get_total_valid_objects);
	Performance.add_custom_monitor(&"ObjectPool/Total Pooled Invalid Objects", get_total_invalid_objects);
	print("[OBJECT POOL] readied object pool!!!");
	_readied = true

func _destroy():
	if _destroyed:
		print("[OBJECT POOL] Destroying again??");
		return
	Performance.remove_custom_monitor(&"ObjectPool/Total Pooled Objects");
	Performance.remove_custom_monitor(&"ObjectPool/Total Pooled Valid Objects");
	Performance.remove_custom_monitor(&"ObjectPool/Total Pooled Invalid Objects");
	print("[OBJECT POOL] destroyed object pool!!!")
	_destroyed = true
	queue_free()

func _exit_tree() -> void:
	if !_destroyed:
		_destroy()

func get_total_pooled_objects()->int:
	var number:int = 0;
	for value:Pool in _dict.values():
		if value == null:
			printerr("[OBJECT POOL] - This shouldnt be null!")
		else:
			number += value.instances.size();
	return number;

func get_total_valid_objects()->int:
	return get_objects_that_conform(is_pooled_object_not_null)

func get_total_invalid_objects()->int:
	return get_objects_that_conform(func(obj:PooledObject): return not is_pooled_object_not_null(obj));

func is_pooled_object_not_null(obj:PooledObject):
	return obj.node != null and is_instance_valid(obj.node);

func get_objects_that_conform(to_what:Callable)->int:
	var number:int = 0;
	for value:Pool in _dict.values():
		if value == null:
			printerr("[OBJECT POOL] - This shouldnt be null!")
		else:
			for instance:PooledObject in value.instances:
				if to_what.call(instance):
					number += 1;
	return number;

#var _reverseDict:Dictionary = {};
const objectPoolingManager = preload("res://systems/pooling/ObjectPoolingManager.tscn");

static func make_singleton(where:Node)->void:
	if _singleton == null or not is_instance_valid(_singleton):
		_singleton = objectPoolingManager.instantiate() as ObjectPool;
		print("[OBJECT POOL] - Will make singleton!")
		where.add_child(_singleton);

static func clear_all():
	if _singleton and is_instance_valid(_singleton):
		if OS.has_feature("editor"):
			for pool in _singleton._dict:
				Performance.remove_custom_monitor(_singleton._dict[pool].pool_name);
				_singleton._dict[pool].clear()
		_singleton._dict.clear()
		_singleton._destroy()

static func instantiate(scene:PackedScene)->PooledObject:
	make_singleton(LevelManager.current_level);

	if not _singleton._dict.has(scene):
		var new_pool = Pool.new(scene)
		_singleton._dict[scene] = new_pool;

		if OS.has_feature("editor"):
			Performance.add_custom_monitor(new_pool.pool_name, new_pool.get_amount_instances);

	var next = _singleton._dict[scene].find_next();
	#_singleton._reverseDict[next.node] = _singleton._dict[scene];
	return next;

static func repool(instance:Node)->void:
	#print("Repooling %s" % [instance]);
	#print_stack();

	assert(_singleton != null, "repooling %s while nobody never got a single object from pool!" % [instance])
	assert(instance.get_parent() != null, "repooling %s which is already repooled!" % [instance])
	#assert(_singleton._reverseDict.has(instance), "%s was never pooled before!!" % [instance]);

	#var pool:Pool = _singleton._reverseDict[instance];
	#instance.get_parent().call_deferred("remove_child", instance);
	instance.queue_free();
