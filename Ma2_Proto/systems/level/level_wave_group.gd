class_name LevelWaveGroup extends Node3D

@export var group_name:String;
@export var use_group_from_level_wave:bool;

func _ready():
	var parent:Node = self;
	var wave:LevelWave;
	var level:Level;
	while parent != null:
		if parent is LevelWave:
			wave = parent as LevelWave;
		if parent is Level:
			level = parent as Level;
			await wave.wave_started;
			if use_group_from_level_wave:
				put_elements_in_group(level, wave.default_group_name);
			else:
				put_elements_in_group(level, group_name);
			return;
		parent = parent.get_parent();
		
		
		
func put_elements_in_group(level:Level, group:String):
	for child in get_children():
		level.objs.add_to_group_node(child, group);
		print("[LevelWaveGroup] reparented child %s" % [child]);
