class_name HudWeaponTap extends Control

@export var _progress_bar:ProgressBarFloatMultiple
@export var _progress_bar_recover:ProgressBarIndexed
@export var _progress_bar_recover_container:Control
@export var _progress_bar_projectiles:ProgressBarIndexed
@export var _weapon_unit:HUDWeaponUnit
@export var _extra_bar_size:float = 10
@export var _tap_available_animation:Switch_Oning_Offing_AnimationPlayer
@export var _tap_animations:AnimationPlayer
@export var _powerup_text:HUDPowerupText

@export var _sfx_tap_ready:WwiseEvent

var _can_use_tap:bool
var _weapon:PlayerWeapon

func _ready() -> void:
	await get_tree().process_frame

	var player:Player = Player.instance

	if !player:
		return

	player.tap_equipped_change.connect(_on_tap_changed)
	player.tap_bar_change.connect(_on_tap_bar_changed)
	player.just_tapped.connect(_on_just_tapped)
	player.failed_tap.connect(_on_failed_tap)
	_on_tap_changed()

func _on_just_tapped(touches):
	_tap_animations.stop()
	_tap_animations.play(&"success")

func _on_failed_tap():
	_tap_animations.stop()
	_tap_animations.play(&"fail")

func _on_tap_bar_changed(bar: float) -> void:
	_progress_bar.set_fill(bar)

	var player:Player = Player.instance
	var current_tap:PlayerWeaponTap = player.get_current_tap()
	if current_tap:
		if player.can_use_tap() != _can_use_tap:
			_can_use_tap = player.can_use_tap()
			_tap_available_animation.set_switch(player.can_use_tap())
			if _can_use_tap:
				if _sfx_tap_ready: _sfx_tap_ready.post(self)
				_powerup_text.play_text(
					"hud_tap_ready",
					current_tap.color_highlight,
					current_tap.color,
					HUDPowerupText.Mode.WeaponReady)

func _on_tap_changed():
	var player:Player = Player.instance
	var s := player.currentState;

	if player.get_current_tap() != _weapon:
		_weapon = player.get_current_tap()
		if _weapon:
			_powerup_text.play_text(_weapon.title, _weapon.color_highlight, _weapon.color, HUDPowerupText.Mode.WeaponChange)

	_weapon_unit.set_weapon(_weapon, player.can_use_tap())

	if !_weapon: return

	if _progress_bar_projectiles:
		_progress_bar_projectiles.set_values(s.tap_missile_level, s.tap_missile_level, false)

	if _progress_bar_recover:
		_progress_bar_recover_container.visible = player.get_tap_recover_level() >= 1
		_progress_bar_recover.set_values(player.get_tap_recover_level(), player.get_tap_recover_level(), false)

	var datas:Array[Dictionary]

	var n_bars = player.get_max_tap_level()
	var i:int = 0
	while i < n_bars:
		if i < player.equipped_taps.size():
			var tap = player.equipped_taps[i]
			var data:Dictionary = {
				ProgressBarFloat.PROP_COLOR_BASE : tap.color,
				ProgressBarFloat.PROP_COLOR_HIGHLIGHT : _weapon.color_highlight,
				ProgressBarFloat.PROP_MAX_VALUE : tap.get_tap_cost()
			}
			datas.push_front(data)
		else:
			var data:Dictionary = {
				ProgressBarFloat.PROP_COLOR_BASE : MA2Colors.GREY_DARK,
				ProgressBarFloat.PROP_COLOR_HIGHLIGHT : MA2Colors.GREY_LIGHT,
				ProgressBarFloat.PROP_MAX_VALUE : _extra_bar_size
			}
			datas.push_back(data)
		i += 1

	_progress_bar.set_data(n_bars, player.get_tap_level(), datas)
	_on_tap_bar_changed(player.get_tap_bar())
