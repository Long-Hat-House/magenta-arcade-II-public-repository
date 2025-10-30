class_name FinalLaser extends Node3D

const FinalLaserMesh = preload("res://elements/enemy/projectiles/final_laser/final_laser_mesh.gd")

@onready var path: Path3D = $Path3D
@onready var laser_mesh:FinalLaserMesh = $LaserMesh
@onready var light: OmniLight3D = $LightNode/OmniLight3D
@onready var ball_mesh_follow: MeshInstance3D = $Path3D/PathFollow_Graphic/BallMeshFollow

@export var sfx_charge:AkEvent3DLoop;
@export var sfx_on:AkEvent3DLoop;

@export var length:float = 30;
@export var squig_amplitude = 3;
@export var squig_sub_amplitude = 1.5;
var amplitude:float = 0:
	set(value):
		squiggly_value.emit(inverse_lerp(0, squig_amplitude, value));
		amplitude = value;
	get:
		return amplitude;
@export var length_frequency_multiplier:float = 2;
@export var frequency:float = 0.5;
var sub_amplitude:float = 0;
@export var sub_frequency:float = 4;

signal set_laser(on:bool);
signal squiggly_value(value:float);

@export var damage:PathFollow3D;
@export var copies_of_damage:int = 4;

var keep_changing_path:bool;
var followers:Array[PathFollow3D];
@export var followers_graphic:Array[PathFollow3D];

var t:float;

enum Mode
{
	NONE,
	PRE,
	ON
}

func set_mode(mode:Mode):
	match mode:
		Mode.NONE:
			ball_mesh_follow.visible = false;
			set_laser.emit(false);
			sfx_charge.stop_loop();
			sfx_on.stop_loop();
			laser_mesh.make_laser_width(0);
			laser_mesh.make_laser_layer_width(0);
			set_colliding(false);
			keep_changing_path = false;
			light.visible = false;
		Mode.PRE:
			ball_mesh_follow.visible = false;
			set_laser.emit(false);
			sfx_charge.start_loop();
			sfx_on.stop_loop();
			laser_mesh.make_laser_layer_width(0);
			laser_mesh.make_laser_width(0.5);
			set_colliding(false);
			light.visible = false;
			keep_changing_path = true;
		Mode.ON:
			ball_mesh_follow.visible = true;
			set_laser.emit(true);
			#sfx_charge.stop_loop(); ##Needs to not stop loop or else it will bug it out
			sfx_on.start_loop();
			HUD.instance.make_screen_effect(HUD.ScreenEffect.ShortFlash);
			laser_mesh.make_laser_layer_width(1, 0.24);
			laser_mesh.make_laser_width(1, 0.08);
			set_colliding(true);
			light.visible = true;
			keep_changing_path = true;
			
func set_squiggly(on:bool, time:float):
	var t:= create_tween();
	t.set_parallel();
	t.tween_property(self, "amplitude", squig_amplitude if on else 0.0, time);
	t.tween_property(self, "sub_amplitude", squig_sub_amplitude if on else 0.0, time * 0.5);
	
	
func make_squiggly_treat(intensity01:float, time:float, percentage_in:float = 0.25):
	var percentage_out:float = 1.0 - percentage_in;
	var t:= create_tween();
	t.set_parallel();
	t.tween_property(self, "amplitude", squig_amplitude * intensity01, time * percentage_in).set_ease(Tween.EASE_IN);
	t.tween_property(self, "sub_amplitude", squig_sub_amplitude * intensity01, time * 0.125);
	t.chain().tween_property(self, "amplitude", 0.0, time * percentage_out).set_ease(Tween.EASE_OUT);
	t.tween_property(self, "sub_amplitude", 0.0, time * 3).set_ease(Tween.EASE_OUT);
	
	
func set_colliding(colliding:bool):
	for follower in followers:
		for child in follower.get_children():
			if child is DamageArea:
				(child as DamageArea).enabled = colliding;

func _ready():
	followers = [damage];
	set_mode(Mode.NONE);

func _process(delta: float) -> void:
	if !keep_changing_path:
		return;
	
	t += delta * frequency;
	path.curve.set_point_position(0, Vector3.ZERO);
	path.curve.set_point_out(0, Vector3.BACK);
	
	for i in range(1, path.curve.point_count):
		var where:float = (float(i) / path.curve.point_count) * length;
		path.curve.set_point_position(i, get_point_pos(t, where));
		var dir:Vector3 = get_point_dir(t, where, true).normalized();
		path.curve.set_point_in(i, -dir);
		path.curve.set_point_out(i, dir);
		
	for follower in followers_graphic:
		follower.progress_ratio += delta * 3;
		

func _physics_process(delta: float) -> void:
	for follower in followers:
		follower.progress_ratio += delta * 4;

func get_point_pos(curve:float, where_in_curve:float)->Vector3:
	return Vector3(sin(curve + where_in_curve * length_frequency_multiplier) * amplitude, 0, where_in_curve) +\
	 		sub_amplitude * Vector3(sin((curve + where_in_curve) * sub_frequency), cos((curve + where_in_curve * 2) * sub_frequency) * 0.25, cos((curve + where_in_curve) * sub_frequency)) * 0.25;

func get_point_dir(curve:float, where_in_curve:float, positive:bool)->Vector3:
	return Vector3(cos(curve + where_in_curve * length_frequency_multiplier) * amplitude, 0, where_in_curve if positive else -where_in_curve) +\
	 		sub_amplitude * Vector3(cos((curve + where_in_curve) * sub_frequency), sin((curve + where_in_curve * 2) * sub_frequency) * 0.25, sin((curve + where_in_curve) * sub_frequency)) * 0.25;
