extends ProgressBarIndexedElement

@export var _texture_filled:Texture2D
@export var _texture_empty:Texture2D

@export var _texture_rect:TextureRect

func set_state(index:int, max:int, fill:int, imediate:bool):
	super.set_state(index, max, fill, imediate)

	_texture_rect.texture = _texture_filled if index < fill else _texture_empty
