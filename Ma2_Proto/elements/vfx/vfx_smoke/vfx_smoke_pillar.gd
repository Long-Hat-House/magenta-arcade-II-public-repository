class_name VFX_Smoke_Pillar extends Node3D

@onready var foreground: AnimatedSprite3D = $LookAtCameraParentY/Foreground
@onready var background: AnimatedSprite3D = $LookAtCameraParentY/Background


@export var color_fg:Color = Color.WHITE;
@export var color_bg:Color = Color.SLATE_GRAY;

signal started;
signal began_ending;
signal finished;
signal start_loop;

func _ready() -> void:
	foreground.modulate = color_fg;
	background.modulate = color_bg;

	background.play(&"off")
	foreground.play(&"off")

func start():
	if background.animation == &"offing" or background.animation == &"off":
		started.emit();
		play(foreground, &"oning", &"on", func():
			start_loop.emit();
			)
		await get_tree().create_timer(0.25).timeout;
		play(background, &"oning", &"on");


func play(anim:AnimatedSprite3D, pre:StringName, loop:StringName, on_finished:Callable = Callable()):
	anim.play(pre);
	await anim.animation_looped;
	anim.play(loop);
	if on_finished.is_valid():
		on_finished.call();

func end():
	if background.animation == &"oning" or background.animation == &"on":
		began_ending.emit();

		play(foreground, &"offing", &"off", func():
			start_loop.emit();
			)
		await get_tree().create_timer(0.25).timeout;
		await play(background, &"offing", &"off");
		finished.emit();
