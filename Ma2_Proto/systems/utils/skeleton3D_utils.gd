class_name Skeleton3DUtils


static func find_bone_contains(skeleton:Skeleton3D, contains:String)->int:
	for bone_idx in range(skeleton.get_bone_count()):
		if skeleton.get_bone_name(bone_idx).contains(contains):
			return bone_idx;
	return -1;

static func find_bone_containsn(skeleton:Skeleton3D, contains:String)->int:
	for bone_idx in range(skeleton.get_bone_count()):
		if skeleton.get_bone_name(bone_idx).containsn(contains):
			return bone_idx;
	return -1;
