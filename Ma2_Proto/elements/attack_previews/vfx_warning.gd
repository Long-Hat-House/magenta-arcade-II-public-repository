extends Node3D

@onready var anim:AnimationPlayer = $AnimationPlayer;
@onready var animation_tree: AnimationTree = $AnimationTree
@export var final_animations:Array[StringName];

@export var time_to_finish:float = 3;

func _ready() -> void:
	animation_tree.animation_started.connect(_on_animation_started);
	
func _on_animation_started(anim:StringName):
	if animation_tree.is_on == false:
		for final_animation in final_animations:
			if anim == final_animation:
				get_tree().create_timer(1).timeout.connect(queue_free, CONNECT_ONE_SHOT);

func _enter_tree() -> void:
	if !self.is_node_ready(): await ready;
	
	animation_tree.is_on = true;
	if time_to_finish != 0:
		await get_tree().create_timer(time_to_finish).timeout;
		if is_instance_valid(self):
			finish();
			
func _exit_tree() -> void:
	finish();

func finish() -> void:
	animation_tree.is_on = false;
