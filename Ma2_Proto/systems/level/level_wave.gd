class_name LevelWave extends VisibleOnScreenNotifier3D

@export_category("WAVE: Will find these things automatically")
@export var wave:Dictionary = {};
@export var default_group_name:String;

signal wave_started;

func _ready():
	for node in get_children():
		wave[node] = node.position;

	for w in wave.keys():
		w.get_parent().remove_child(w);

	self.screen_entered.connect(on_area_screen_entered);

func position_self(pos:Vector3):
	global_position = pos - Vector3(0, 0, get_distance().z * 0.5);
	print("[LevelWave] positioned self %s in %s" % [name, pos - Vector3(0, 0, get_distance().z * 0.5)]);
	# tested this is correct even after 2 frames
	await get_tree().process_frame;
	await get_tree().process_frame;
	await get_tree().process_frame;
	print("[LevelWave] %s after 3 frames my position is %s (%s)" % [name, global_position, pos - Vector3(0, 0, get_distance().z * 0.5)]);

func get_distance()->Vector3:
	return self.aabb.size;

#func get_beginning_position()->Vector3:
	#return Vector3(global_position.x, global_position.y, self.aabb.position.z);

func start_wave():
	print("[WAVE] starting wave %s" % name);
	for w in wave.keys():
		add_child(w);
		#w.position = wave[w];
	wave_started.emit();

func on_area_screen_entered():
	start_wave();
