class_name GlobalListener

static var _callables:Dictionary
static var _vars:Dictionary

static func emit_var_changed(var_id:StringName):
	if !has_var(var_id): return
	if !_callables.has(var_id): return
	
	var callables = (_callables[var_id] as Array[Callable])
	var to_remove:Array[Callable]
	var value:Variant = get_var(var_id)
	
	for callable in callables:
		if !callable.is_valid():
			to_remove.push_back(callable)
		else:
			callable.call(value)
	
	for callable in to_remove:
		remove_callable(var_id, callable)

static func set_var(var_id:StringName, value:Variant):
	_vars[var_id] = value
	emit_var_changed(var_id)

static func has_var(var_id:StringName):
	return _vars.has(var_id)

static func get_var(var_id:StringName) -> Variant:
	if has_var(var_id):
		return _vars[var_id]
	else:
		return false
		
static func add_callable(var_id:StringName, callable:Callable):
	if !callable.is_valid(): return
	if !_callables.has(var_id):
		_callables[var_id] = [callable]
	else:
		var arr = _callables[var_id] as Array[Callable]
		if arr.has(callable): return
		arr.push_back(callable)
		
static func remove_callable(var_id:StringName, callable:Callable):
	if !callable.is_valid(): return
	if !_callables.has(var_id): return
	var arr = _callables[var_id] as Array[Callable]
	if !arr.has(callable): return
	arr.erase(callable)
	
