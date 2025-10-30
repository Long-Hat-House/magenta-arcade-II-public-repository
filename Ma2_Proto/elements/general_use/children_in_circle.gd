class_name ChildrenInCircle extends Node3D

@export var radius:float = 1.0;
@export var offset_angle:float = 0;
@export var offset_position:Vector3;
@export var circ_multiplier:Vector2 = Vector2.ONE;
@export var walk_min_arc:float;
@export var walk_max_arc:float;
@export var automatically_add_children_to_circle_equally_spaced:bool;

class CircleElement:
	var node:Node3D;
	var offset:float;

	func _to_string() -> String:
		return "%s (offset: %s)" % [node, offset]

var elements:Array[CircleElement] = [];

func get_size()->int:
	return elements.size();

signal added_element;
signal removed_element;

func _ready() -> void:
	if automatically_add_children_to_circle_equally_spaced:
		self.child_order_changed.connect(_changed_children);

func _changed_children():
	elements.clear();
	if walk_min_arc != walk_max_arc:
		add_elements_equally_spaced(get_children(), walk_min_arc, walk_max_arc, false);
	else:
		add_elements_equally_spaced(get_children(), 0.0, 2.0 * PI, false);
	walk_elements(0.0);

func get_angles_string()->String:
	return str(elements.map(func(elem):
		return elem.offset;
		))

func add_element(what:Node3D, angle:float, also_add_child:bool = true):
	var elem:CircleElement = CircleElement.new();
	elem.node = what;
	elem.offset = angle;
	elements.append(elem);
	if also_add_child:
		if elem.node.get_parent():
			elem.node.reparent(self);
		else:
			add_child(elem.node);
	added_element.emit();

func add_elements_equally_spaced(elements:Array, arc_min:float = 0, arc_max:float = 2*PI, also_add_child:bool = true):
	var len := elements.size();
	var angles = NumberUtils.get_equally_separated_numbers(arc_min, arc_max, len + 1)
	for i in range(len):
		add_element(elements[i], angles[i], also_add_child);

func walk_elements(delta_angle:float):
	var to_delete:Array[CircleElement];
	for element in elements:
		if element.node and is_instance_valid(element.node):
			element.offset += delta_angle;
			if walk_min_arc != walk_max_arc:
				element.offset = fposmod(element.offset - walk_min_arc, walk_max_arc - walk_min_arc) + walk_min_arc;
			element.node.position = offset_position + get_circle_position(radius, element.offset, circ_multiplier);
		else:
			to_delete.append(element);

	for element in to_delete:
		elements.erase(element);
		removed_element.emit();

static func get_circle_position(radius:float, offset_angle:float, circ_multiplier:Vector2 = Vector2.ONE)-> Vector3:
	return VectorUtils.get_circle_point(offset_angle, Vector3.UP, circ_multiplier) * radius;
