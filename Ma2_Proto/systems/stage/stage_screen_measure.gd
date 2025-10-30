@tool
class_name StageMeasure extends Node3D

@onready var top: MeshInstance3D = $Top
@onready var right: MeshInstance3D = $Right
@onready var bottom: MeshInstance3D = $Bottom
@onready var left: MeshInstance3D = $Left
@onready var label: Label3D = $Label3D

var old_rect:Rect2;

enum Pivot {
	Center,
	Top,
}

@export_category("Mounting the measure (as a tool)")
@export var rect:Rect2 = Rect2(0, 0, 9.5, 25);
@export var pivot:Pivot;
@export var amount_top_bigger:float = 1.4;

@export_category("Moving the camera (when used)")
@export var default_movement:CameraMovementData = CameraMovementData.DefaultData;

func cmd_set_pivot_to_this(lvl:Level)->Level.CMD:
	return Level.CMD_Callable.new(func():
		lvl.stage.set_pivot_offset_to_exactly_node(self);
		)

func cmd_default_camera_tween(lvl:Level, wait_multiplier:float = 0.0, fixed_duration:float = -1, set_pivot:bool = true)->Level.CMD:
	if default_movement == null:
		default_movement = CameraMovementData.DefaultData; ##default parameters

	return default_movement.cmd_camera_tween(lvl, self, wait_multiplier, fixed_duration, set_pivot);

func do_camera_tween(lvl:Level, wait_multiplier:float = 0.0, fixed_duration:float = -1, set_pivot:bool = true):
	if default_movement == null:
		default_movement = CameraMovementData.DefaultData; ##default parameters

	await default_movement.do_cmd_camera_tween(lvl, self, wait_multiplier, fixed_duration, set_pivot);

func _ready() -> void:
	if not Engine.is_editor_hint():
		visible = false;
		if get_child_count() > 4:
			push_warning("StageScreenMeasure '%s' has children. If they are meant to be seen, they will be invisible!" % self.name)

	var group = get_tree().get_nodes_in_group(get_groups()[0]);
	label.text = str(group.find(self, 0));


func _process(delta: float) -> void:
	if rect != old_rect:
		old_rect = rect;
		var newR:Rect2 = Rect2(rect);
		match pivot:
			Pivot.Center:
				newR.position = - newR.size * 0.5;
			Pivot.Top:
				newR.position.x -= newR.size.x * 0.5;
				newR.position.y -= newR.size.y;

		top.scale.x = newR.size.x * amount_top_bigger;
		bottom.scale.x = newR.size.x;

		var top_right:Vector3 = top.position + Vector3.RIGHT * top.scale.x * 0.5;
		var top_left:Vector3 = top.position - Vector3.RIGHT * top.scale.x * 0.5;
		var bottom_right:Vector3 = bottom.position + Vector3.RIGHT * bottom.scale.x * 0.5;
		var bottom_left:Vector3 = bottom.position - Vector3.RIGHT * bottom.scale.x * 0.5;

		right.scale.z = (top_right - bottom_right).length();
		left.scale.z = (top_left - bottom_left).length();

		top.position.z = -newR.end.y + 0.5;
		bottom.position.z = -newR.position.y + 0.5
		right.position = top_right.lerp(bottom_right, 0.5);
		left.position = top_left.lerp(bottom_left, 0.5);
		right.rotation.y = Vector3.FORWARD.signed_angle_to(top_right - bottom_right, Vector3.UP);
		left.rotation.y = Vector3.FORWARD.signed_angle_to(top_left - bottom_left, Vector3.UP);

		label.position = 0.25 * (top.position + bottom.position + right.position + left.position)

func _get_configuration_warnings() -> PackedStringArray:
	if get_child_count() > 4:
		return ["Children will be invisible on play!"]
	else:
		return [];
