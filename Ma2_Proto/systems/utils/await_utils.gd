class_name AwaitUtils

## Only works on signals without parameters, for now
class All:
	signal completed;
	var complete:bool;
	var signals:Dictionary = {};

	func _init(array_signals:Array[Signal]):
		for sig:Signal in array_signals:

			signals[sig] = false;
			sig.connect(_on_signal.bind(sig), CONNECT_ONE_SHOT);

	#func _on_signal(_a=null,_b=null,_c=null,_d=null,_e=null,_f=null,_g=null, sig:Signal = Signal()): ## multiple parameters implementation?
	func _on_signal(sig:Signal = Signal()):
		if not complete:
			signals[sig] = true;
		var comp:bool = true;
		for value in signals.values():
			comp = comp and value;
		if comp:
			complete = true;
			completed.emit();


class Any:
	signal completed;
	var complete:bool;

	func _init(array_signals:Array[Signal]):
		for sig:Signal in array_signals:
			if sig:
				sig.connect(_on_signal.bind(sig), CONNECT_ONE_SHOT);

	func _on_signal(sig:Signal):
		if not complete:
			complete = true;
			completed.emit();

static func await_all(list: Array, node:Node):
	var counter = {
		value = list.size()
	}

	for el in list:
		if el is Signal:
			el.connect(count_down.bind(counter), CONNECT_ONE_SHOT)
		elif el is Callable:
			func_wrapper(el, count_down.bind(counter))

	var tree := node.get_tree();

	while counter.value > 0 and (node and is_instance_valid(node)):
		await tree.process_frame

static func count_down(dict):
	dict.value -= 1


static func func_wrapper(callable: Callable, call_back: Callable):
	await callable.call()
	call_back.call()


static func all(signals:Array[Signal])->void:
	if !signals.is_empty():
		await All.new(signals).completed;

static func any(signals:Array[Signal])->void:
	if !signals.is_empty():
		await Any.new(signals).completed;
