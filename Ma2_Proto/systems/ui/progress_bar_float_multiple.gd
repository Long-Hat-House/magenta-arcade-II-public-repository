class_name ProgressBarFloatMultiple extends Control

var _bars:Array[ProgressBarFloat]
var _prepared:bool = false

func _ready() -> void:
	_prepare()

func _prepare() -> void:
	if _prepared: return
	_prepared = true

	for child in get_children():
		if child is ProgressBarFloat:
			_bars.append(child)

func set_data(n_bars_total:int, n_bars_on:int, bars_data:Array[Dictionary] = [], fill:float = 0):
	_prepare()

	while _bars.size() < n_bars_total:
		var d = _bars[_bars.size()-1].duplicate()
		d.name = _bars[_bars.size()-1].name + "D"
		_bars.append(d)
		add_child(d)

	var i:int = 0
	var default_data:Dictionary = bars_data[0] if bars_data.size() >= 1 else {}
	for bar in _bars:
		var data:Dictionary = bars_data[i] if bars_data.size() > i else default_data
		fill -= bar.set_bar_data(i<n_bars_on, data, fill)
		i += 1

func set_fill(fill:float):
	for bar in _bars:
		fill -= bar.set_fill(fill)
