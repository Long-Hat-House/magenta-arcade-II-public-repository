class_name ConstantCreatorLine3D extends Node3D

enum Style
{
	ChildLine3D,
	Path3D
}

@export var lines:Array[ChildLine3D];
@export var paths:Array[Path3D];
@export var where_from:Style = Style.ChildLine3D;
## The scenes to create
@export var scenes:Array[PackedScene];
## The custom order of scenes to get from scenes array. Default is random.
@export var creating:bool = true;
@export var order:Array[int];
@export var create_interval:float = 2;
@export var create_interval_random_plus:float = 0;
@export var create_random_position_circle_radius:float = 0.1;
@export var create_random_position_circle_normal:Vector3 = Vector3.UP;
@export var jump_height:float = 2;
@export var move_velocity:float = 1;
@export var move_velocity_random_add:float = 0;
@export var warmed_time:float = 0;
@export var stop_moving_dead_healths:bool;
var health_path:NodePath;

var _curr:int;
var count:float;
var max_length:float;

class Liner:
	var instance:Node3D;
	var scene:PackedScene;
	var dist_walked:float;
	var dist_used_before:float;
	var offset:Vector3;
	var locked:bool;
	var tween:Tween;
	var velocity:float;

	var reuseable:bool:
		get:
			if is_instance_valid(instance):
				return not instance.get_parent();
			return false;

var instances:Array[Liner]

signal created(instance:Node3D);
signal finished(instance:Node3D);
signal dead(instance:Node3D);
signal jump_start(instance:Node3D);
signal jump_end(instance:Node3D);
signal moved(instance:Node3D);

func _ready() -> void:
	max_length = _get_length();
	count = -warmed_time;

func _get_length()->float:
	var leng:float = 0.0;
	match where_from:
		Style.Path3D:
			for p in paths:
				leng += p.curve.get_baked_length();
		Style.ChildLine3D:
			for l in lines:
				leng += l.get_line_length();
	return leng;

func _get_position(subject:Liner)->Vector3:
	match where_from:
		Style.ChildLine3D:
			return _get_position_from_child_line(subject);
		Style.Path3D:
			return _get_position_from_path(subject);
	push_error("%s has no style to get from!" % self)
	return Vector3.ZERO;

func _get_position_from_path(subject:Liner)->Vector3:
	var last_path:Path3D;
	var last_leng:float;
	var pos:float = subject.dist_walked;
	var old_pos:float = subject.dist_used_before;
	subject.dist_used_before = pos;
	var paths_size:int = paths.size();

	for index in range(paths_size):
		var path:Path3D = paths[index];
		var leng:float = path.curve.get_baked_length();

		last_path = path;
		last_leng = leng;

		if old_pos <= leng and pos > leng and (index + 1) < paths_size: ## are we needing a jump?
			tween_instance(subject, global_transform * paths[index + 1].curve.sample_baked(pos - leng));
			return global_transform * path.curve.sample_baked(leng);
		elif pos < leng: ## got correct position
			return global_transform * path.curve.sample_baked(pos);
		else:
			pos -= leng;
			old_pos -= leng;

	return global_transform * last_path.curve.sample_baked(pos + last_leng);

func _get_position_from_child_line(subject:Liner)->Vector3:
	var last_line:ChildLine3D;
	var last_leng:float;
	var pos:float = subject.dist_walked;
	var old_pos:float = subject.dist_used_before;
	subject.dist_used_before = pos;
	var lines_size:int = lines.size();

	for index in range(lines_size):
		var l:ChildLine3D = lines[index];
		var leng:float = l.get_line_length();

		last_line = l;
		last_leng = leng;

		if old_pos <= leng and pos > leng and (index + 1) < lines_size: ## are we needing a jump?
			tween_instance(subject, lines[index + 1].get_position_in_line(pos - leng));
			return l.get_position_in_line(leng);
		elif pos < leng: ## got correct position
			return l.get_position_in_line(pos);
		else:
			pos -= leng;
			old_pos -= leng;

	return last_line.get_position_in_line(pos + last_leng);

func _process(delta: float) -> void:
	if creating:
		count -= delta;
		while count < 0.0:
			_create(-count);
			count += create_interval + randf() * create_interval_random_plus;
	_walk(delta);

func _create(time_back:float)->Liner:
	var scene:PackedScene = _get_next_scene(_curr);
	_curr += 1;
	if scene:
		for inst in instances:
			if inst.scene == scene and inst.reuseable:
				add_child(inst.instance);
				return inst;
		var new_inst = Liner.new();
		new_inst.scene = scene;
		new_inst.instance = scene.instantiate();
		new_inst.offset = _create_random_offset_position();
		add_child(new_inst.instance);
		new_inst.velocity = randf_range(move_velocity, move_velocity + move_velocity_random_add);
		new_inst.dist_walked = time_back * new_inst.velocity;
		new_inst.instance.global_position = _get_position(new_inst);
		if stop_moving_dead_healths:
			var h:Health = get_health(new_inst.instance);
			if h:
				h.dead_parameterless.connect(func():
					dead.emit(new_inst.instance);
					instances.erase(new_inst);
					, CONNECT_ONE_SHOT)
		instances.push_back(new_inst);
		created.emit(new_inst.instance);
		return new_inst;
	else:
		return null;

func _create_random_offset_position()->Vector3:
	if create_random_position_circle_radius == 0:
		return Vector3.ZERO;

	var t:float = randf() * PI * 2.0;
	var offset:Vector3 = Vector3(cos(t), 0, sin(t)) * randf() * create_random_position_circle_radius;
	offset = Quaternion(Vector3.UP, create_random_position_circle_normal) * offset;
	return offset;

func get_health(node:Node)->Health:
	var h:Health;
	if health_path.is_empty():
		h = Health.FindHealth(node, true, true);
		health_path = node.get_path_to(h);
	else:
		h = node.get_node(health_path);
	return h;

func _walk(delta:float):
	var to_delete:Array[Liner] = [];
	for inst in instances:
		if not is_instance_valid(inst.instance):
			to_delete.push_back(inst);
			continue;
		if inst.tween and inst.tween.is_running():
			continue;
		if inst.locked:
			continue;
		inst.dist_walked += inst.velocity * delta;
		if inst.dist_walked > max_length:
			finished.emit(inst.instance);
			if inst.instance.get_parent():
				remove_child(inst.instance);
			to_delete.push_back(inst);
		else:
			inst.instance.global_position = _get_position(inst) + inst.offset;
			moved.emit(inst.instance);
			#print("Child creator line %s in %s" % [inst.instance, inst.instance.global_position]);
	for deleted in to_delete:
		instances.erase(deleted);

func tween_instance(instance:Liner, target:Vector3):
	if not is_instance_valid(instance.instance): return;
	instance.tween = create_tween();
	instance.tween.chain();
	instance.tween.tween_callback(func():
		jump_start.emit(instance.instance);
		)
	instance.tween.tween_interval(0.5);
	#instance.tween.tween_property(instance.instance, "global_position", target, 1);
	TweenUtils.tween_jump_vector3(instance.instance, instance.tween, "global_position",
			instance.instance.global_position,
			target,
			Vector3.UP * jump_height,
			0.35).set_ease(Tween.EASE_OUT_IN).set_trans(Tween.TRANS_LINEAR);
	instance.tween.tween_callback(func():
		jump_end.emit(instance.instance);
		)
	instance.tween.tween_interval(0.25);

func set_instance_locked(instance:Node3D, locked:bool):
	var inst = _find_instance(instance);
	if inst:
		inst.locked = locked;

func _find_instance(instance:Node3D)->Liner:
	for walker in instances:
		if walker.instance == instance:
			return walker;
	return null;

func free() -> void:
	for inst in instances:
		if inst.instance and is_instance_valid(inst.instance):
			inst.instance.queue_free.call_deferred();
	instances.clear();

func _get_next_scene(curr:int)->PackedScene:
	if order and order.size() > 0:
		var which:int = order[curr % order.size()];
		if which < 0:
			return null;
		else:
			return scenes[which % scenes.size()];
	else:
		return scenes.pick_random();
