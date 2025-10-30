class_name HudWeaponHold extends Control

@export var _progress_bar:ProgressBarFloatMultiple
@export var _progress_bar_fire_rate:ProgressBarIndexed
@export var _progress_bar_warm_up:ProgressBarIndexed
@export var _progress_bar_extra_shots:ProgressBarIndexed
@export var _weapon_unit:HUDWeaponUnit
@export var _powerup_text:HUDPowerupText

var _weapon:PlayerWeapon
var _lvl:int
var _fire_rate_level:int
var _warm_up_level:int
var _extra_shot_level:int

func _ready() -> void:
	_weapon_unit.set_weapon(null, false)
	await get_tree().process_frame

	var player:Player = Player.instance

	if !player:
		return

	player.weapon_any_change.connect(_on_player_weapon_any_change)
	player.hold_potencial_change.connect(_on_player_potencial_change)
	player.just_holded_all.connect(_on_player_holded_all)
	player.just_released_all.connect(_on_player_released_all)

	_on_player_weapon_any_change()

func _process(delta: float) -> void:
	var s := Player.instance.currentState;
	var fill:float = (s.hold_potencial) + s.hold_potencial_bar
	_progress_bar.set_fill(fill)

func _on_player_weapon_any_change():
	var player:Player = Player.instance
	var s := player.currentState;

	if _weapon != player.equippedHold:
		_weapon = player.equippedHold
		if _weapon && _weapon.id != PlayerWeapon.WeaponID.TOUCH_ONLY:
			_powerup_text.play_text(_weapon.title, _weapon.color_highlight, _weapon.color, HUDPowerupText.Mode.WeaponChange)

	_weapon_unit.set_weapon(_weapon, true)

	#Fire Rate
	if s.hold_fire_rate_level != _fire_rate_level:
		if s.hold_fire_rate_level > _fire_rate_level:
			_powerup_text.play_text("hud_powerup_hold_firerate", _weapon.color_highlight, _weapon.color, HUDPowerupText.Mode.WeaponPowerup)
		_fire_rate_level = s.hold_fire_rate_level
	_progress_bar_fire_rate.set_values(_fire_rate_level,_fire_rate_level,false)

	#Warm Up
	if s.hold_warm_up_level != _warm_up_level:
		if s.hold_warm_up_level > _warm_up_level:
			_powerup_text.play_text("hud_powerup_hold_speed", _weapon.color_highlight, _weapon.color, HUDPowerupText.Mode.WeaponPowerup)
		_warm_up_level = s.hold_warm_up_level
	_progress_bar_warm_up.set_values(_warm_up_level,_warm_up_level,false)

	#Extra Shot
	if s.extra_shot_level != _extra_shot_level:
		if s.extra_shot_level > _extra_shot_level:
			_powerup_text.play_text("hud_powerup_extrashot", _weapon.color_highlight, _weapon.color, HUDPowerupText.Mode.WeaponPowerup)
		_extra_shot_level = s.extra_shot_level
	_progress_bar_extra_shots.set_values(_extra_shot_level,_extra_shot_level,false)

	#Hold Level
	if s.hold_level != _lvl:
		if s.hold_level > _lvl:
			_powerup_text.play_text("hud_powerup_hold_lvl", _weapon.color_highlight, _weapon.color, HUDPowerupText.Mode.WeaponPowerup)
		_lvl = s.hold_level

	var datas:Array[Dictionary]

	var n_bars = player.get_max_hold_level()
	var i:int = 0
	while i < n_bars:
		if i < n_bars:
			var data:Dictionary = {
				ProgressBarFloat.PROP_COLOR_BASE : _weapon.color,
				ProgressBarFloat.PROP_COLOR_HIGHLIGHT : _weapon.color_highlight,
			}
			datas.push_front(data)
		else:
			var data:Dictionary = {
				ProgressBarFloat.PROP_COLOR_BASE : Color.TRANSPARENT,
				ProgressBarFloat.PROP_COLOR_HIGHLIGHT : MA2Colors.GREY_DARK,
			}
			datas.push_back(data)
		i += 1

	_progress_bar.set_data(n_bars, _lvl, datas, (s.hold_potencial) + s.hold_potencial_bar)

	_check_hold_status();

func _on_player_holded_all():
	_check_hold_status();

func _on_player_released_all():
	_check_hold_status();

func _on_player_potencial_change(potencial:int):
	_check_hold_status();

func _check_hold_status():
	#weapon_hold.set_shake(Player.instance.is_holding and not Player.instance.is_in_max_potential_hold_level);
	pass
