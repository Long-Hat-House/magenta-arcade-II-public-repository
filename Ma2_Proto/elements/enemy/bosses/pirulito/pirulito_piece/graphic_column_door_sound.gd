extends Node3D

@onready var aim_position: Node3D = $"sound/aim Position"
@onready var anim: AnimationPlayer = $AnimationPlayer
var readied:bool = false;

func _ready() -> void:
	readied = true;

func set_open(on:bool) -> void:
	if on:
		anim.play("opening");
		await anim.animation_finished;
		anim.play("open");
	else:
		anim.play("closed");
		
func get_aim_position() -> Node3D:
	return aim_position;
