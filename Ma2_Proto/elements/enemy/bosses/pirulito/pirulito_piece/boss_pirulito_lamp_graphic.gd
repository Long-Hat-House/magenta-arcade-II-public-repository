extends Node3D

@onready var anim_emission: AnimationPlayer = $anim_emission

func set_on(on:bool):
	if on:
		anim_emission.play(&"emission");
		await anim_emission.animation_finished;
		anim_emission.play(&"on");
	else:
		anim_emission.play(&"off");
