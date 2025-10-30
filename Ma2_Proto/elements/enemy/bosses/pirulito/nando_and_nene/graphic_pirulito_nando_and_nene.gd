class_name Graphic_Boss_Pirulito_NandoENene extends LHH3D 

@onready var anim: AnimatedSprite3D = %AnimatedSprite3D

var animation:AnimatedSprite3D:
	get:
		return anim;

var last_random:int = 0;

@export_category("Sprite Animation")
@export var animation_intro_idle:StringName = &"intro_idle";
@export var animation_intro_speak:StringName = &"intro_speak";
@export var animation_losing_idle:StringName = &"losing_idle";
@export var animation_1_idle:StringName = &"part_1_idle";
@export var animation_1_open_idle:StringName = &"part_1_open_idle";
@export var animation_1_open_speak:StringName = &"part_1_open_speak";
@export var animation_1_open_hurt:Array[StringName] = [
		&"part_1_open_hurt1",
		&"part_1_open_hurt2",
		&"part_1_open_hurt3",
		&"part_1_open_hurt4"
		];
@export var animation_2_idle:StringName = &"part_2_idle";
@export var animation_2_hurt:Array[StringName] = [
	&"part_2_hurt1",
	&"part_2_hurt2",
	&"part_2_hurt3",
	&"part_2_hurt4",
	];
@export var animation_finish:StringName = &"lost_idle";
@export var position_bubble:Node3D;

var stack:Array[StringName] = [];

func add_stack(animation_string_or_array)->void:
	print("[nando] adding %s" % [animation_string_or_array]);
	stack.push_back(animation_string_or_array);
	_check_stack();
	
func remove_stack()->void:
	print("[nando] popping %s" % [stack.back()]);
	stack.pop_back();
	_check_stack();
	
func erase_stack(animation_string_or_array)->void:
	print("[nando] erasing %s" % [animation_string_or_array]);
	stack.erase(animation_string_or_array);
	_check_stack();
	
func clear_stack()->void:
	stack.clear();
	
func _check_stack():
	if stack.size() > 0:
		play(stack.back(), false);
	
func finish():
	add_stack(animation_finish);
	_check_stack();

var last_id:int = 0;
func play(animation_string_or_array, check_stack_after:bool = true)->void:
	if not animation_string_or_array:
		return;
	last_id += 1;
	var id:int = last_id;
	if animation_string_or_array is StringName:
		animation.play(animation_string_or_array);
	elif animation_string_or_array is Array[StringName]:
		var arr := animation_string_or_array as Array[StringName];
		last_random += 1;
		animation.play(arr[last_random % arr.size()]);
	if check_stack_after:
		await AwaitUtils.any([animation.animation_finished, animation.animation_looped]);
		if id != last_id:
			return; ## not this call
		if get_tree():
			_check_stack();
