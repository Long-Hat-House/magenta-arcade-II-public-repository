class_name SpawnArea extends VisibleOnScreenNotifier3D

@export var scenes:Array[PackedScene];

@export var spawn_multiple_default:int = 1;
@export var spawn_multiple_default_duration:float = 0;
@export var spawn_multiple_default_ease:Tween.EaseType = Tween.EASE_IN;
@export var spawn_multiple_default_trans:Tween.TransitionType = Tween.TRANS_QUINT;
@export var parent:Node3D;
@export var enforce_normalized_basis:bool = true;
@export var object_pooling:bool = true;

signal do_spawn_start;
signal do_spawn_finish;
signal tween_finish;
signal instantiated(inst:Node3D);

var curr:Tween;

func get_random_position()->Vector3:
	return global_transform * get_random_position_local();
				
func get_random_position_local()->Vector3:
	var rect:AABB = self.get_aabb();
	return rect.position +\
			Vector3(
				rect.size.x * randf(), 
				rect.size.y * randf(), 
				rect.size.z * randf()
				);
				

func get_next_scene():
	return scenes[randi() % scenes.size()];

func _spawn():
	var inst = InstantiateUtils.InstantiateInTree(
		get_next_scene(),
		self,
		get_random_position_local());
	if parent:
		inst.reparent(parent);
		
func spawn_multiple(how_many:int):
	while how_many > 0:
		how_many -= 1;
		_spawn();
		
func spawn_tween(how_many:int, duration:float, ease:Tween.EaseType = Tween.EASE_IN, trans:Tween.TransitionType = Tween.TRANS_QUINT)->Tween:
	#if curr and curr.is_running():
		#curr.kill();
	curr = create_tween();
	spawn_tweener(curr, how_many, duration).set_ease(ease).set_trans(trans);
	curr.tween_callback(tween_finish.emit);
	return curr;
		
func spawn_tweener(tween:Tween, how_many:int, duration:float)->MethodTweener:
	return VFX_Utils.make_vfxs_in_region(tween, scenes, parent, self, how_many, duration, object_pooling, enforce_normalized_basis, _on_each_instance);

func do_spawn(number:int, duration:float = 0):
	do_spawn_start.emit();
	if duration == 0:
		spawn_multiple(number);
	else:
		await spawn_tween(number, duration, spawn_multiple_default_ease, spawn_multiple_default_trans).finished;
	do_spawn_finish.emit();

func do_spawn_default():
	await do_spawn(spawn_multiple_default, spawn_multiple_default_duration);
	
func _on_each_instance(inst:Node3D):
	instantiated.emit(inst);
