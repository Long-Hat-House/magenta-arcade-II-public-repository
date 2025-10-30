class_name ChallengePrizeButton extends TimedButton

const TEXT_ID_POWERUP_HEALTH_TITLE 	:StringName = &"powerup_health_title"
const TEXT_ID_POWERUP_HOLD_TITLE 	:StringName = &"powerup_hold_title"
const TEXT_ID_POWERUP_TAP_TITLE 	:StringName = &"powerup_tap_title"

const ICON_HEALTH = preload("res://elements/icons/icon_health.png")

@export_group("styles")
@export var bg_general:Texture
@export var bg_hold:Texture
@export var bg_tap:Texture

@export_group("")
@export var _icon:TextureRect
@export var _bg_icon:TextureRect
@export var _title:Label
@export var _text:Label

var _callback:Callable

func _ready():
	super._ready()
	time_completed.connect(func(): if _callback : _callback.call())

func set_prize_general(type):
	pass

func set_prize_health(increase:int = 1):

	set_visuals(
		TEXT_ID_POWERUP_HEALTH_TITLE,
		"+" + str(increase),
		ICON_HEALTH,
		MA2Colors.GREENISH_BLUE,
		MA2Colors.GREENISH_BLUE_DARK,
		bg_general,
	)
	_callback = Player.instance.heal.bind(1)

func set_prize_scene(weapon_scene:PackedScene):
	var obj = weapon_scene.instantiate()
	if obj is PlayerWeapon:
		add_child(obj)
		set_prize_weapon(obj)
	else:
		push_error("Object Scene is not a recognized Prize!")
		obj.queue_free()

func set_prize_weapon(weapon:PlayerWeapon):
	if !is_instance_valid(weapon):
		hide()
		return

	var is_hold:bool = weapon.type == PlayerWeapon.WeaponType.HOLD

	set_visuals(
		TEXT_ID_POWERUP_HOLD_TITLE if is_hold else TEXT_ID_POWERUP_TAP_TITLE,
		weapon.title,
		weapon.icon,
		weapon.color_highlight,
		weapon.color,
		bg_hold if is_hold else bg_tap,
	)
	_callback = Player.instance.add_weapon.bind(weapon)

func set_visuals(title:String, text:String, icon:Texture2D, color_light:Color, color_dark:Color, bg:Texture2D):
	self_modulate = color_dark

	_bg_icon.texture = bg
	_bg_icon.self_modulate = color_dark

	_icon.texture = icon
	_icon.self_modulate = color_light

	_title.text = title
	_title.self_modulate = color_light

	_text.text = text
	_text.self_modulate = color_light

#func set_prize_definition(data:ChallengeController.PrizeDefinition):
	#match data._get_style():
		#ChallengeController.PrizeDefinition.Style.GENERAL:
			#_bg_icon.texture = bg_general
		#ChallengeController.PrizeDefinition.Style.HOLD:
			#_bg_icon.texture = bg_hold
		#ChallengeController.PrizeDefinition.Style.TAP:
			#_bg_icon.texture = bg_tap
	#
	#var color_light = data._get_color()
	#var color_dark = data._get_bg_color()
	#
	#self_modulate = color_dark
	#
	#_bg_icon.self_modulate = color_dark
	#
	#_icon.texture = data._get_icon()
	#_icon.self_modulate = color_light
		#
	#_title.text = data._get_title()
	#_title.self_modulate = color_light
	#
	#_text.text = data._get_text()
	#_text.self_modulate = color_light
	#
	#_callback = data._get_callback()


#func _is_usable()->bool:
	#if !_weapon:
		#return false
#
	#match _weapon.type:
			#PlayerWeapon.WeaponType.HOLD:
				#return Player.instance.currentState.hold_level < _weapon._get_max_level();
			#PlayerWeapon.WeaponType.TAP:
				#return Player.instance.currentState.tap_level < _weapon._get_max_level();
	#return true;

#
#static var PRIZE_HEALTH:PrizeDefinition = PrizeDefinition.new(
	#ICON_HEALTH, Color.from_string("A8FFE8", Color.WHITE),
	#func():
		#Player.instance.heal(1)
		#,
	#TEXT_ID_POWERUP_HEALTH_TITLE, "+1")
#
#static var PRIZE_HOLD_UPGRADE:WeaponPrizeDefinition:
	#get: return WeaponPrizeDefinition.new(Player.instance.equippedHold)
#
#static var PRIZE_TAP_UPGRADE:WeaponPrizeDefinition:
	#get: return WeaponPrizeDefinition.new(Player.instance.equippedTap)
#
#static var COMMON_PRIZE_ARRAY:Array[PrizeDefinition]:
	#get: return [PRIZE_HOLD_UPGRADE, PRIZE_HEALTH, PRIZE_TAP_UPGRADE];
#
#static func PRIZE_WEAPON_SCENE(weapon_scene:PackedScene) -> PrizeDefinition:
	#return PRIZE_WEAPON_INSTANCE(weapon_scene.instantiate())
#
#static func PRIZE_WEAPON_INSTANCE(weapon_instance:PlayerWeapon) -> PrizeDefinition:
	#return WeaponPrizeDefinition.new(weapon_instance)

#class PrizeDefinition  extends RefCounted:
	#enum Style {
		#GENERAL,
		#HOLD,
		#TAP
	#}
#
	#var _style:Style = Style.GENERAL
	#var _icon:Texture2D
	#var _title:String
	#var _text:String
	#var _callback:Callable
	#var _color:Color
	#var _bg_color:Color
#
	#func _init(icon:Texture2D, color:Color, callback:Callable, title:String = "", text:String = ""):
		#_icon = icon
		#_callback = callback
		#_text = text
		#_title = title
		#_color = color
		#_bg_color = color
#
	#func _get_icon() -> Texture2D:
		#return _icon
	#func _get_style() -> Style:
		#return _style
	#func _get_title() -> String:
		#return _title
	#func _get_text() -> String:
		#return _text
	#func _get_callback() -> Callable:
		#return _callback
	#func _get_color() -> Color:
		#return _color
	#func _get_bg_color() -> Color:
		#return _bg_color
	#func _is_usable() -> bool:
		#return true
#
#class WeaponPrizeDefinition extends PrizeDefinition:
	#var _weapon:PlayerWeapon
#
	#func _init(weapon:PlayerWeapon):
		#_weapon = weapon
#
		#if _weapon:
			#match _weapon.type:
				#PlayerWeapon.WeaponType.HOLD:
					#_style = Style.HOLD
					#_title = TEXT_ID_POWERUP_HOLD_TITLE
				#PlayerWeapon.WeaponType.TAP:
					#_style = Style.TAP
					#_title = TEXT_ID_POWERUP_TAP_TITLE
#
			#_icon = _weapon.icon
			#_text = _weapon.title
			#_callback = func(): Player.instance.add_weapon(_weapon)
			#_color = _weapon.color_highlight
			#_bg_color = _weapon.color
#
	#func _is_usable()->bool:
		#if !_weapon:
			#return false
#
		#match _weapon.type:
				#PlayerWeapon.WeaponType.HOLD:
					#return Player.instance.currentState.hold_level < _weapon._get_max_level();
				#PlayerWeapon.WeaponType.TAP:
					#return Player.instance.currentState.tap_level < _weapon._get_max_level();
		#return true;
