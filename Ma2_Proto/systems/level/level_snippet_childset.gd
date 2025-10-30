class_name Level_Snippet_ChildSet extends Level_Snippet_Node

func get_snippets_count():
	var i:int = 0;
	for child in get_snippets():
		if is_valid_snippet(child):
			i += 1;
	return i;
	
func is_valid_snippet(node:Node)->bool:
	return node and is_instance_valid(node) and node is Level_Snippet_Node;
	
func get_commands(level:Level)->Array[Level.CMD]:
	var arr:Array[Level.CMD] = [];
	
	for node:Node in get_snippets():
		if not is_valid_snippet(node): 
			continue;
		var snip:Level_Snippet_Node = node as Level_Snippet_Node;
		if snip.is_active():
			arr.push_back(snip.cmd(level));
	return arr;

func get_snippets()->Array[Node]:
	return get_children();
