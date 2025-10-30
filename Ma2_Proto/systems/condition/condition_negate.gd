class_name Condition_Negate extends Condition

@export var instruction:String = "If condition is null, will search in children"
@export var condition:Condition;

func _ready() -> void:
	if !condition:
		for child in get_children():
			if child is Condition:
				condition = child;
				return;

func is_condition()-> bool:
	if condition:
		return not condition.is_condition();
	else:
		push_error("No condition in negate %s child of %s" % [self, get_parent()])
		return false;
