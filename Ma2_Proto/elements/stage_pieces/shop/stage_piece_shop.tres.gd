class_name LevelShopStagePiece extends LevelStagePiece

const WEAPON_HOLD_TOUCH_ONLY = preload("res://elements/player/weapons/weapon_hold_touch_only.tscn")

enum LineStyle{
	Start,
	BuyOne,
	BuyAny,
	Sacrifice
	}

const LINE_TITLES:Dictionary[LineStyle, StringName] = {
	LineStyle.Start: &"shop_start",
	LineStyle.BuyOne: &"shop_buy_one",
	LineStyle.BuyAny: &"",
	LineStyle.Sacrifice: &"shop_sacrifice",
}

signal shop_finished

static var current_arcade_shop_stage: int = 0

static func arcade_shop_clear():
	current_arcade_shop_stage = 0

@export var objs_container:Node3D
@export var position_to_return:float = -40

@export var mat_to_move:StandardMaterial3D
@export var mat_to_move_speed_multiplier:float = 1

@export var animation:AnimationPlayer

@export var line_title_scene:PackedScene
@export var altar_scene:PackedScene

@export var speed:float = 20
@export var test_objs:Array[ShopObjectInfo]

@export var altars_appear_delay:Curve

@export var sacrifice_line:Array[ShopObjectInfo]
@export var repeated_sacrifices_setup:Array[int];
@export var second_sacrifices_text:Array[String];

var _objs_to_move:Array[Node3D]
var _altars_array:Array[GenericAltar]

var _sacrifice_index:int = 0;

signal extra_sacrifice;

func start_shop() -> void:
	for child in objs_container.get_children():
		if child is Node3D:
			_objs_to_move.append(child)

	await get_tree().process_frame

	var lines:Dictionary[LineStyle,Array]

	var what_to_happen_after_end:Callable = finish;
	var lvl_info = LevelManager.current_level_info
	if lvl_info:
		if !lvl_info.is_arcade_mode || current_arcade_shop_stage <= 0:
			Player.instance.add_weapon(WEAPON_HOLD_TOUCH_ONLY.instantiate())
			if lvl_info.buy_start.size() > 0: lines[LineStyle.Start] = lvl_info.buy_start
			if lvl_info.buy_one.size() > 0: lines[LineStyle.BuyOne] = lvl_info.buy_one
			if lvl_info.buy_as_many.size() > 0: lines[LineStyle.BuyAny] = lvl_info.buy_as_many
		else: #Is Arcade Mode AND stage > 0
			lines[LineStyle.Sacrifice] = sacrifice_line
			what_to_happen_after_end = do_all_sacrifices_and_finish;

		if lvl_info.is_arcade_mode and _sacrifice_index == 0: ##If is arcade mode and the first sacrifice
			current_arcade_shop_stage += 1

	if test_objs.size() > 0: lines[LineStyle.BuyAny] = test_objs

	LevelEnvironment.set_animation_speed_scale(0)

	if lines.size() <= 0 || Ma2MetaManager.get_coins_all_time_amount() == 0:
		finish()
		return

	AudioManager.post_music_event(AK.EVENTS.MUSIC_SHOP_START)
	ScoreManager.instance.set_in_shop_mode(true)

	_make_altars(lines, true, what_to_happen_after_end);


func do_all_sacrifices_and_finish():
	while _sacrifice_index < repeated_sacrifices_setup[current_arcade_shop_stage - 1]: ## -1 because it sums when it encounters the stage
		_sacrifice_index += 1;
		await _clear_altars();
		await get_tree().create_timer(1).timeout;
		if second_sacrifices_text.size() > 0:
			for child:Node in get_children():
				if child is ShopTextTitle:
					child.set_title(second_sacrifices_text[clampi(_sacrifice_index - 1, 0, second_sacrifices_text.size() - 1)])
					break;
		await _make_altars({LineStyle.Sacrifice : sacrifice_line}, false, extra_sacrifice.emit)
		await extra_sacrifice;
		HUD.instance.make_screen_effect(HUD.ScreenEffect.ShortFlash)
	finish();

func finish() -> void:
	LevelEnvironment.set_animation_speed_scale(1)
	HUD.instance.make_screen_effect(HUD.ScreenEffect.ShortFlash)
	animation.play("stop")
	AudioManager.post_music_event(AK.EVENTS.MUSIC_SHOP_END)
	shop_finished.emit()
	await _clear_altars();
	ScoreManager.instance.set_in_shop_mode(false)
	
func _old_finish() -> void:
	LevelEnvironment.set_animation_speed_scale(1)
	HUD.instance.make_screen_effect(HUD.ScreenEffect.ShortFlash)
	animation.play("stop")
	AudioManager.post_music_event(AK.EVENTS.MUSIC_SHOP_END)
	shop_finished.emit()
	var i:float = 0
	for altar in _altars_array:
		await get_tree().create_timer(altars_appear_delay.sample(i/float(_altars_array.size()))).timeout
		if is_instance_valid(altar):
			altar.finish_altar()
	ScoreManager.instance.set_in_shop_mode(false)
	
func _make_altars(new_lines:Dictionary[LineStyle,Array], also_titles:bool, finish_callable:Callable):
	var z_height:float = 14
	var z_desired_dist:float = 8
	var n_distances:int = new_lines.size()-1
	var z_dist:float = min(z_height / n_distances, z_desired_dist)
	z_height = n_distances*z_dist
	var z = -10
	for line_style in new_lines:
		var objs = new_lines[line_style]
		_add_altars_line(line_style, objs, z, also_titles, finish_callable)
		z -= z_dist

	var i:float
	for altar in _altars_array:
		await get_tree().create_timer(altars_appear_delay.sample(i/float(_altars_array.size()))).timeout
		if is_instance_valid(altar):
			altar.start_altar()
			i+=1
	
func _clear_altars():
	var i:float = 0;
	for altar in _altars_array:
		await get_tree().create_timer(altars_appear_delay.sample(i/float(_altars_array.size()))).timeout
		if is_instance_valid(altar):
			altar.finish_altar()
	_altars_array.clear();

func _destroy_altars():
	var i:int = 0;
	for altar in _altars_array:
		await get_tree().create_timer(altars_appear_delay.sample(i/float(_altars_array.size()))).timeout
		if is_instance_valid(altar):
			altar.destroy_altar()
	_altars_array.clear();
	

func _add_altars_line(style:LineStyle, objs:Array[ShopObjectInfo], z_position:float, make_title:bool, finish_behavior:Callable):
	var position:Vector3 = Vector3(0,0,z_position)
	var has_finish_behavior:bool = style in [LineStyle.Start, LineStyle.Sacrifice]
	var finish_line:bool = style in [LineStyle.BuyOne]
	if make_title:
		var title:StringName = LINE_TITLES[style]
		var title_obj = line_title_scene.instantiate() as ShopTextTitle
		title_obj.position = position
		title_obj.set_title(title)
		add_child(title_obj)

	position.z += 3

	if objs.size() <= 0: return
	elif objs.size() == 1: _add_altar_with_obj(objs[0], position, finish_behavior if has_finish_behavior else Callable())
	else:
		var x_width:float = 7
		var x_desired_dist:float = 5
		var n_distances:int = objs.size()-1
		var x_dist:float = min(x_width / n_distances, x_desired_dist)
		x_width = n_distances*x_dist
		position.x = -x_width/2

		var previous_altar:GenericAltar
		for info in objs:
			var new_altar = _add_altar_with_obj(info, position, finish_behavior if has_finish_behavior else Callable())
			if is_instance_valid(previous_altar) && finish_line:
				previous_altar.connect_altar(new_altar)
			previous_altar = new_altar
			position.x += x_dist

func _add_altar_with_obj(obj_info:ShopObjectInfo, pos:Vector3, finish_behaviour:Callable) -> GenericAltar:
	var altar:GenericAltar = altar_scene.instantiate() as GenericAltar
	var obj = obj_info.object_scene.instantiate()

	altar.position = pos

	if finish_behaviour.is_valid():
		altar.obj_hold_finished.connect(finish_behaviour)

	if obj is Holdable:
		obj.set_cost(obj_info.object_cost)

	altar.add_obj(obj)
	add_child(altar)
	_altars_array.append(altar)
	return altar

func _process(delta: float) -> void:
	var dist:float = speed * delta

	if mat_to_move:
		mat_to_move.uv1_offset.z += dist * mat_to_move_speed_multiplier

	for obj in _objs_to_move:
		obj.position.z += dist
		if obj.position.z >= 0:
			obj.position.z = position_to_return
