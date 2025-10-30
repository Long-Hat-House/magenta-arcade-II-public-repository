@tool
class_name Boss_Ivo_Graphic_Tree
extends AnimationTree

@export var gaveta:float;
@export_range(0, 1) var porta_inferior:float;
@export_range(0, 1) var porta_superior:float;

func _process(delta: float) -> void:
	set("parameters/BlendTree/gaveta/blend_amount", gaveta);
	set("parameters/BlendTree/porta_inf/blend_amount", porta_inferior);
	set("parameters/BlendTree/porta_sup/blend_amount", porta_superior);
	pass;
