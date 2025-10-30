class_name TargetValue extends Resource

@export var value:float = 1;
@export var up_velocity:float = 1;
@export var down_velocity:float = 1;

func _init(value:float = 0.0) -> void:
	self.value = value;

func _go(value:float, velocity:float, delta:float) -> float:
	return value + velocity * delta;

func target_value(value_now:float, delta:float) -> float:
	if value > value_now:
		return min(_go(value_now, up_velocity, delta), value);
	elif value < value_now:
		return max(_go(value_now, -down_velocity, delta), value);
	return value_now;
	
func _to_string() -> String:
	return str(value);
