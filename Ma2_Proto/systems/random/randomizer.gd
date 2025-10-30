class_name Randomizer

const INT_MAX = 9223372036854775807;
const INT_MIN = -9223372036854775808;
const INT32_MAX = 0b11111111_11111111_11111111_11111111

class RandomizerObject:
	var _current:PackedInt64Array;
	
	func _init(starting_seed:int = 128) -> void:
		_current = rand_from_seed(starting_seed);
	
	func get_current_value()->int:
		return _current[0];
		
	func get_current_seed()->int:
		return _current[1];
	
	func get_next_value()->int:
		_current = rand_from_seed(get_current_seed() + 1);
		return get_current_value();
		
	func randi()->int:
		return get_next_value();
		
	func randf()->float:
		var random_integer:int = self.randi();
		var random_float:float = ((random_integer & INT32_MAX) as float) / (INT32_MAX);
		return random_float;
		
	func randf_range(min:float, max:float):
		return lerpf(min, max, self.randf());

static var _random_dictionary:Dictionary = {};
static func get_randomizer(id:String, starting_seed:int = 128)->RandomizerObject:
	if not _random_dictionary.has(id):
		_random_dictionary[id] = RandomizerObject.new(starting_seed)
	return _random_dictionary[id];
		
