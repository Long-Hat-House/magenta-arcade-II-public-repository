class_name TextFlowZapGroupInfoPanel extends Panel

signal speaker_clicked(speaker:TextFlowZapSpeaker)

@export var _speaker_info_display:PackedScene
@export var _speakers_container:Control

@export var _close_button:Button
@export var _animator:Switch_Oning_Offing_AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	_close_button.pressed.connect(close)
	for child in _speakers_container.get_children(): child.queue_free()

func close():
	_animator.set_switch(false)

func open():
	_animator.set_switch(true)

func add_speaker(speaker:TextFlowZapSpeaker):
	var spk = _speaker_info_display.instantiate() as TextFlowZapSpeakerInfoDisplay
	assert(spk, "A valid scene is necessary")

	_speakers_container.add_child(spk)
	spk.set_speaker(speaker)
	spk.speaker_clicked.connect(on_speaker_display_clicked)

func on_speaker_display_clicked(speaker:TextFlowZapSpeaker):
	speaker_clicked.emit(speaker)
