class_name CameraShaker extends Node3D

static var shakers:Array[CameraShaker] = [];
static var constant_value:Dictionary[StringName, Vector3] = {};
@export var camera_transform:Node3D;

func get_camera_quaternion()->Quaternion:
	if camera_transform:
		return camera_transform.global_basis.get_rotation_quaternion().inverse();
	else:
		return self.global_basis.get_rotation_quaternion().inverse();

var tween:Tween;
var current_force:Vector3;

func _enter_tree() -> void:
	shakers.push_back(self);

func _exit_tree() -> void:
	shakers.erase(self);

func _process(delta: float) -> void:
	self.position = VectorUtils.rand_vector3_range_vector(current_force + _get_constant_shake());

static func screen_shake(data:CameraShakeData):
	for shaker in shakers:
		shaker.shake(data);

static func change_constant_shake(id:StringName, value:Vector3):
	constant_value[id] = value;

static func remove_constant_shake(id:StringName)->bool:
	return constant_value.erase(id);

static func _get_constant_shake()->Vector3:
	return constant_value.values().reduce(func(accum:Vector3, now:Vector3): return accum + now, Vector3.ZERO);

func shake(data:CameraShakeData):
	var st := _get_strength(data);

	if tween and tween.is_running():
		tween.kill();
	tween = create_tween();

	tween.tween_property(self, "current_force", st, data.durationIn).set_ease(data.easeIn).set_trans(data.transIn);
	tween.tween_property(self, "current_force", Vector3.ZERO, data.durationOut).set_ease(data.easeOut).set_trans(data.transOut);


func _get_strength(data:CameraShakeData)->Vector3:
	if data == null:
		LogUtils.log_warning("Tried to shake but can't without data!", true);
		return Vector3.ZERO;
	else:
		return data.absolute_strength + get_camera_quaternion() * data.rotated_strength;
