class_name ChallengeInfo extends Resource

@export_group("General Text")
@export var challenge_begin_title:StringName = &"menu_challenge_begin_title"
@export var challenge_fail_title:StringName = &"menu_challenge_fail_title"
@export var challenge_victory_title:StringName = &"menu_challenge_victory_title"
@export var challenge_victory_subtitle:StringName = &"menu_challenge_victory_subtitle"

@export_category("Challenge Specifics")
@export var challenge_instruction_text:StringName = "GO GO GO"

@export var scene_prizes:Array[PackedScene]
