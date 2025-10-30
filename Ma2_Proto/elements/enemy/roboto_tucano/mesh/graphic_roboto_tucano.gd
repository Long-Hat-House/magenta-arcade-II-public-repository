class_name Graphic_Tucano extends LHH3D

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var skel: Skeleton3D = $rig_tucano/Skeleton3D
@onready var rotater: Node3D = $rig_tucano/Skeleton3D/robo/Rotater

var angle:float;
@export var angle_velocity:float = 360;
@export var angle_search:float = 15;
@export var search_change_time:float = 0.45;
@export var tween_speed_scale:bool = true;
var is_negative:bool;
var count_change:float;

func _enter_tree() -> void:
	if not is_node_ready(): 
		await ready;
	if tween_speed_scale:
		anim.speed_scale = 2;
		var t:= create_tween();
		t.tween_property(anim,"speed_scale", 0.0, 1.1).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD);
		
func set_speed_scale(value:float):
	anim.speed_scale = value;

func _process(delta: float) -> void:
	var target_angle; 
	if Player.instance.currentTouches.size() > 0:
		var origin:Vector3 = rotater.global_position;
		var target:Vector3 = Player.instance.get_closest_position(origin);
		target_angle = self.global_basis.z.signed_angle_to(target - origin, Vector3.UP);
	else:
		count_change -= delta;
		while count_change < 0.0:
			count_change += search_change_time;
			is_negative = not is_negative;
		target_angle = -deg_to_rad(angle_search) if is_negative else deg_to_rad(angle_search);
	
	angle = move_toward(angle, target_angle, delta * deg_to_rad(angle_velocity));
	rotater.basis = Basis.IDENTITY.rotated(Vector3.UP, -angle);
	skel.set_bone_pose_rotation(3, rotater.basis.get_rotation_quaternion());
