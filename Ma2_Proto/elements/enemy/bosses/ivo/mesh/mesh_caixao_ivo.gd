class_name Boss_Ivo_Graphic extends LHH3D

@onready var tree: Boss_Ivo_Graphic_Tree = $AnimationTree

signal door_superior_closed;
signal door_superior_opened;
signal door_inferior_opened;
signal door_inferior_closed;

class Bump:
	var value:float;

var bump_arr_sup:Array[Bump];
var bump_arr_inf:Array[Bump];

@export var instantiate_place_sup:Node3D;
@export var instantiate_place_inf:Node3D;
@export var limit_opened:float = 0.05;


var door_sup:float:
	get:
		return tree.porta_superior;
	set(value):
		if _is_opened(tree.porta_superior) and !_is_opened(value):
			door_superior_closed.emit();
		elif not _is_opened(tree.porta_superior) and _is_opened(value):
			door_superior_opened.emit();
		tree.porta_superior = value;
		
var door_inf:float:
	get:
		return tree.porta_inferior;
	set(value):
		if _is_opened(tree.porta_inferior) and !_is_opened(value):
			door_inferior_closed.emit();
		elif not _is_opened(tree.porta_inferior) and _is_opened(value):
			door_inferior_opened.emit();
		tree.porta_inferior = value;
		
func bump(sup:bool, val_in:float, ease_in:Tween.EaseType, trans_in:Tween.TransitionType, duration_in:float, ease_out:Tween.EaseType, trans_out:Tween.TransitionType, duration_out:float, val_out:float = 0):
	var b:Bump = Bump.new();
	
	if sup:
		bump_arr_sup.append(b);
	else:
		bump_arr_inf.append(b);
		
	var t := create_tween();
	var set_value = func(value:float):
		b.value = value;
		
	t.tween_method(set_value, 0.0, val_in, duration_in).set_ease(ease_in).set_trans(trans_in);
	t.tween_method(set_value, val_in, val_out, duration_out).set_ease(ease_out).set_trans(trans_out);
	
	if sup:
		t.tween_callback(func():
			bump_arr_sup.erase(b);
			);
	else:
		t.tween_callback(func():
			bump_arr_inf.erase(b);
			);

func _sum(v1:float, v2:float) -> float:
	return v1 + v2;
	
func _transform(v1:Bump)-> float:
	return v1.value;

func _process(delta: float) -> void:
	door_sup = bump_arr_sup.map(_transform).reduce(_sum, 0.0);
	door_inf = bump_arr_inf.map(_transform).reduce(_sum, 0.0);
	
	var sup_closed:bool = _is_closed(door_sup);
	var inf_closed:bool = _is_closed(door_inf);

func _is_closed(value:float)-> bool:
	return value < limit_opened;

func _is_opened(value:float)->bool:
	return value > limit_opened;
