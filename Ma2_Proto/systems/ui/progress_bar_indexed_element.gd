class_name ProgressBarIndexedElement extends Control

#index is from zero, while Max is the maximum Count, and Fill is the Fill Count
func set_state(index:int, max:int, fill:int, imediate:bool):
	if index >= max:
		visible = false
	else:
		visible = true
