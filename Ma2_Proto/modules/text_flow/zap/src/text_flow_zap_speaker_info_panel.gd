class_name TextFlowZapSpeakerInfoPanel extends Panel

@export var speaker_info_display:TextFlowZapSpeakerInfoDisplay

@export var _animator:Switch_Oning_Offing_AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	gui_input.connect(_on_input_event)

func _on_input_event(input:InputEvent):
	if InputUtils.is_input_basic_touch(input):
		_animator.set_switch(false)

func show_speaker(speaker:TextFlowZapSpeaker):
	if !speaker: return
	speaker_info_display.set_speaker(speaker)
	_animator.set_switch(true)
