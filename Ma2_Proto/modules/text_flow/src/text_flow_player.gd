class_name TextFlowPlayer extends Control

signal flow_started
signal flow_finished
signal flow_killed

static var GLOBAL_SPEAKERS:Dictionary
static func SET_GLOBAL_SPEAKER(value, speaker_id:StringName):
	GLOBAL_SPEAKERS[speaker_id] = value
static func GET_GLOBAL_SPEAKER(speaker_id:StringName):
	return GLOBAL_SPEAKERS[speaker_id]
static func CLEAR_GLOBAL_SPEAKERS():
	GLOBAL_SPEAKERS.clear()

enum FlowCMD {
	None,
	Dialogue,
	Timer,
	Delay,
	Speaker
	}

var _speakers:Dictionary
var _default_duration_min:float = 1
var _default_duration_max:float = 2

var _current_speaker_id:StringName
var _current_duration_min:float = 1
var _current_duration_max:float = 2
var _current_rng:float

var _playing:bool
var _loop:bool
var _cmds:PackedStringArray
var _current_cmd_index:int
var _current_cmd:FlowCMD
var _current_cmd_param:String
var _cmd_execution_timer:float

var _text_flow_id:StringName

var _tags:String

var _skip:bool

var _queue:Array[Callable]

func skip():
	_cmd_execution_timer = 0
	_skip = true

func _ready():
	set_process(false)

func _process(delta):
	if _current_cmd_index >= _cmds.size() || DevManager.get_shortcut_just_pressed(DevManager.ShortcutCommand.SkipCutscene):
		finish_flow()

	#we start the next command until one needs to be executing, or ID is empty
	while _current_cmd_index < _cmds.size() && ((_current_cmd == FlowCMD.None) || !_cmd_process(delta)):
		if _current_cmd != FlowCMD.None: #if it's not the first command, finishes previous, index ++, treats finishing
			_cmd_finish()
			_current_cmd_index += 1
			if _current_cmd_index >= _cmds.size():
				if _loop: #restarts
					_current_cmd = FlowCMD.None
					_current_cmd_index = 0
				elif _queue.size() > 0:
					var next:Callable = _queue.pop_front()
					next.call()
					continue
				else: #finishes
					finish_flow()
				break #avoids infinite loop if we send a loop that nevers need processing
		if _cmd_start(): #start cmd, if needs execution, we break for the next frame, otherwise
			break


func set_speaker(value, speaker_id:StringName = ""):
	_speakers[speaker_id] = value

func get_speaker(speaker_id:StringName):
	if _speakers.has(speaker_id):
		return _speakers[speaker_id]
	elif GLOBAL_SPEAKERS.has(speaker_id):
		return GET_GLOBAL_SPEAKER(speaker_id)

	if _speakers.size() > 0:
		return _speakers.values()[0]

	return GLOBAL_SPEAKERS.values()[0]

func get_current_speaker():
	return get_speaker(get_current_speaker_id())

func get_current_speaker_id() -> StringName:
	return _current_speaker_id

func set_current_speaker(speaker_id:StringName):
	_current_speaker_id = speaker_id

func is_playing() -> bool: return _playing

func kill_flow(emit_killed:bool = true):
	_playing = false
	set_process(_playing)
	flow_killed.emit()

func finish_flow(emit_killed:bool = true):
	kill_flow(false)
	flow_finished.emit()

func queue_flow(text_flow_id:StringName, loop:bool = false, start_skipping:bool = false, emit_started:bool = true, tags:String = ""):
	var new_call:Callable = start_flow.bind(text_flow_id,loop,start_skipping,emit_started,tags)
	if !_playing:
		new_call.call()
	else:
		_queue.push_back(new_call)

func start_flow(text_flow_id:StringName, loop:bool = false, start_skipping:bool = false, emit_started:bool = true, tags:String = ""):
	_skip = start_skipping
	_text_flow_id = text_flow_id
	if tags.is_empty():
		_tags = TranslationServer.get_translation_object("tags").get_message(_text_flow_id)
	else:
		_tags = tags

	var text_flow = \
		TranslationServer.get_translation_object("pre").get_message(_text_flow_id) \
		+ tr(text_flow_id) \
		+ TranslationServer.get_translation_object("pos").get_message(_text_flow_id)

	if _playing: kill_flow()
	if text_flow.is_empty(): return
	_playing = true
	set_process(_playing)
	flow_started.emit()

	_current_duration_min = _default_duration_min
	_current_duration_max = _default_duration_max

	_cmds = text_flow.split(">>", false)
	_current_cmd_index = 0
	_current_cmd = FlowCMD.None
	_loop = loop

## returns true if needs executing
func _cmd_start() -> bool:
	var cmd = _cmds[_current_cmd_index].strip_edges()

	if cmd.is_empty(): return false

	var first = cmd.get_slice("=", 0).strip_edges()

	match first:
		"S":
			_current_cmd = FlowCMD.Speaker
			var split = cmd.split("=", false)
			_current_speaker_id = split[1].strip_edges()
			return false
		"D": #delay
			_current_cmd = FlowCMD.Delay
			if _skip: return false
			var split = cmd.split("=", false)
			var sub_split = split[1].split(",", false)
			if sub_split.size() == 1:
				var val = sub_split[0].strip_edges()
				if val == "#":
					_current_duration_min = _default_duration_min
					_current_duration_max = _default_duration_max
				else:
					_current_duration_min = val.to_float()
					_current_duration_max = _current_duration_min
			if sub_split.size() == 2:
				_current_duration_min = sub_split[0].strip_edges().to_float()
				_current_duration_max = sub_split[1].strip_edges().to_float()
			return false
		"T":
			_current_cmd = FlowCMD.Timer
			if _skip: return false
			var split = cmd.split("=", false)
			var sub_split = split[1].split(",", false)
			if sub_split.size() == 1:
				_cmd_execution_timer = sub_split[0].strip_edges().to_float()
			if sub_split.size() == 2:
				_cmd_execution_timer = randf_range(sub_split[0].strip_edges().to_float(), sub_split[0].strip_edges().to_float())
			return true
		"RNG", "CONTINUE":
			var total_sum:float = 0
			var split = cmd.split("->", false)
			if first == "RNG": #randomize _current_rng
				total_sum = 0
				for i in range(1, split.size()):
					total_sum += split[i].split(">", false)[0].strip_edges().to_float()
				_current_rng = randf_range(0.0, total_sum)
			#for both commands, choose next line
			total_sum = 0
			for i in range(1, split.size()):
				var sub_split = split[i].split(">", false)
				total_sum += sub_split[0].strip_edges().to_float()
				if total_sum >= _current_rng:
					return _prepare_dialogue_cmd(sub_split[1])
		_:
			return _prepare_dialogue_cmd(cmd)

	return false

func _prepare_dialogue_cmd(text:String) -> bool:
	_current_cmd = FlowCMD.Dialogue
	text = text.strip_edges()
	if text.is_empty(): return false
	_current_cmd_param = _tags + text
	return _line_start()

## returns true if still executing
func _cmd_process(delta) -> bool:
	match _current_cmd:
		FlowCMD.Dialogue:
			return _line_process(delta)
		FlowCMD.Timer:
			if _skip:
				_cmd_execution_timer = 0
				return false
			_cmd_execution_timer -= delta
			return _cmd_execution_timer > 0
	return false

func _cmd_finish():
	match _current_cmd:
		FlowCMD.Dialogue:
			_line_finish()

## returns true if needs executing
func _line_start() -> bool:
	if _skip:
		_cmd_execution_timer = 0
	else:
		_cmd_execution_timer = randf_range(_current_duration_min, _current_duration_max)
	return  _cmd_execution_timer > 0

## returns true if still executing
func _line_process(delta) -> bool:
	if _skip:
		_cmd_execution_timer = 0
		return false
	_cmd_execution_timer -= delta
	return _cmd_execution_timer > 0

func _line_finish():
	pass
