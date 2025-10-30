class_name GameElement extends Node3D

var _health:Health;
var health:Health:
	get:
		if _health == null:
			_health = Health.FindHealth(self, true, true);
		#assert(_health != null, "No health found in %s!" % [self])
		return _health;
		
		
var _poolable:Poolable;
var poolable:Poolable: 
	get:
		if _poolable == null:
			_poolable = Poolable.FindPoolable(self);
		#assert(_poolable != null, "No poolable found in %s!" % [self])
		return _poolable;
		
##Is this Game Element still valid? This is used to see if the element has been destroyed after an await, for example.
func is_valid()->bool:
	return self.get_parent() != null and not self.is_queued_for_deletion();
	
func get_full_name()->String:
	var n:Node = self;
	var parent:Node = self.get_parent();
	var str:String = "'";
	while n != null:
		if parent != null:
			str += "%s, of " % n.name;
		else:
			str += "%s'" % n.name;
		n = parent;
		if parent != null:
			parent = parent.get_parent();
	return str;
