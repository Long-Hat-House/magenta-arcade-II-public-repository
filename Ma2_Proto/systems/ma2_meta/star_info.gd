@tool
class_name StarInfo extends Resource

const ICON_SCORE = preload("res://elements/icons/icon_score.png")

const TEXT_LEVEL_COMPLETE:String = "Encontre e derrote {char_name}"
const TEXT_THE_BOSS:String = "The Boss"
const TEXT_TARGET_TIME:String = "Finish in less than {target_time}"
const TEXT_SCORE:String = "Destroy all the enemies!"

enum StarType {
	LevelComplete,
	TargetTime,
	TargetScore
}

static func get_score_text(score:int) -> String:
	var original_text:String = str(score).reverse()
	var result_text:String = ""
	var counter = 3
	for digit in original_text:
		if counter == 0:
			result_text = "." + result_text
		result_text = digit + result_text
		counter -= 1
	return result_text

static func get_time_text_from_sec(seconds:int) -> String:
	var minutes:int = seconds/60
	seconds = seconds - minutes*60
	return "%02d:%02d" % [minutes, seconds]

@export var star_id:StringName:
	set(val):
		if val.is_empty():
			val = resource_path.get_file().get_basename()
		star_id = val
	get:
		if star_id.is_empty():
			return resource_path.get_file().get_basename()
		return star_id

@export var type:StarType:
	set(val):
		type = val
		notify_property_list_changed()
	get:
		return type

@export var _target_value_int:int = 180

func _validate_property(property: Dictionary) -> void:
	if property.name in ["_target_value_int"] and type in [StarType.LevelComplete]:
		property.usage = PROPERTY_USAGE_NO_EDITOR

func get_target_time() -> float:
	return _target_value_int

func get_target_score() -> int:
	return _target_value_int

## Should only be called when Meta is loaded
func is_unlocked() -> bool:
	return Ma2MetaManager.is_star_unlocked(star_id)

## Should only be called when Meta is loaded
func set_unlocked() -> bool:
	return Ma2MetaManager.set_star_unlocked(star_id)

func get_icon() -> Texture2D:
	var icon:Texture2D
	match type:
		StarType.TargetScore:
			icon = ICON_SCORE
		_:
			icon = null
	return icon

func get_instruction(lvl_info:LevelInfo) -> String:
	var text:String
	match type:
		StarType.LevelComplete:
			if lvl_info && lvl_info.zap_speaker_bosses.size():
				text = tr(TEXT_LEVEL_COMPLETE).format({
					"char_name" : tr(lvl_info.zap_speaker_bosses[0].name)
					})
			else:
				text = tr(TEXT_LEVEL_COMPLETE).format({
					"char_name" : tr(TEXT_THE_BOSS)
					})
		StarType.TargetTime:
			text = tr(TEXT_TARGET_TIME).format({
				"target_time" : get_time_text_from_sec(get_target_time())
				})
		StarType.TargetScore:
			text = get_score_text(get_target_score())
		_:
			text = text
	return text
