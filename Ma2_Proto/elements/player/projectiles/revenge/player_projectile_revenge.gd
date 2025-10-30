extends Node3D

@onready var to_increase: Node3D = $ToIncrease
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var shape: MeshInstance3D = $Shape

@export var duration:float = 1.0

static var in_use:int = 0;

func _enter_tree() -> void:
	in_use += 1;
	
	if self.is_node_ready():
		start();
		
func _exit_tree() -> void:
	in_use -= 1;
	
func _ready() -> void:
	if in_use > 0:
		shape.mesh = shape.mesh.duplicate();
	start();
	
func start():
	var t := create_tween();
	
	
	to_increase.scale = Vector3.ONE * 0.001;
	var appearence_tween := create_tween();
	appearence_tween.set_parallel();
	appearence_tween.tween_property(shape, "rotation:y", PI * 2 * 8, duration).as_relative().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC);
	appearence_tween.tween_property(to_increase, "scale", Vector3.ONE * 20, duration)\
			.set_ease(Tween.EASE_OUT)\
			.set_trans(Tween.TRANS_QUART);
	t.tween_subtween(appearence_tween);
	t.tween_callback(self.queue_free);
	
	anim.speed_scale = 1.0 / duration;
	anim.play(&"explode");
