class_name UI_VFX_Animation extends Control

static var ONLY_ONE_INSTANCE_DICTIONARY:Dictionary[StringName, UI_VFX_Animation]

@export var _animation:AnimationPlayer
@export var _allow_only_one_id:StringName = ""

func _ready() -> void:
	if !_allow_only_one_id.is_empty():
		if ONLY_ONE_INSTANCE_DICTIONARY.has(_allow_only_one_id):
			var previous =  ONLY_ONE_INSTANCE_DICTIONARY[_allow_only_one_id]
			if is_instance_valid(previous):
				previous.queue_free()
		ONLY_ONE_INSTANCE_DICTIONARY[_allow_only_one_id] = self

	if Game.instance:
		Game.instance.level_clear.connect(queue_free)
	LevelManager.removing_current_level.connect(queue_free)
	_animation.animation_finished.connect(_on_animation_finished)
	rotation_degrees = randf()*360
	scale = Vector2.ONE * randf_range(0.8,1.5)

func _on_animation_finished(anim_name: StringName):
	queue_free()
	if !_allow_only_one_id.is_empty():
			ONLY_ONE_INSTANCE_DICTIONARY.erase(_allow_only_one_id)
