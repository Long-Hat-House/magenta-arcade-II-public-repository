class_name NumberUtils

static func get_equally_separated_numbers(min:float, max:float, amount:int)->Array[float]:
	if amount > 1:
		var arr:Array[float] = [];
		var now:float = min;
		var dist:float = max-min;
		var sum:float = dist / (amount - 1);
		while amount > 0:
			amount -= 1;
			arr.push_back(now);
			now += sum;
		return arr;
	else:
		return [lerpf(min, max, 0.5)];
