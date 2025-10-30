class_name HudHpBar extends ProgressBarIndexed

func _ready() -> void:
	super._ready()

	await get_tree().process_frame
	Player.instance.hp_change.connect(_on_player_hp_change)
	_on_player_hp_change(Player.instance.hp, Vector3.ZERO)

func _on_player_hp_change(amount:int, pos:Vector3):
	super.set_values(maxi(amount, 3), amount, false)
