class_name LevelInfo extends Resource

enum NPCMode{
	Priest,
	Fanatic,
	Dead
}

@export var lvl_id:StringName
@export_file("lvl_*") var lvl_resource_path:String

@export var zap_speaker_bosses:Array[TextFlowZapSpeaker]

@export var is_arcade_mode:bool = false
@export var npc_mode:NPCMode = NPCMode.Priest
@export_range(0, 8) var church_npc_max_count:int = 0
@export var always_unlocked:bool = false

@export_category("Level Goals")
@export var score_max_seconds:int = 300
@export var level_goal_text:String = "Encontre e derrote!"
@export var star_list:Array[StarInfo]

@export_category("Level Visual Identity")
@export var lvl_texture:Texture2D
@export var lvl_icon:Texture2D

@export var lvl_color:Color = MA2Colors.SKY_BLUE
@export var lvl_color_highlight:Color = MA2Colors.GREENISH_BLUE

@export var map_coordinate:Vector3
@export var map_scale:float

@export_category("Level Dialogues")
@export var dial_zap:String = "zap_lvl"

@export var dial_hub_welcome:String = "dial_hub_welcome"

@export var dial_hub_win:String = "dial_hub_win"
@export var dial_hub_win_array:Array[String] = []
@export var dial_hub_pre_unlock:String = "dial_hub_pre_unlock"
@export var dial_hub_pos_unlock:String = "dial_hub_pos_unlock"

@export var dial_hub_lvl_still_locked:String = "dial_hub_lvl_still_locked"

@export var dial_hub_stars_locked:String = "dial_hub_stars_locked"
@export var dial_hub_stars_unlocked_first:String = "dial_hub_stars_unlocked_first"
@export var dial_hub_stars_unlocked_full:String = "dial_hub_stars_unlocked_full"

@export_category("Level Shop")
@export var buy_as_many:Array[ShopObjectInfo]
@export var buy_one:Array[ShopObjectInfo]
@export var buy_start:Array[ShopObjectInfo]

@export_category("Social")
@export var _leaderboard_id:SocialPlatformManager.Leaderboard = SocialPlatformManager.Leaderboard.HS_NONE
@export var _achievement_beat_id:SocialPlatformManager.Achievement = SocialPlatformManager.Achievement.ACH_NONE

## Should only be called when Meta is loaded
func is_unlocked() -> bool:
	return always_unlocked || Ma2MetaManager.is_level_unlocked(lvl_id)

## Should only be called when Meta is loaded
func is_complete() -> bool:
	return Ma2MetaManager.is_level_complete(lvl_id)

## Should only be called when Meta is loaded
func set_unlocked() -> bool:
	SocialPlatformManager.reveal_achievement(_achievement_beat_id)
	return Ma2MetaManager.set_level_unlocked(lvl_id)

## Should only be called when Meta is loaded
func set_complete() -> bool:
	SocialPlatformManager.unlock_achievement(_achievement_beat_id)
	return Ma2MetaManager.set_level_complete(lvl_id)

func submit_score(score:int, invalidated:bool) -> void:
	Ma2MetaManager.submit_score(self, score)
	if !invalidated:
		SocialPlatformManager.submit_score(_leaderboard_id, score)

func get_highscore() -> int:
	return Ma2MetaManager.get_highscore(self)

func get_highscore_text() -> String:
	return StarInfo.get_score_text(get_highscore())
