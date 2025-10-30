@tool extends AnimationTree

@export_range(-0.1, 1.1) var punch:float = 0;
@export var touching:bool;
@export var attack:bool;
@export_range(0.0, 1.0) var two_fingers:float;

signal tapped;
signal hold_state_change(is_holding:bool);

func _ready() -> void:
	punch = 0;
	touching = false;
	
func is_holding()->bool:
	return punch < 0.1 and touching == false and attack == false;

var was_holding:bool;

func _process(delta: float) -> void:
	set("parameters/IdlePunch/IdlePunchBlend/blend_amount", punch);
	set("parameters/IdlePunch/DoisDedos/blend_amount", two_fingers);

	var hold:bool = is_holding();
	if hold != was_holding:
		hold_state_change.emit(is_holding);
		was_holding = hold;
