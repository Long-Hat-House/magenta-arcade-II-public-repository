class_name ChallengePanelBegin extends ChallengePanel

@export var _title:Label
@export var _text:Label

func set_info(info:ChallengeInfo):
	_title.text = info.challenge_begin_title
	_text.text = info.challenge_instruction_text
