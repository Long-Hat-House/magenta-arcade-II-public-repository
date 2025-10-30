class_name FloatValue extends Resource

@export var value:float = 0:
	set(v):
		value = v;
	get:
		return value * _get_value(multiply, 1.0) + _get_value(add, 0.0);

@export var multiply:FloatValue;
@export var add:FloatValue;

static func _get_value(fv:FloatValue, default:float)->float:
	if fv:
		return fv.value;
	else:
		return default;
