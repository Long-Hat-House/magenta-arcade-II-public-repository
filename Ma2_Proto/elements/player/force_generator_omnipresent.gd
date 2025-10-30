class_name ForceGenerator_OmniPresent extends ForceGenerator

@export var force_percentage:float = 0;
@export var direction:Vector3 = Vector3.FORWARD;

func _ready() -> void:
	direction = direction.normalized();

func get_force_now(to:Node3D)->Vector3:
	return FORCE_MAX * force_percentage * direction;
