class_name Node3DTarget
extends Node3D

@export var id:String;

### Returns the quantity of targets it found
static func FindTargets(node:Node, returnValue:Array, id:String = "", debug:bool = false) -> int:
	var count:int = 0;
	var target := node as Node3DTarget;
	if target:
		if debug:
			print("FOUND target in %s (id:'%s'; looking for '%s')" % [target, target.id, id]);
		if id == node.id:
			count += 1;
			returnValue.append(node as Node3DTarget);
	for child in node.get_children():
		var newTargets:int = FindTargets(child, returnValue, id, debug);
		count += newTargets;
		if debug:
			print("looking for target in %s's %s (%s), found %s targets" % [node, child, child is Node3DTarget, newTargets])
	return count;
