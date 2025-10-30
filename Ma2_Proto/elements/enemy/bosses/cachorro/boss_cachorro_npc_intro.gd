class_name Boss_Cachorro_Intro extends LHH3D

@export var img:AnimatedSprite3D;
@onready var notifier: VisibleOnScreenNotifier3D = $Sprite/VisibleOnScreenNotifier3D
@export var velocity:float = 12;
@onready var dialogue: QuickDialogue = $Sprite/QuickDialogue
@onready var dialogue2: QuickDialogue = $Sprite/DialogueHole
@onready var parries:Array[StringName] = [
	&"parry1",
	&"parry2",
]

var tween:Tween;

func _ready() -> void:
	img.play("idle");


var pressed_once:bool;

var pres_tween:Tween;
func set_pressed(pressed:bool):
	var destination:float = -2 if pressed else 0;
	if pressed:
		pressed_once = true;
	if img.position.x != destination:
		if pres_tween and pres_tween.is_valid():
			pres_tween.kill();
		pres_tween = create_tween();
		pres_tween.tween_property(img, "position:x", destination, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO);

var avoid_call:int = 0;
func avoid(_uai:Node3D):
	if img.animation.containsn("parry"):
		return;
	avoid_call += 1;
	var id:int = avoid_call;
	var old_anim:StringName = img.animation;
	var parry_anim:StringName = parries.pick_random();
	img.play(parry_anim);
	await img.animation_looped;
	if img.animation == parry_anim and id == avoid_call:
		img.play(old_anim);

func cmd(lvl:Level, measure_boss:StageMeasure, position_boss_intro_hole:Node3D, position_hole:Node3D, boss:Boss_Cachorro)->Level.CMD:
	return Level.CMD_Sequence.new([
		Level.CMD_Parallel.new([
			Level.CMD_Sequence.new([
				Level.CMD_Wait_Seconds.new(0.25),
				dialogue.cmd_dialogue(true),
				Level.CMD_Wait_Seconds.new(0.125),
				Level.CMD_Await_AsyncCallable.new(func():
					img.play("attack");
					await img.animation_looped;
					await img.animation_looped;
					, img),
			]),
			Level.CMD_Sequence.new([
				Level.CMD_Wait_Callable.new(func(): return pressed_once),
				Level.CMD_Callable.new(func():
					dialogue.stop_dialogue();
					)
			]),
		]),
		Level.CMD_Await_AsyncCallable.new(func():
			tween = create_tween();
			var dist:Vector3 = position_boss_intro_hole.global_position - self.global_position;
			if pressed_once:
				velocity += 3.5;
			tween.tween_property(self, "position", dist.normalized() * 30, 30 / velocity).as_relative().set_trans(Tween.TRANS_LINEAR);
			img.play("run4")
			, img),
		Level.CMD_Wait_Signal.new(notifier.screen_exited),
		Level.CMD_Wait_Seconds.new(0.12),
		Level.CMD_Callable.new(func():
			tween.kill();
			self.reparent(boss.food_parent);
			self.global_position = position_boss_intro_hole.global_position;
			),
		Level.CMD_Branch.new(func(): return !pressed_once,
			Level.CMD_Sequence.new([
				measure_boss.cmd_default_camera_tween(lvl, 0.7),
				Level.CMD_Wait_Seconds.new(0.25),
				dialogue2.cmd_dialogue(true),
				Level.CMD_Wait_Seconds.new(0.25),
			]),
			Level.CMD_Sequence.new([
				measure_boss.cmd_default_camera_tween(lvl, 0.4),
				Level.CMD_Wait_Seconds.new(0.25),
			])),
		Level.CMD_Await_AsyncCallable.new(func():
			img.play("attack");
			await img.animation_looped;
			img.play("run");
			tween = create_tween();
			TransformUtils.tween_jump_global_dynamic(self, tween,
					func(): return position_hole.global_position,
					Vector3.UP * 4,
					0.75);
			tween.tween_callback(func(): 
				self.visible = false
				);
			await tween.finished;
			, self),
		Level.CMD_Callable.new(func():
			self.reparent(boss.get_parent());
			)

	]);
