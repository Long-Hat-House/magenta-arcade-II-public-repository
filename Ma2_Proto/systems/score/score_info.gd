class_name ScoreInfo extends Resource

@export_category("Normal Score")
@export var score_title:StringName
@export var score_value:int = 10
@export var world_positioned:bool = true
@export var works_in_shop_mode:bool = false

@export_category("Combo Score")
@export var adds_to_combo:bool = true

@export_category("Boost Score")
@export var ignore_boost_multiplier:bool = false
