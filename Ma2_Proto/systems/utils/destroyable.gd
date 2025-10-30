class_name Destroyable extends Node

signal destruction_starting()
signal destruction_ending()
signal destruction_ended()

@export var on_end_queue_free:bool = true
@export var animation_id:StringName = &"destroy"
@export var player:AnimationPlayer
@export var screen_shake:CameraShakeData;

@export_category("Destroyable Audio")
@export var _sfx_destroy:WwiseEvent

var _is_being_destroyed:bool
var _interrupting:bool

func _ready() -> void:
	player.animation_finished.connect(_on_animation_finished)

func destroy(_param1 = null, _param2 = null) -> void:
	if _is_being_destroyed:
		return
	_is_being_destroyed = true
	destruction_starting.emit()

	if _interrupting:
		_interrupting = false
		_is_being_destroyed = false
		return

	if _sfx_destroy:
		_sfx_destroy.post(self)
	player.play(animation_id)
	if screen_shake:
		screen_shake.screen_shake();

func _on_animation_finished(animation_name:StringName):
	if !_is_being_destroyed || animation_name != self.animation_id:
		return

	if _interrupting:
		_interrupting = false
		_is_being_destroyed = false
		return

	destruction_ending.emit()

	if _interrupting:
		_interrupting = false
		_is_being_destroyed = false
		return

	if on_end_queue_free:
		queue_free()

	destruction_ended.emit()

func interrupt() -> void:
	if _is_being_destroyed:
		_interrupting = true
