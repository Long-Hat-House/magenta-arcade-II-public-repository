class_name Graphic_Bomb extends LHH3D
@onready var anim:AnimationPlayer = $AnimationPlayer as AnimationPlayer

func land():
	anim.play("land");
	await anim.animation_finished;

func pre_jump():
	anim.play("jump_pre");
	await anim.animation_finished;

func jump():
	anim.play("jump");
	await anim.animation_finished;
	anim.play("jump_LOOP")

func idle():
	anim.play("idle");
