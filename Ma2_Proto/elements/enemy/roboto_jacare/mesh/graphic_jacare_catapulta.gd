class_name Graphic_Jacare extends LHH3D

@onready var lamp_off_01: MeshInstance3D = $rig_jacare_roboto/Skeleton3D/lamp_off_01
@onready var lamp_off_02: MeshInstance3D = $rig_jacare_roboto/Skeleton3D/lamp_off_02
@onready var lamp_off_03: MeshInstance3D = $rig_jacare_roboto/Skeleton3D/lamp_off_03
@onready var lamp_off_04: MeshInstance3D = $rig_jacare_roboto/Skeleton3D/lamp_off_04
@onready var lamp_off_05: MeshInstance3D = $rig_jacare_roboto/Skeleton3D/lamp_off_05
@onready var lamp_off_06: MeshInstance3D = $rig_jacare_roboto/Skeleton3D/lamp_off_06
@onready var lamp_on_01: MeshInstance3D = $rig_jacare_roboto/Skeleton3D/lamp_on_01
@onready var lamp_on_02: MeshInstance3D = $rig_jacare_roboto/Skeleton3D/lamp_on_02
@onready var lamp_on_03: MeshInstance3D = $rig_jacare_roboto/Skeleton3D/lamp_on_03
@onready var lamp_on_04: MeshInstance3D = $rig_jacare_roboto/Skeleton3D/lamp_on_04
@onready var lamp_on_05: MeshInstance3D = $rig_jacare_roboto/Skeleton3D/lamp_on_05
@onready var lamp_on_06: MeshInstance3D = $rig_jacare_roboto/Skeleton3D/lamp_on_06

@export var instantiate_place_right: Node3D
@export var instantiate_place_left: Node3D


@onready var lamps_off:Array[MeshInstance3D] = [
	lamp_off_01,
	lamp_off_02,
	lamp_off_03,
	lamp_off_04,
	lamp_off_05,
	lamp_off_06,
]

@onready var lamps_on:Array[MeshInstance3D] = [
	lamp_on_01,
	lamp_on_02,
	lamp_on_03,
	lamp_on_04,
	lamp_on_05,
	lamp_on_06,
]

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var wheel: AnimationPlayer = $anim
@onready var tree: AnimationTree = $AnimationTree



static var lamps_indexes:Array;

func _ready() -> void:
	if not lamps_indexes or lamps_indexes.size() == 0:
		lamps_indexes = range(mini(lamps_on.size(), lamps_off.size()));

var old_progress:float;
func set_lamp_progress(progress01:float):
	ArrayUtils.percentage_boolean_call_one(lamps_indexes, progress01, old_progress, func(index:int, on:bool):
		index = lamps_on.size() - index - 1;
		lamps_off[index].visible = !on;
		lamps_on[index].visible = on;
		lamps_on[index].scale = Vector3(1,0,1) * 1.25 + Vector3.UP * 1.075;
		lamps_on[index].create_tween().tween_property(lamps_on[index], "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT);
		);
	progress01 = old_progress;

func get_instantiate_place(right:bool)->Node3D:
	return instantiate_place_left if right else instantiate_place_left;

func set_walk(walk:bool):
	tree.walk = walk;

func set_side(right:bool):
	tree.right = right;

func set_attacking(attack:bool):
	tree.attack = attack;

func set_interrupt():
	tree.interrupt = true;
