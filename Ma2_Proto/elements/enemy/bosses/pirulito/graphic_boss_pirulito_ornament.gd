class_name Graphic_Boss_Pirulito_Ornament extends LHH3D

@onready var anim: AnimationPlayer = $AnimationPlayer

var open:bool;

func set_open():
	if not open:
		open = true;
		anim.play(&"opening");
		await anim.animation_finished;
		anim.play(&"opened");
