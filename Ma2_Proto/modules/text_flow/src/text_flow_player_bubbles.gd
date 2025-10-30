class_name TextFlowPlayerBubbles
extends TextFlowPlayer

@export var _basic_bubble_scene:PackedScene

var _current_bubble:TextFlowBubble

func kill_flow(emit:bool = true):
	if is_instance_valid(_current_bubble): _current_bubble.finish()
	super.kill_flow(emit)

func _line_start() -> bool:
	if _current_cmd_param.is_empty(): return false
	var speaker = get_current_speaker()
	if !is_instance_valid(speaker): return false

	#finish whatever bubble we were already playing and for some reason haven't finished.
	if is_instance_valid(_current_bubble): _current_bubble.finish()

	_current_bubble = _basic_bubble_scene.instantiate() as TextFlowBubble

	if speaker is TextFlowBubbleSpeaker:
		_current_bubble.bubble_speaker = speaker

		if !is_instance_valid(speaker.followee): return false

	elif speaker is Node3D:
		push_error("This is not supported anymore, as there's no way to set a voice!")
		var new_speaker = TextFlowBubbleSpeaker.new()
		new_speaker.followee = speaker
		_current_bubble.bubble_speaker = new_speaker

	_current_bubble.text = _current_cmd_param

	add_child(_current_bubble)
	_current_bubble.start()

	return super._line_start()

func _line_process(delta) -> bool:
	return is_instance_valid(_current_bubble) && super._line_process(delta)

func _line_finish():
	if is_instance_valid(_current_bubble): _current_bubble.finish()
	super._line_finish()
