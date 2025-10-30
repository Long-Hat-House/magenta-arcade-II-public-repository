class_name ChildrenInCircleMoving extends ChildrenInCircle

@export var velocity_degrees:float;
@export var velocity_physics_degrees:float;


func _process(delta: float) -> void:
	if velocity_degrees != 0:
		walk_elements(delta * deg_to_rad(velocity_degrees));
		
func _physics_process(delta: float) -> void:
	if velocity_physics_degrees != 0:
		walk_elements(delta * deg_to_rad(velocity_physics_degrees));
