class_name Graphic_RobotoCopter extends LHH3D

@onready var skel:Skeleton3D = $Rig_Robotocopter/Skeleton3D as Skeleton3D;

@export var helixVelocity:float = 1000;

var helixId:int;
var baseId:int;
var helixRot:float;

func _ready():
	#print("HELLO %s and %s" % [self, skel]);
	helixId = Skeleton3DUtils.find_bone_containsn(skel, "helix");
	baseId = Skeleton3DUtils.find_bone_containsn(skel, "base");

func _process(delta:float):
	helixRot += deg_to_rad(helixVelocity) * delta;
	var quat = Quaternion.from_euler(Vector3.UP * helixRot)
	skel.set_bone_pose_rotation(helixId, quat);

func set_tilt(tilt:Vector3):
	var quat = Quaternion(Vector3.DOWN, tilt);
	skel.set_bone_pose_rotation(baseId, quat.normalized());
