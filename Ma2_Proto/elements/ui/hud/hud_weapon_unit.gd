class_name HUDWeaponUnit extends Control

@export var _trect_to_set_icon:Array[TextureRect]
@export var _to_set_color:Array[Control]
@export var _to_set_color_highlight:Array[Control]

func set_shake(shake:bool):
	push_warning("Deprecated function! Has no effect")

func set_weapon(w:PlayerWeapon, available:bool):
	if w && w.id != PlayerWeapon.WeaponID.TOUCH_ONLY:
		show()
		for trect in _trect_to_set_icon:
			trect.texture = w.icon

		if available:
			for c in _to_set_color:
				c.modulate = w.color
			for c in _to_set_color_highlight:
				c.modulate = w.color_highlight
		else:
			for c in _to_set_color:
				c.modulate = MA2Colors.GREY_DARK
			for c in _to_set_color_highlight:
				c.modulate = MA2Colors.GREY
	else:
		hide()

func set_state(level:int, current:float):
	push_warning("Deprecated function! Has no effect")
