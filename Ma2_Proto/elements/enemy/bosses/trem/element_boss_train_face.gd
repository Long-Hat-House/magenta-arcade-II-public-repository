class_name Boss_Trem_Face extends LHH3D

@onready var health: Health = $StaticBody3D/Health
@onready var tree: AnimationTree = $AnimationTree
@onready var spawn_area: SpawnArea = $SpawnArea

@onready var rosto: MeshInstance3D = $faceTrain/rosto
@export var overlay_meshes: Array[MeshInstance3D];

@export var on_dead_accessibility_group:StringName = &"neutral";
@export var on_restore_accessibility_group:StringName = &"enemy";
@export var overlay:Material;
var overlay_cache:Material;


@export_range(-1.0, 1.0) var sad_to_angry_initial_value:float;
@export var max_health:float = 6;
@export var sfx_immune_enable:AkEvent3D;
@export var sfx_immune_disable:AkEvent3D;

var sad_to_angry_value:float;
var sad_to_angry_amplitude:float = 0;
var sad_to_angry_frequency:float = 0;
var stunned_value:float;
var stunned_amplitude:float = 0;
var stunned_frequency:float = 0.5;
var opened_value:float;
var opened_amplitude:float = 0.1;
var opened_frequency:float = 0.5;
var anxiety_global_multiplier:float = 1.0;

var sad_tween:Tween;
var opened_tween:Tween;
var stunned_tween:Tween;

@onready var accessibility: AccessibilityHighContrastObject = $FaceHighContrastObject

enum Value
{
	OPENED,
	STUNNED,
	SAD_TO_ANGRY,
}


var count:float;

func _update_values(sad:float, stun:float, open:float):
	tree["parameters/BlendTree/SadToAngry/blend_position"] = signf(sad) * pingpong(sad, 1.0);
	tree["parameters/BlendTree/Stunned/blend_amount"] = pingpong(stun, 1.0);
	tree["parameters/BlendTree/Opened/blend_amount"] = pingpong(open, 1.0);
	
#func change_material_overlay_recursive(to_change:Material, node:Node3D):
	#if node is MeshInstance3D:
		#node.material_overlay = to_change;
		#
	#for child in node.get_children():
		#change_material_overlay_recursive(to_change, child);
	
func _enter_tree() -> void:
	if overlay_cache == null:
		overlay_cache = overlay.duplicate();
	for mesh in overlay_meshes:
		mesh.material_overlay = overlay_cache;
	
func _ready() -> void:
	health.set_max_health(max_health, false);
	sad_to_angry_value = sad_to_angry_initial_value;
	health.currentAmount = 0;
	
	health.dead_parameterless.connect(_on_health_dead);
	health.revived_parameterless.connect(_on_health_revive);
	
	tween_die();
	
func _on_health_dead()->void:
	sfx_immune_enable.post_event();
	accessibility.change_group(on_dead_accessibility_group);
	
	tween_die();
	
	
func _on_health_revive()->void:
	sfx_immune_disable.post_event();
	accessibility.change_group(on_restore_accessibility_group);
	
	tween_revive();
	
func tween_die():
	var t := create_tween();
	
	var t1 := create_tween();
	t1.set_parallel();
	t1.tween_property(overlay_cache, "albedo_color", Color(0.25, 0.25, 0.25, 0.5), 0.125);
	t1.tween_property(overlay_cache, "emission", Color(1, 1, 1, 1), 0.125);
	t1.tween_property(overlay_cache, "emission_energy_multiplier", 5.0, 0.1);
	
	var t2 := create_tween();
	t2.set_parallel();
	t2.tween_property(overlay_cache, "albedo_color", Color(0, 0, 0, 0.70), 0.5);
	t2.tween_property(overlay_cache, "emission", MA2Colors.RED_LIGHT, 0.45);
	t2.tween_property(overlay_cache, "emission_energy_multiplier", 0.0, 1);
	
	t.tween_subtween(t1);
	t.tween_subtween(t2);
	
func tween_revive():
	var t := create_tween();
	
	var t1 := create_tween();
	t1.set_parallel();
	t1.tween_property(overlay_cache, "albedo_color", Color(1, 1, 1, 0.25), 0.25);
	t1.tween_property(overlay_cache, "emission", Color(1, 1, 1, 1), 0.25);
	t1.tween_property(overlay_cache, "emission_energy_multiplier", 0.8, 0.25);
	
	var t2 := create_tween();
	t2.set_parallel();
	t2.tween_property(overlay_cache, "albedo_color", Color(0, 0, 0, 0), 0.45).set_ease(Tween.EASE_IN);
	t2.tween_property(overlay_cache, "emission", Color(1, 1, 1, 1), 0.1);
	t2.tween_property(overlay_cache, "emission_energy_multiplier", 0.0, 0.35);
	
	t.tween_interval(0.4 + randf() * 0.5);
	t.tween_subtween(t1);
	t.tween_subtween(t2);
	
	
func _process(delta:float) -> void:
	_update_values(
		sad_to_angry_value + _get_wave(count, sad_to_angry_amplitude, sad_to_angry_frequency),
		stunned_value + _get_wave(count, stunned_amplitude, stunned_frequency),
		opened_value + _get_wave(count, opened_amplitude, opened_frequency)
		);
	count += delta * anxiety_global_multiplier;
	
func _get_wave(t:float, amplitude:float, frequency:float):
	return sin(t * PI * 2 * frequency) * amplitude;
	
func kill_tween(tween:Tween):
	if tween and tween.is_valid():
		tween.kill();	
	
func set_value(value:Value, amount:float, amplitude:float, frequency:float, duration:float, delay:float = 0.0):
	var prefix:String;
	var t:Tween;
	match value:
		Value.OPENED:
			prefix = "opened_";
			kill_tween(opened_tween);
			opened_tween = create_tween();
			t = opened_tween;
		Value.STUNNED:
			prefix = "stunned_";
			kill_tween(stunned_tween);
			stunned_tween = create_tween();
			t = stunned_tween;
		Value.SAD_TO_ANGRY:
			prefix = "sad_to_angry_";
			kill_tween(sad_tween);
			sad_tween = create_tween();
			t = sad_tween;
			
	t.set_parallel();
	t.tween_property(self, prefix + "value", amount, duration).set_delay(delay);
	t.tween_property(self, prefix + "frequency", frequency, duration).set_delay(delay);
	t.tween_property(self, prefix + "amplitude", amplitude, duration).set_delay(delay);
	return t;
	

func restore():
	health.restore();
	
func get_health():
	return health;
	
func explode():
	spawn_area.do_spawn_default();
