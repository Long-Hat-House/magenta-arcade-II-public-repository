class_name Graphic_Brawny extends LHH3D


@onready var skelL:Skeleton3D = $Rig_ArmL/Skeleton3D
@onready var skelR:Skeleton3D = $Rig_ArmR/Skeleton3D
@onready var skelLID:int = Skeleton3DUtils.find_bone_containsn(skelL, "bone");
@onready var skelRID:int = Skeleton3DUtils.find_bone_containsn(skelR, "bone");
@onready var cannon_1:BoneAttachment3D = $Rig_ArmL/Skeleton3D/Cannon1
@onready var cannon_2:BoneAttachment3D = $Rig_ArmL/Skeleton3D/Cannon2
@onready var cannon_3:BoneAttachment3D = $Rig_ArmL/Skeleton3D/Cannon3
@onready var cannon_4:BoneAttachment3D = $Rig_ArmR/Skeleton3D/Cannon4
@onready var cannon_5:BoneAttachment3D = $Rig_ArmR/Skeleton3D/Cannon5
@onready var cannon_6:BoneAttachment3D = $Rig_ArmR/Skeleton3D/Cannon6
@onready var shootAnimation:AnimationPlayer = $AnimationPlayer

var minOpening:float = 0;
var maxOpening:float = 0.45;

func get_head()->Node3D:
	return $Rig_Brawny as Node3D;

func set_arms_opened(ratio01:float):
	var opening:float = lerp(minOpening,maxOpening, ratio01);
	var rotL:Quaternion = Quaternion(0, -opening, 0, 1);
	var rotR:Quaternion = Quaternion(0, opening, 0, 1);
	#print("setting arms opened %s: %s (%s) and %s (%s)" % [ratio01, skelL, is_instance_valid(skelL), skelR, is_instance_valid(skelR)]);
	if skelL and is_instance_valid(skelL):
		skelL.set_bone_pose_rotation(skelLID, rotL);
	if skelR and is_instance_valid(skelR):
		skelR.set_bone_pose_rotation(skelRID, rotR);

func attach_to_cannon_slot(node:Node3D, whichCannon:int):
	var cannon:Node3D = _get_cannon_node(whichCannon);
	if node.get_parent():
		node.get_parent().remove_child(node);
	cannon.add_child(node);
	node.position = Vector3.ZERO;



func _get_cannon_node(whichCannon:int)->BoneAttachment3D:
	match whichCannon:
		0:
			return cannon_1;
		1:
			return cannon_2;
		2:
			return cannon_3;
		3:
			return cannon_4;
		4:
			return cannon_5;
		5:
			return cannon_6;
	return null;

enum AnimPhase
{
	Pre,
	Shoot,
	Post,
	Idle,
	PostFall,
	CloseFace,
	Stop,
	Dead
}

func get_animator()->AnimationPlayer:
	return shootAnimation;

func set_animation(phase:AnimPhase):
	match phase:
		AnimPhase.Pre:
			shootAnimation.play("BRAWNY_PRE_SHOOT");
		AnimPhase.Shoot:
			shootAnimation.play("BRAWNY_SHOOT");
		AnimPhase.Post:
			shootAnimation.play("BRAWNY_POS_SHOOT");
		AnimPhase.Idle:
			shootAnimation.play("BRAWNY_IDLE");
		AnimPhase.PostFall:
			shootAnimation.play("BRAWNY_POS_FALL");
		AnimPhase.CloseFace:
			shootAnimation.play("BRAWNY_CLOSE_FACE");
		AnimPhase.Stop:
			shootAnimation.play("BRAWNY_STOP");
		AnimPhase.Dead:
			shootAnimation.play("BRAWNY_DEAD");
