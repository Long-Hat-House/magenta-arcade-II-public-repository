class_name MetaInfoDisplay extends Node

enum InfoType
{
	UnlockedStarsCount,
	CoinsAmount,
	AllocatedStarsCount,
	UnusedStarsCount,
	Playtime,
	UpgradeUnlockStage,
}

@export var _info_type:InfoType
@export var _label_text:Label
@export var _label3d_text:Label3D

func _ready() -> void:
	Ma2MetaManager.meta_updated.connect(_on_meta_updated)
	_on_meta_updated()

func _on_meta_updated() -> void:
	match _info_type:
		InfoType.UnlockedStarsCount:
			_set_text(str(Ma2MetaManager.get_unlocked_stars_count()))
		InfoType.CoinsAmount:
			_set_text(str(Ma2MetaManager.get_coins_amount()))
		InfoType.AllocatedStarsCount:
			_set_text(str(Ma2MetaManager.get_allocated_total_stars()))
		InfoType.UnusedStarsCount:
			_set_text(str(Ma2MetaManager.get_unused_stars_count()))
		InfoType.UpgradeUnlockStage:
			_set_text(str(Ma2MetaManager.get_upgrade_unlock_stage()))

func _set_text(text:String):
	if _label_text: _label_text.text = text
	if _label3d_text: _label3d_text.text = text

func _process(delta: float) -> void:
	if _info_type == InfoType.Playtime:
		_set_text(str(Ma2MetaManager.get_playtime_text()))
