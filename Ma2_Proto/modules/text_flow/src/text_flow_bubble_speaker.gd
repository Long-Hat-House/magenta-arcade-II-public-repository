class_name TextFlowBubbleSpeaker extends Resource

enum SpeakerVoice {
	Follower, #Magentas
	Believer,
	Fanatic,
	Priest,
	FanaticPriest,
	Eva,
	Nando,
	Nene,
	Ju,
	Adao,
	Turing
}

signal bubble_started
signal bubble_finished

var followee:Node3D
var offset:Vector3

@export_group("Voice")
var voice:SpeakerVoice
#When multiple voice types are possible, forces to a specific one or leave random (-1)
var voice_type_id:int = -1
var voice_pitch:float

var voice_based_on_graphic:GraphicNPC_RegularRandomizer

func _init(
	followee:Node3D = null,
	offset:Vector3 = Vector3.ZERO,
	voice = SpeakerVoice.Believer,
	voice_type_id:int = -1,
	voice_based_on_graphic:GraphicNPC_RegularRandomizer = null
	):
	self.voice_pitch = randf()
	self.followee = followee
	self.offset = offset
	self.voice = voice
	self.voice_type_id = voice_type_id
	self.voice_based_on_graphic = voice_based_on_graphic

func set_voice(voice = SpeakerVoice.Believer, voice_type_id:int = -1):
	self.voice = voice
	self.voice_type_id = voice_type_id

func get_wwise_voice() -> int:
	if voice_based_on_graphic:
		match voice_based_on_graphic.get_type():
			GraphicNPC_RegularRandomizer.Type.Magenta:
				voice = SpeakerVoice.Follower
			GraphicNPC_RegularRandomizer.Type.Believer:
				voice = SpeakerVoice.Believer
			GraphicNPC_RegularRandomizer.Type.BelieverFanatic:
				voice = SpeakerVoice.Fanatic

	var group:Array[SpeakerVoice]

	# == BELIEVER
	group = [
		SpeakerVoice.Believer,
		]
	if group.has(voice):
		return AK.SWITCHES.NPC_VOICE.SWITCH.BELIEVER

	# == FOLLOWER
	group = [
		SpeakerVoice.Follower,
		]
	if group.has(voice):
		return AK.SWITCHES.NPC_VOICE.SWITCH.FOLLOWER

	# == FANATIC
	group = [
		SpeakerVoice.Fanatic,
		]
	if group.has(voice):
		return AK.SWITCHES.NPC_VOICE.SWITCH.FANACTIC

	# == SPECIAL
	group = [
		SpeakerVoice.Eva,
		SpeakerVoice.Nando,
		SpeakerVoice.Nene,
		SpeakerVoice.Ju,
		SpeakerVoice.Adao,
		SpeakerVoice.Turing,
		SpeakerVoice.Priest,
		SpeakerVoice.FanaticPriest,
		]
	if group.has(voice):
		return AK.SWITCHES.NPC_VOICE.SWITCH.SPECIAL

	# == DEFAULT
	return AK.SWITCHES.NPC_VOICE.SWITCH.BELIEVER

func get_wwise_voice_pitch() -> float:

	return voice_pitch

func get_wwise_voice_type() -> int:
	if voice_based_on_graphic:
		match voice_based_on_graphic.get_type():
			GraphicNPC_RegularRandomizer.Type.Magenta:
				voice = SpeakerVoice.Follower
			GraphicNPC_RegularRandomizer.Type.Believer:
				voice = SpeakerVoice.Believer
			GraphicNPC_RegularRandomizer.Type.BelieverFanatic:
				voice = SpeakerVoice.Fanatic

	match voice:
		SpeakerVoice.Priest:
			return AK.SWITCHES.NPC_VOICE_TYPE.SWITCH.HUB_PRIEST
		SpeakerVoice.FanaticPriest:
			return AK.SWITCHES.NPC_VOICE_TYPE.SWITCH.HUB_FANACTIC
		SpeakerVoice.Eva:
			return AK.SWITCHES.NPC_VOICE_TYPE.SWITCH.CHAR_EVA
		SpeakerVoice.Nando:
			return AK.SWITCHES.NPC_VOICE_TYPE.SWITCH.CHAR_NANDO
		SpeakerVoice.Nene:
			return AK.SWITCHES.NPC_VOICE_TYPE.SWITCH.CHAR_NENE
		SpeakerVoice.Ju:
			return AK.SWITCHES.NPC_VOICE_TYPE.SWITCH.CHAR_JU
		SpeakerVoice.Adao:
			return AK.SWITCHES.NPC_VOICE_TYPE.SWITCH.CHAR_ADAO
		SpeakerVoice.Turing:
			return AK.SWITCHES.NPC_VOICE_TYPE.SWITCH.CHAR_TURING
		_:
			var generics:Array[SpeakerVoice] = [
				AK.SWITCHES.NPC_VOICE_TYPE.SWITCH.GENERIC_A,
				AK.SWITCHES.NPC_VOICE_TYPE.SWITCH.GENERIC_B,
				AK.SWITCHES.NPC_VOICE_TYPE.SWITCH.GENERIC_C,
				]

			if voice_type_id <= -1:
				return generics[followee.get_instance_id()%generics.size() if followee else 0]
			else:
				return generics[voice_type_id%generics.size()]
