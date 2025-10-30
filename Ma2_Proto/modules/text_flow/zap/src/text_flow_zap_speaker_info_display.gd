class_name TextFlowZapSpeakerInfoDisplay extends Control

signal speaker_clicked(speaker:TextFlowZapSpeaker)

@export var _speaker_name_label:Label
@export var _speaker_description_label:Label
@export var _trects_speaker_icons_1:Array[TextureRect]
@export var _trects_speaker_icons_2:Array[TextureRect]

@export var _set_speaker_name_color:bool = true

var _speaker:TextFlowZapSpeaker

func click_speaker():
	speaker_clicked.emit(_speaker)

func set_speaker(speaker:TextFlowZapSpeaker):
	if !speaker:
		hide()
		return
	else:
		show()
		_speaker = speaker
		if _speaker_name_label:
			_speaker_name_label.text = speaker.name
			if _set_speaker_name_color:
				_speaker_name_label.modulate = speaker.color
		if _speaker_description_label:
			_speaker_description_label.text = speaker.description
		for trect in _trects_speaker_icons_1:
			trect.texture = speaker.icon_1
		for trect in _trects_speaker_icons_2:
			trect.texture = speaker.icon_2
