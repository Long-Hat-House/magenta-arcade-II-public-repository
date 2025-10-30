class_name Boss_Cachorro_Turing_Sidekick extends LHH3D

@onready var cachorro_sprite: AnimatedSprite3D = $"Cachorro Sprite"


signal pulled;
signal ate;

func _ready() -> void:
	idle();

func _do_animation(pre:StringName, loop:StringName, evt:Signal = Signal()):
	cachorro_sprite.play(pre);
	await cachorro_sprite.animation_looped;
	if not evt.is_null():
		evt.emit();
	cachorro_sprite.play(loop);


func start_pull():
	await _do_animation("pre_pull", "pull", pulled);

func eat():
	await _do_animation("pre_vulnerable", "vulnerable_loop", Signal());
	await cachorro_sprite.animation_looped;
	ate.emit();

func idle():
	cachorro_sprite.play("idle");

func run_forward():
	cachorro_sprite.play("run4");

func run_up():
	cachorro_sprite.play("run_");

func start_attack():
	cachorro_sprite.play("attack");
	pass;

func finish_attack():
	pass;

func death(new_parent:Node3D):
	reparent(new_parent);
	var t:= create_tween();
	cachorro_sprite.play("defeat");
	cachorro_sprite.animation_looped.connect(func():
		cachorro_sprite.play("defeat_frame")
		, CONNECT_ONE_SHOT)
	t.tween_property(self, "global_position", Vector3.UP * 1.5, 2).as_relative().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC);
	t.tween_interval(1);
	t.tween_property(self, "global_position", Vector3.RIGHT * 20, 5).as_relative().set_trans(Tween.TRANS_LINEAR);
	pass;
