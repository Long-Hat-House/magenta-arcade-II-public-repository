class_name SimpleSkeletonNodeFollow extends Node

@export var copied_to_copier:Dictionary[Node3D, Node3D];

enum Style
{
	None,
	NormalProcess,
	PhysicsProcess,
}
@export var style:Style = Style.PhysicsProcess;

func _process(delta: float) -> void:
	if style == Style.NormalProcess:
		_copy_all();
		
func _physics_process(delta: float) -> void:
	if style == Style.PhysicsProcess:
		_copy_all();

func _copy_all():
	for copied in copied_to_copier.keys():
		if is_instance_valid(copied):
			var copier := copied_to_copier[copied];
			copier.global_transform = copied.global_transform;
