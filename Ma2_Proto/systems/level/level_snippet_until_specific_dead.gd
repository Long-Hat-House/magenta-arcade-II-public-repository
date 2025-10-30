class_name Level_Snippet_Until_Element_Dead extends Level_Snippet_Node

@export var element_to_wait:Node;
@export var while_snippet:Level_Snippet_Node;
@export var while_healths_inside:Array[Node];
@export var wait_after_secondary_objetive:float = 0.15;

func kill_element_to_wait():
	var h:Health = Health.FindHealth(element_to_wait);
	if h:
		h.damage_kill(element_to_wait);

func cmd_wait_until_dead()->Level.CMD:
	return Level.CMD_Wait_Callable.new(func wait_until_element_dead():
			return !is_instance_valid(element_to_wait);
			);

func cmd(level:Level)->Level.CMD:
	
	var secondary_stuff:Array[Level.CMD] = [];
	
	if while_snippet != null:
		secondary_stuff.push_back(while_snippet.cmd(level));
		
	if while_healths_inside != null and while_healths_inside.size() > 0:
		var enemies:Array[Health] = Health.FindAllUniqueHealths_Nodes(while_healths_inside);
		secondary_stuff.push_back(Level.CMD_Wait_Callable.new(func():
				for enemy:Health in enemies:
					if is_instance_valid(enemy) and enemy.is_alive():
						print("%s is alive" % [enemy] );
						return false;
				return true;
				),
		)
		
	
	var main_parallel_stuff:Array[Level.CMD] = [
		Level.CMD_Parallel_Complete.new([
			_cmd(level),
			cmd_wait_until_dead(),
		]),
	];
	
	if secondary_stuff.size() > 0:
		main_parallel_stuff.push_back(Level.CMD_Sequence.new([
			Level.CMD_Parallel_Complete.new(secondary_stuff),
			Level.CMD_Wait_Seconds.new(wait_after_secondary_objetive),
			Level.CMD_Callable.new(kill_element_to_wait),
		]))
		
	return Level.CMD_Parallel.new(main_parallel_stuff);
