class_name AltarTweenable extends Altar

@onready var npc_graphic_regular: Graphic_NPC = $Body/NPC_Graphic_Regular
@export var npc_velocity_to_animation_multiplier = 10;

@export var queue_free_on_out_of_screen:bool;



var _old_pos:Vector3;
func _process(delta: float) -> void:
	var pos:Vector3 = body.global_position;
	_update_animation((pos - _old_pos).length())
	_old_pos = pos;

func _ready():
	npc_graphic_regular.play_animation(npc_graphic_regular.anim_walk);

func _update_animation(velocity_frame:float):
	npc_graphic_regular.speed_scale = 0.5 + 0.5 * velocity_frame * npc_velocity_to_animation_multiplier;


func tween_distance(tween:Tween, distance:Vector3, velocity:float)->Tweener:
	return create_tween().tween_property(body, "position", distance, distance.length() / velocity).as_relative();

func keep_moving(direction:Vector3, velocity:float, distance_loop:float = 50.0, trans:Tween.TransitionType = Tween.TRANS_LINEAR, ease:Tween.EaseType = Tween.EASE_IN_OUT)->Tween:
	var t:= create_tween();
	t.tween_property(body, "position", direction.normalized() * distance_loop, distance_loop / velocity).as_relative().set_trans(trans).set_ease(ease);
	t.set_loops(-1);
	return t;

enum Style
{
	DIRECT,
	PING_PONG,
}

func tween_path(path:Path3D, velocity:float, style:Style = Style.DIRECT, trans:Tween.TransitionType = Tween.TRANS_LINEAR, ease:Tween.EaseType = Tween.EASE_IN_OUT)->Tween:
	var t := create_tween();

	var len:float = path.curve.get_baked_length();
	var duration:float = len / velocity;

	var go_thorugh_path := func go_through_path(offset:float):
		body.global_transform = path.global_transform * path.curve.sample_baked_with_rotation(offset, true);

	match style:
		Style.DIRECT:
			t.tween_method(go_thorugh_path, 0.0, len, duration).set_ease(ease).set_trans(trans);
		Style.PING_PONG:
			t.tween_method(go_thorugh_path, 0.0, len, duration).set_ease(ease).set_trans(trans);
			t.tween_method(go_thorugh_path, len, 0.0, duration).set_ease(ease).set_trans(trans);
	return t;


static var visible_altars:Array[Altar] = []

func _on_visible_on_screen_notifier_3d_screen_entered() -> void:
	visible_altars.append(self);

func _on_visible_on_screen_notifier_3d_screen_exited() -> void:
	visible_altars.erase(self);
	if queue_free_on_out_of_screen:
		queue_free();

static func get_altars_by_id(id:StringName)->Array[Altar]:
	var altars:Array[Altar];
	altars.assign(visible_altars.filter(func(altar):
		if is_instance_valid(altar):
			#print("ALTAR %s id is %s, searching for %s" % [altar, altar.id, id]);
			return id.nocasecmp_to(altar.id) == 0;
		else:
			return false;
		));
	return altars;

static func close_all_altars_with_id(id:StringName):
	for altar in visible_altars:
		if is_instance_valid(altar):
			if(id.nocasecmp_to(altar.id) == 0):
				altar.close(0)
	var altars:Array[Altar];

static func get_random_unopened_altar()->Altar:
	return visible_altars.filter(func(altar:Altar): return altar.is_opened).pick_random() as Altar;


static func get_random_unopened_altars(amount:int)->Array[Altar]:
	var new_arr = visible_altars.filter(func(altar:Altar): return altar.is_opened).duplicate(false);
	new_arr.shuffle();
	var eita:Array[Altar];
	eita.assign( new_arr.slice(0, amount));
	return eita;
