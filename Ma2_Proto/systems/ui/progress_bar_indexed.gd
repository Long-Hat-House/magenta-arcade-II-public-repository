class_name ProgressBarIndexed extends Control

@export var _elements_container:Control

var _elements:Array[ProgressBarIndexedElement]
var _prepared:bool = false

func _ready() -> void:
	_prepare()

func _prepare() -> void:
	if _prepared: return
	_prepared = true
	if _elements.size() <= 0:
		for child in _elements_container.get_children():
			if child is ProgressBarIndexedElement:
				_elements.append(child)

func set_values(max:int, fill:int, imediate:bool):
	_prepare()

	if _elements.size() > 0:
		while _elements.size() < max:
			var n = _elements[0].duplicate()
			_elements_container.add_child(n)
			_elements.append(n)

	var i:int = 0
	for element in _elements:
		element.set_state(i, max, fill, imediate)
		i += 1
