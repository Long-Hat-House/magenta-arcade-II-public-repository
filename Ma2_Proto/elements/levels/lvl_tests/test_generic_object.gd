extends Node3D

@export var objs_container:Node3D
@export var _initial_index:int = 0
var _objs:Array[Node3D]
var _current:int = 0
var _moved:bool = false

func _ready() -> void:
	for obj in objs_container.get_children():
		if obj is Node3D:
			_objs.append(obj)
	set_current(_initial_index)

func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_1):
		move(-1)
	elif Input.is_key_pressed(KEY_2):
		move(+1)
	else:
		_moved = false

func move(ammount:int):
	if _moved: return
	_moved = true
	set_current(_current + ammount)

func set_current(index:int):
	_current = index

	if _objs.size() == 0:
		return

	while _current < 0:
		_current += _objs.size()
	while _current >= _objs.size():
		_current -= _objs.size()

	objs_container.position.x = -_objs[_current].position.x
