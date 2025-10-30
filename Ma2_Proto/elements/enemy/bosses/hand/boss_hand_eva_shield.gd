class_name Element_EvaShield extends StaticBody3D

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var tree: AnimationTree = $AnimationTree
@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var enable_sfx:AkEvent3D = $EnableSFX;
@onready var disable_sfx:AkEvent3D = $DisableSFX;
@onready var reflect_sfx: AkEvent3D = $ReflectSFX;

@export var min_transparency:float = 0.0;
@export var max_transparency:float = 1.0;
@export var hit_color:Color = MA2Colors.BUTTON_ICON;
@export var damage_color:Color = MA2Colors.RED_LIGHT;


var default_color:Color;
var tween:Tween;

func set_on(on:bool, sound:bool = true):
	tree.on = on;
	collision.disabled = !on;
	if sound:
		if on:
			enable_sfx.post_event();
		else:
			disable_sfx.post_event()

func _ready() -> void:
	var defcol = mesh.get_instance_shader_parameter("Light2");
	if defcol:
		default_color = defcol; 
	mesh.set_instance_shader_parameter("Transparency", min_transparency);

func _on_area_entered(area: Area3D) -> void:
	try_hit();

func _on_body_entered(body: Node3D) -> void:
	try_hit();

func _on_health_hit_parameterless() -> void:
	try_hit();

func _on_health_try_damage_parameterless() -> void:
	try_hit();

func try_hit():
	if tween and tween.is_valid():
		tween.kill();
		
	reflect_sfx.post_event();

	tween = create_tween();
	mesh.set_instance_shader_parameter("Transparency", max_transparency);
	mesh.set_instance_shader_parameter("Light2", hit_color);
	tween.tween_property(mesh, "instance_shader_parameters/Light2", default_color, 0.25).set_ease(Tween.EASE_IN);
	tween.tween_property(mesh, "instance_shader_parameters/Transparency", min_transparency, 2.0).set_ease(Tween.EASE_IN_OUT);


func _on_damage_area_on_damaged() -> void:
	if tween and tween.is_valid():
		tween.kill();

	tween = create_tween();
	mesh.set_instance_shader_parameter("Transparency", 1.0);
	mesh.set_instance_shader_parameter("Light2", damage_color);
	tween.tween_property(mesh, "instance_shader_parameters/Light2", Color(1.0, 0.0, 0.0, 0.0), 0.50).set_ease(Tween.EASE_IN);
	tween.tween_property(mesh, "instance_shader_parameters/Transparency", 0.0, 2.0).set_ease(Tween.EASE_IN_OUT);
