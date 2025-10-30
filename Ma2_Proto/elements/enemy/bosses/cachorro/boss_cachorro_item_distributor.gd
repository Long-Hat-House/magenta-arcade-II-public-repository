class_name Boss_Cachorro_Item_Distributor extends Node

@export var items_parent:Node3D;
@export var food_scene:PackedScene;
@export var height_item:float = 0.5;
@export var min_radius:float = 10;
@export var max_radius:float = 14;

signal item_fell(item:Node3D)
signal item_destroyed;
signal all_items_fell;

@onready var objects_scenes:Array[PackedScene] = [
	Level_Cmd_Utils.HOLD_BLUE,
	Level_Cmd_Utils.HOLD_YELLOW,
	Level_Cmd_Utils.HOLD_GREEN,
	Level_Cmd_Utils.HOLD_RED,
	
	Level_Cmd_Utils.TAP_BLUE,
	Level_Cmd_Utils.TAP_BLUE,
	Level_Cmd_Utils.TAP_RED,
	Level_Cmd_Utils.TAP_YELLOW,
	Level_Cmd_Utils.TAP_GREEN,
	
	Level_Cmd_Utils.HOLD_FIRE_RATE,
	Level_Cmd_Utils.HOLD_FIRE_RATE,
	Level_Cmd_Utils.HOLD_FIRE_RATE,
	Level_Cmd_Utils.HOLD_FIRE_RATE,
	Level_Cmd_Utils.HOLD_WARMUP,
	Level_Cmd_Utils.HOLD_WARMUP,
	Level_Cmd_Utils.HOLD_WARMUP,
	Level_Cmd_Utils.HOLD_WARMUP,
	Level_Cmd_Utils.HOLD_LVLUP,
	Level_Cmd_Utils.HOLD_LVLUP,
]

var after_scenes:Array[PackedScene] = [
	Level_Cmd_Utils.HOLD_FIRE_RATE,
	Level_Cmd_Utils.HOLD_FIRE_RATE,
	Level_Cmd_Utils.HOLD_WARMUP,
	Level_Cmd_Utils.HOLD_WARMUP,
	Level_Cmd_Utils.HOLD_LVLUP,
	Level_Cmd_Utils.HOLD_LVLUP,
	Level_Cmd_Utils.HOLD_LVLUP,
	
]
var tmp_scenes:Array[PackedScene] = [];

var standby:Array = [];
var items_total:int;

func shuffle():
	objects_scenes.shuffle();
	standby.resize(objects_scenes.size() + 1);
	
func has_food_in_plate()->bool:
	#print("[DOG ITEM DISTRIBUTOR] has %s children (%s) %s" % [
		#get_amount_items_on_plate(),
		#items_parent.get_children().any(func(element:Node): return is_instance_valid(element)),
		#items_parent.get_children().map(func(x:Node3D): return "%s%spos:%s" % [x.name, 
				#" (%s) " % x.scale.length() if !x.scale.is_equal_approx(Vector3.ONE) else " ",
				#x.global_position - items_parent.global_position]),
	#]);
	return items_parent.get_children().any(func(element:Node): return is_instance_valid(element))
	
func get_amount_items_on_plate()->int:
	return items_parent.get_children().reduce(func(number:int, element:Node):
		if is_instance_valid(element):
			return number + 1;
		else:
			return number;
		, 0);
	
func get_items_total()->int:
	if items_total == 0:
		items_total = objects_scenes.size();
	return items_total;

func add_items(powerups:int):
	##instantiate things
	#insert_in_random_place(standby, make_food());
	#powerups = mini(powerups, objects_scenes.size());
	while powerups > 0:
		var scene:PackedScene;
		if objects_scenes.size() > 0:
			scene = objects_scenes.pop_back();
		else:
			if tmp_scenes.is_empty():
				tmp_scenes = after_scenes.duplicate();
				tmp_scenes.shuffle();
			scene = tmp_scenes.pop_back();
		var instance:Node = scene.instantiate();
		if instance.has_method("protect_against_leaving_screen"):
			instance.protect_against_leaving_screen();
		insert_in_random_place(standby, instance);
		powerups -= 1;
	
	fall_plate_routine(standby);


var fall_id:int;
func fall_plate_routine(from:Array):
	fall_id += 1;
	var id:int = fall_id;
	var len:int = from.size();
	var big_tween:Tween = create_tween();
	for i:int in range(len):
		if from[i] is Node3D:
			var element:Node3D = from[i];
			from[i] = "used"; ## mark as used already
			
			_set_random_position(element, i, len);
			items_parent.add_child(element);
			
			element.global_basis = element.global_basis.orthonormalized();
			element.position.y = height_item;
			
			element.tree_exited.connect(func():
				item_destroyed.emit();
				from[i] = null;
				, CONNECT_ONE_SHOT);
				
			var t := create_tween();
			TransformUtils.tween_fall(element, t, 0.85, 0.65, Vector3.UP * 25, "position");
			t.tween_callback(item_fell.emit.bind(element));
			big_tween.tween_subtween(t);
			
	big_tween.tween_callback(all_items_fell.emit);
		

func insert_in_random_place(possible:Array, elem:Node3D):
	var rand:int = randi_range(0, possible.size() - 1)
	var initial_rand:int = rand;
	while (possible[rand] is String) or (is_instance_valid(possible[rand])):
		rand = (rand + 1) % possible.size();
		if rand == initial_rand:
			LogUtils.log_error("[Boss distributor] Found no space for %s!" % elem)
			return;
	possible[rand] = elem;

			
func _set_random_position(elem:Node3D, index:int, len:int):
	var t:float = PI * 2.0 * (float(index + randf_range(0.25, 0.75))/(len+1.0));
	elem.position = Vector3(sin(t), 0, cos(t)) * randf_range(min_radius, max_radius);
	elem.basis = Basis.looking_at(-elem.position);

func make_food()->Node3D:
	return food_scene.instantiate();
