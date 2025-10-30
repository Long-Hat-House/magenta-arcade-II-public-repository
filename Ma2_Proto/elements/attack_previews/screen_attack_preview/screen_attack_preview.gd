class_name ScreenAttackPreview extends Node3D

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var label_animation: AnimationPlayer = $After/Label3D/LabelAnimation
@onready var the_aim: Node3DShaker = $TheAim
@onready var after: LookAtCamera = $After

@onready var screen_attack_preview_corner_1: Node3D = $TheAim/LookAtCamera/Previews/Shaker1/ScreenAttackPreviewCorner
@onready var screen_attack_preview_corner_2: Node3D = $TheAim/LookAtCamera/Previews/Shaker2/ScreenAttackPreviewCorner2
@onready var screen_attack_preview_corner_3: Node3D = $TheAim/LookAtCamera/Previews/Shaker3/ScreenAttackPreviewCorner3
@onready var screen_attack_preview_corner_4: Node3D = $TheAim/LookAtCamera/Previews/Shaker4/ScreenAttackPreviewCorner4

@onready var screen_corners:Array[Node3D] = [
	screen_attack_preview_corner_1,
	screen_attack_preview_corner_2,
	screen_attack_preview_corner_3,
	screen_attack_preview_corner_4,
]

@export var _sfx_charging_start:WwiseEvent
@export var _sfx_charging_stop:WwiseEvent
@export var _sfx_charging_rtpc:WwiseRTPC;
@export var _sfx_interrupt:WwiseEvent

var interrupting:bool;
var _playing_sfx:bool = false

func _enter_tree() -> void:
	if not is_node_ready(): await ready;
	after.hide();
	the_aim.hide();

func _exit_tree() -> void:
	_stop_sfx()

func _play_sfx() -> void:
	if _playing_sfx: return
	_playing_sfx = true
	_sfx_charging_start.post(self)

func _stop_sfx(interrupt:bool = false) -> void:
	if !_playing_sfx: return
	_playing_sfx = false
	if interrupt:
		_sfx_interrupt.post(self)
	else:
		_sfx_charging_stop.post(self)

func set_closed(closed:float):
	if !interrupting:
		var was_visible:bool = the_aim.visible;
		var should_be_visible:bool = closed > 0.0 and closed < 1.0
		if not was_visible and should_be_visible:
			_play_sfx()
			for corner in screen_corners:
				if corner.has_method("idle"):
					corner.idle();
		the_aim.visible = should_be_visible;
		_sfx_charging_rtpc.set_value(self, closed)
		animation_tree.set("parameters/blend_position", closed);

		if not should_be_visible:
			_stop_sfx()

func interrupt():
	_stop_sfx(true)
	label_animation.play(&"do");
	after.show();
	interrupting = true;
	hide_aim();
	await label_animation.animation_finished;
	after.hide();
	interrupting = false;

func hide_aim():
	_stop_sfx()
	for corner in screen_corners:
		if corner.has_method("cancel"):
			corner.cancel();
	await get_tree().create_timer(1).timeout;
	the_aim.hide();
