class_name Pressable_Kill extends Pressable

@export var health_to_kill:Health;

func _start_pressing(touch:Player.TouchData):
	#print("[PRESSABLE KILL] Pressed %s" % self);
	if health_to_kill && touch:
		health_to_kill.damage_kill(touch.instance);
	
