class_name HUDCoins extends Node

const SAVE_HUD_COINS_LAST_SHOWN:StringName = &"HUD.COINS.LAST_SHOWN"

static var instance:HUDCoins

@export var _label_coins:Label
@export var _label_adder:Label
@export var _on_off_animation:Switch_Oning_Offing_AnimationPlayer
@export var _adder_animations:AnimationPlayer
@export var _coin_animations:AnimationPlayer

@export_category("Coins Audio")
@export var _sfx_coins_switch_up:WwiseSwitch
@export var _sfx_coins_switch_down:WwiseSwitch
@export var _sfx_play_coins:WwiseEvent
@export var _sfx_stop_coins:WwiseEvent
@export var _sfx_not_enough:WwiseEvent

var _requesters:Dictionary
var _force_hide_requesters:Dictionary

var _last_shown_value:int = 0
var _target_value:int = 0
var _adder_tween:Tween

static func get_coins_text(amount:int) -> String:
	return str(amount)

func add_hud_request(requester:Node):
	if !_requesters.has(requester):
		_requesters[requester] = 1
		_on_requesters_updated()

func remove_hud_request(requester:Node):
	if _requesters.has(requester):
		_requesters.erase(requester)
		_on_requesters_updated()

func add_force_hide_request(requester:Node):
	if !_force_hide_requesters.has(requester):
		_force_hide_requesters[requester] = 1
		_on_force_hide_requesters_updated()

func remove_force_hide_request(requester:Node):
	if _force_hide_requesters.has(requester):
		_force_hide_requesters.erase(requester)
		_on_force_hide_requesters_updated()

func _on_requesters_updated():
	if _force_hide_requesters.size() > 0:
		return

	if _requesters.size() > 0 && !_on_off_animation.is_set_to_on():
		_set_on()
	elif _requesters.size() == 0 && !_on_off_animation.is_set_to_off():
		_set_off()

func _on_force_hide_requesters_updated():
	if _force_hide_requesters.size() > 0 && !_on_off_animation.is_set_to_off():
		_set_off()
	elif _force_hide_requesters.size() == 0 && !_on_off_animation.is_set_to_on():
		_on_requesters_updated()

func _set_on():
	_on_off_animation.set_switch(true)

func _set_off():
	_on_off_animation.set_switch(false)
	if _sfx_play_coins: _sfx_play_coins.stop(self)

func _exit_tree() -> void:
	if _sfx_play_coins: _sfx_play_coins.stop(self)

func _ready() -> void:
	instance = self

	_last_shown_value = Ma2MetaManager.get_quick_int(SAVE_HUD_COINS_LAST_SHOWN, 0)
	_target_value = _last_shown_value
	_label_coins.text = get_coins_text(_last_shown_value)

	_on_off_animation.turned_on.connect(_on_animation_turned_on)
	Ma2MetaManager.meta_updated.connect(_on_meta_updated)
	Ma2MetaManager.check_enough_coins_failed.connect(_on_not_enough_coins)
	_on_off_animation.set_switch_immediate(false)
	_label_adder.hide()

	_on_meta_updated()

func _on_not_enough_coins():
	_coin_animations.play("not_enough")
	_sfx_not_enough.post(self)

func _on_animation_turned_on():
	_on_meta_updated()

func _on_meta_updated():
	_tween_adder(Ma2MetaManager.get_coins_amount())

func _tween_adder(new_target:int):
	if _on_off_animation.is_set_to_off():
		return
	if _target_value == new_target:
		return

	if _adder_tween && _adder_tween.is_running():
		_adder_tween.kill()
		_complete_adder_tween(false)

	add_hud_request(_label_adder)

	_target_value = new_target
	var dif:int = _target_value - _last_shown_value
	if dif> 0:
		_adder_animations.play("gained")
		_sfx_coins_switch_up.set_value(self)
	else:
		_adder_animations.play("spent")
		_sfx_coins_switch_down.set_value(self)

	_sfx_play_coins.post(self)

	_label_adder.text = get_coins_text(dif)
	_label_adder.show()

	var absdif:int = absi(dif)
	var tween_duration:float = .5 if absdif < 50 else (1 if absdif < 1000 else 2)

	_adder_tween = create_tween()
	_adder_tween.tween_interval(.5)
	_adder_tween.tween_method(func(value:float):
		_label_coins.text = get_coins_text(lerp(_last_shown_value, _target_value, value))
		, 0.0, 1.0, tween_duration)
	_adder_tween.finished.connect(_complete_adder_tween)

func _complete_adder_tween(is_final:bool = true):
	if _last_shown_value < _target_value:
		_coin_animations.play("gained")
	else:
		_coin_animations.play("spent")

	_sfx_stop_coins.post(self)

	_last_shown_value = _target_value
	_label_coins.text = get_coins_text(_last_shown_value)
	Ma2MetaManager.set_quick_int(SAVE_HUD_COINS_LAST_SHOWN, _last_shown_value)

	if is_final:
		_label_adder.hide()
		remove_hud_request(_label_adder)
