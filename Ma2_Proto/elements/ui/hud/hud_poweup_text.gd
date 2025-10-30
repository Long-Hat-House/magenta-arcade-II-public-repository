class_name HUDPowerupText extends Control

enum Mode {
	WeaponPowerup,
	WeaponReady,
	WeaponChange
}

@export var _text_label:Label
@export var _to_set_color_bg:Array[Control]
@export var _to_set_color_fg:Array[Control]
@export var _animation:AnimationPlayer

func play_text(text:String, fg_color:Color, bg_color:Color, mode:Mode = Mode.WeaponPowerup):
	visible = true

	_text_label.text = text

	for c in _to_set_color_fg:
		c.modulate = fg_color

	for c in _to_set_color_bg:
		c.modulate = bg_color

	_animation.stop()
	_animation.play(&"RESET")
	_animation.advance(0)
	match mode:
		Mode.WeaponPowerup:
			_animation.play("weapon_powerup")
		Mode.WeaponReady:
			_animation.play("weapon_powerup")
		Mode.WeaponChange:
			_animation.play("weapon_change")

func _ready() -> void:
	visible = false
	_animation.animation_finished.connect(_on_animation_finished)

func _on_animation_finished(anim_name:StringName):
	visible = false
