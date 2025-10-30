class_name CoinsChangerTag extends CoinsChanger

@export var _hide_when_zero:bool = true
@export var _animations_tag:AnimationPlayer
@export var _animations_enabled:Switch_Oning_Offing_AnimationPlayer
@export var _animations_interacting:Switch_Oning_Offing_AnimationPlayer
@export var _label_3d:Label3D
@export var _invisible_on_start:Node3D
@export var _enable_hud:bool = true

func start_interacting():
	_animations_interacting.set_switch(true)

func stop_interacting():
	_animations_interacting.set_switch(false)

func set_change_amount(change_amount:int) -> void:
	super.set_change_amount(change_amount)

	_label_3d.text = get_exibition_string(change_amount)

	if _hide_when_zero && change_amount == 0:
		_animations_enabled.set_switch(false)
	else:
		_animations_enabled.set_switch(true, true)

func check_enough_coins() -> bool:
	var check = super.check_enough_coins()
	if !check:
		_animations_tag.stop()
		_animations_tag.play("check_fail")
	return check

func do_change() -> bool:
	var changed = super.do_change()
	if changed:
		_animations_tag.stop()
		_animations_tag.play("change_success")
	return changed

func _ready() -> void:
	_animations_enabled.turned_on.connect(_on_animation_turned_on)
	_animations_enabled.turned_off.connect(_on_animation_turned_off)

func _enter_tree() -> void:
	if _invisible_on_start:
		_invisible_on_start.visible = false
	set_change_amount(get_change_amount())

func _exit_tree() -> void:
	if is_instance_valid(HUDCoins.instance):
		HUDCoins.instance.remove_hud_request(self)

func get_exibition_string(value:int) -> String:
	return HUDCoins.get_coins_text(abs(value))

func _on_animation_turned_on():
	if is_instance_valid(HUDCoins.instance) && _enable_hud:
		HUDCoins.instance.add_hud_request(self)

func _on_animation_turned_off():
	if is_instance_valid(HUDCoins.instance) && _enable_hud:
		HUDCoins.instance.remove_hud_request(self)
