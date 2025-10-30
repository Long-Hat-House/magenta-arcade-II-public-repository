class_name Graphic_LaserRoboto extends LHH3D

@onready var skeleton_3d:Skeleton3D = %Skeleton3D;
@onready var neckId = skeleton_3d.find_bone("LaserCannon");
@onready var cannonId = skeleton_3d.find_bone("Cannon");
@onready var cannon_attachment:BoneAttachment3D = $Rig_LaserCannon/Skeleton3D/CannonAttachment
@onready var laser_pivot = $"Rig_LaserCannon/Skeleton3D/CannonAttachment/Laser Pivot"
@onready var walkAnim:AnimationPlayer = %AnimationPlayer2;
@onready var shootAnim:AnimationPlayer = %AnimationPlayer;

var velocityMultiplier := 1.0;

func direct_neck(dir:Vector3):
	var quat:Quaternion = Quaternion(Vector3.FORWARD, dir);
	skeleton_3d.set_bone_pose_rotation(neckId, quat);

func get_cannon_point()->Node3D:
	return laser_pivot;

func set_walking(velocity:float)->void:
	walkAnim.play("laserRobotoBelt", -1, velocityMultiplier * velocity)

enum ShootPhase
{
	Pre,
	Shoot,
	Post,
	Idle,
}

func set_shooting(phase:ShootPhase):
	match phase:
		ShootPhase.Pre:
			shootAnim.play("LASER_ROBOTO_PRE_SHOOTER");
		ShootPhase.Shoot:
			shootAnim.play("LASER_ROBOTO_SHOOTER");
		ShootPhase.Post:
			shootAnim.play("LASER_ROBOTO_POS_SHOOTER");
		ShootPhase.Idle:
			shootAnim.play("RESET");
