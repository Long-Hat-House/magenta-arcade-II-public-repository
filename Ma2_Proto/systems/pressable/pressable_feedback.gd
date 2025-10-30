class_name PressableFeedback extends Node

const M_PRESSABLE_FEEDBACK = preload("res://elements/ui/pressable/m_pressable_feedback.tres")

@export var mesh_getter:Array[Node3D];
@export var getter_height:int = 4;
@export var cancel_names:Array[String];
@export var needs_call:bool;

@export var random_wait_before_min:float = 1;
@export var random_wait_before_max:float = 2;
@export var only_if_seen:VisibleOnScreenNotifier3D;
@export var effect_tween_delay:float;
@export var effect_tween_delay_random:float;

var meshes:Array[MeshInstance3D];

var effect_value:float:
	get:
		return effect_value;
	set(value):
		effect_value = value;
		#print("[PRESSABLE FEEDBACK] Setting meshes as %s" % [value]);
		for mesh in meshes:
			if is_instance_valid(mesh):
				mesh.set_instance_shader_parameter("InstanceAlpha", value);
		
func _ready():
	for origin in mesh_getter:
		get_meshes(origin);
	
func get_meshes(from:Node3D, height:int = 0):
	for name in cancel_names:
		if from.name.contains(name):
			return;
	
	if height > getter_height: 
		return;
		
	if from is MeshInstance3D:
		if from.material_overlay == null:
			from.material_overlay = M_PRESSABLE_FEEDBACK;
		else:
			from.material_overlay.next_pass = M_PRESSABLE_FEEDBACK;
		
		meshes.push_back(from as MeshInstance3D);
		
	for child in from.get_children():
		if child is Node3D:
			get_meshes(child, height + 1);
	
	
func _enter_tree() -> void:
	
	#print("[PRESSABLE FEEDBACK] Entered tree [%s]" % [Engine.get_physics_frames()]);
	
	if !is_node_ready():
		await ready;
		
	effect_value = 0;
	
	if needs_call:
		return;
		
	if only_if_seen and not only_if_seen.is_on_screen():
		await only_if_seen.screen_entered;
		
	var random_wait:float = randf_range(random_wait_before_min, random_wait_before_max);
	if random_wait > 0.0:
		await get_tree().create_timer(random_wait).timeout;
		
	if self and is_instance_valid(self):
		do_effect();

func do_effect():
	var t := create_tween();
	effect_value = 0;
	#print("[PRESSABLE FEEDBACK] Doing effect with delay %s [%s]" % [effect_tween_delay, Engine.get_physics_frames()]);
	print_stack();
	if (effect_tween_delay + effect_tween_delay_random) > 0:
		t.tween_interval(effect_tween_delay + randf() * effect_tween_delay_random);
	t.tween_property(self, "effect_value", 1.0, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD);
	t.tween_property(self, "effect_value", 0.0, 1.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD);
	
	await t.finished;
