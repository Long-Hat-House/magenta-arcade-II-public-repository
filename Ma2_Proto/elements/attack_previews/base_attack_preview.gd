class_name Attack_Preview extends LHH3D

@export var full_increase_time_begin:float = 0.8;
@export var full_increase_time_end:float = 0.225;
@export var size:float = 10;

@onready var border:Sprite3D = %Border
@onready var expander:Sprite3D = %Expander


var _percentage:float;
var _count_increase:float;

func _ready():
	border.pixel_size = size / border.texture.get_width();
	expander.pixel_size = border.pixel_size;
	border.modulate.a = 0;
	expander.modulate.a = 0;

func _process(delta:float):
	if border.modulate.a > 0:
		expander.scale = Vector3(_count_increase, _count_increase, _count_increase);
		expander.modulate.a = min(1.0 - _count_increase, border.modulate.a);
		var full_increase_time:float = lerp(full_increase_time_begin, full_increase_time_end, _percentage);
		_count_increase += delta / full_increase_time;
		while _count_increase > 1 : _count_increase -= 1;
	else:
		expander.modulate.a = 0;
		
func warn(duration:float):
	var t:= create_tween();
	#t.tween_property(border, "modulate:a", 1.0, duration * 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC);
	#t.tween_property(border, "modulate:a", 0.0, duration * 0.75).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC);
	t.tween_method(set_preview_closeness, 0.0, 1.0, duration * 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC);
	t.tween_method(set_preview_closeness, 1.0, 0.5, duration * 0.85).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC);
func set_preview_closeness(percentage01:float):
	_percentage = smoothstep(0.35, 1.0, percentage01);
	border.modulate.a = _percentage; ##Use to be set through this, now the .a is set through warn()
