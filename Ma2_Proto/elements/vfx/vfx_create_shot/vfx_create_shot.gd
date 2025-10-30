extends Node3D

@onready var mesh: MeshInstance3D = $MeshInstance3D

@export var height:float = 0.1;
@export var in_duration:float = 0.015;
@export var out_duration:float = 0.175;

@export var attached_to_screen:bool;

func _physics_process(delta: float) -> void:
	if attached_to_screen:
		position += LevelCameraController.instance.last_physics_step_movement;

func _enter_tree() -> void:
	if !is_node_ready():
		await ready;
	mesh.scale = Vector3.ONE * 0.9;
	mesh.position.y = height;
	var t := create_tween();
	t.tween_property(mesh, "scale", Vector3.ONE * 1, in_duration).set_ease(Tween.EASE_OUT);
	t.tween_property(mesh, "scale", Vector3.ONE * 0.01, out_duration).set_ease(Tween.EASE_IN);
	create_tween().tween_property(mesh, "position", Vector3.ZERO, in_duration + out_duration);
	t.tween_callback(ObjectPool.repool.bind(self));
