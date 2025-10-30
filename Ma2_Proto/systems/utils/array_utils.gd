class_name ArrayUtils

static func _get_percentage(percentage01:float, current:float, next:float)->float:
	return clampf(remap(percentage01, current, next , 0, 1), 0, 1);


## Calls for every element, where in the percentage it is. Imagine an array a juice of n compartments, and you fill it x%. The first compartments will be filled, one compartment will be partially field and the rest would be empty, 0%. This does it for every element.
static func percentage_array_float_call_all(arr:Array, percentage01:float, callable_element_float:Callable):
	var len:int = arr.size();
	if len <= 0: 
		return;
	var iteration_percentage:float = 1.0 / len;
	var curr:float = 0;
	for elem:Variant in arr:
		var next = curr + iteration_percentage;
		var elem_percentage:float = _get_percentage(percentage01, curr, next)
		callable_element_float.call(elem, elem_percentage);
		curr = next;

## Calls for the current changing element, where in the percentage it is. Imagine an array a juice of n compartments, and you fill it x%. The first compartments will be filled, one compartment will be partially field and the rest would be empty, 0%. This does it for every element.
static func percentage_array_float_call_one(arr:Array, percentage01:float, percentage01_last:float, callable_element_float:Callable):
	var len:int = arr.size();
	if len <= 0 or percentage01 == percentage01_last: 
		return;
	var iteration_percentage:float = 1.0 / len;
	var element:int = floori(percentage01 / iteration_percentage);
	var element_old:int = floori(percentage01_last / iteration_percentage);
	var element_min:int = mini(element, element_old);
	var element_max:int = maxi(element, element_old);
	element_max = mini(element_max, len - 1);
	while element_min <= element_max:
		var curr:float = element_min * iteration_percentage;
		var next:float = curr + iteration_percentage;
		var elem_percentage:float = _get_percentage(percentage01, curr, next);
		
		callable_element_float.call(arr[element_min], elem_percentage);
		
		element_min += 1;



static func _turn_percentage_callable_into_boolean(elem:Variant, percentage:float, callable_element_boolean:Callable, higher_is_true:float):
	callable_element_boolean.call(elem, percentage > higher_is_true);

static func percentage_boolean_call_all(arr:Array, percentage01:float, callable_element_boolean:Callable, higher_is_true:float = 0.5):
	percentage_array_float_call_all(arr, percentage01, _turn_percentage_callable_into_boolean.bind(callable_element_boolean, higher_is_true))

static func percentage_boolean_call_one(arr:Array, percentage01:float, percentage01_last:float, callable_element_boolean:Callable, higher_is_true:float = 0.5):
	var len:int = arr.size();
	if len <= 0 or percentage01 == percentage01_last: 
		return;
	var iteration_percentage:float = 1.0 / len;
	var element:int = floori(percentage01 / iteration_percentage);
	var element_old:int = floori(percentage01_last / iteration_percentage);
	var element_min:int = mini(element, element_old);
	var element_max:int = maxi(element, element_old);
	while(element_min <= element_max):
		var curr:float = element_min * iteration_percentage;
		var next:float = curr + iteration_percentage;
		var elem_percentage:float = _get_percentage(percentage01, curr, next);
		var elem_percentage_old:float = _get_percentage(percentage01_last, curr, next);
		
		if elem_percentage != elem_percentage_old:
			var b_new:bool = elem_percentage > higher_is_true;
			var b_old:bool = elem_percentage_old > higher_is_true;
			if b_old != b_new:
				callable_element_boolean.call(arr[element_min], b_new);
		
		element_min += 1;
