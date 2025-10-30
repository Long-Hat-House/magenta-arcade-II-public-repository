class_name Element_Compartiment extends LHH3D

@export var origin:Node3D;
@export var destination:Node3D;
@export var item:Node3D;
@export var global_basis_identity:bool;

@export var vfx_on_fall:PackedScene;
@export var default_duration:float = 0.35;

var from:Transform3D;
var to:Transform3D;

var gambiarra:float; ##to avoid levels that remove/re-add elements in the tree to trigger the compartment

static func give_item(item:Node3D, from:Node3D, to:Node3D, vfx:PackedScene, duration:float = 0.35):
	await give_item_transform(item, from.global_transform, to.global_transform, vfx, duration);

static func give_item_transform(item:Node3D, from:Transform3D, to:Transform3D, vfx:PackedScene, duration:float = 0.35):
	if !item.is_inside_tree():
		InstantiateUtils.get_topmost_instantiate_node().add_child(item);
	var t = item.create_tween();
	print("[COMPARTMENT] Opening up with %s (duration %s) %s to %s" % [item, duration, from, to]);
	t.tween_method(func(value:float):
		if is_instance_valid(item):
			#print("[COMPARTMENT] Tweening from %s to %s (%s)" % [from, to, value]);
			item.global_transform = from.interpolate_with(to, value);
			item.scale = Vector3.ONE * remap(value, 0.0, 1.0, 0.001, 1.0);
			#print("giving %s from %s to %s" % [item, from, to])
		, 0.25, 1.0, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC);
	#print("[COMPARTMENT] Created tween %s (duration %s) %s" % [item, duration, t]);

	if vfx:
		t.tween_callback(func():
			if is_instance_valid(item):
				InstantiateUtils.InstantiateInTree(vfx, item);
			);
	await t.finished;


func _ready():
	if item == null:
		for child in get_children():
			if child != origin and child != destination:
				item = child;
				destination.global_transform = item.global_transform;
				break;


	if origin == null: origin = self;
	if destination == null: destination = self;

	if self.item.is_inside_tree():
		self.item.get_parent().remove_child(self.item);

	gambiarra = 1.0;
	tree_exiting.connect(on_tree_exiting);


func _process(delta):
	gambiarra -= delta;

	from = origin.global_transform;
	to = destination.global_transform;



func on_tree_exiting():
	if gambiarra >= 0:
		return;

	if global_basis_identity:
		to.basis = Basis.IDENTITY;

	give_item_transform(item, from, to, vfx_on_fall, default_duration);



func setup(origin:Node3D, destination:Node3D, what_inside:Node3D):
	self.origin = origin;
	self.destination = destination;
	self.item = what_inside;

	if self.item.is_inside_tree():
		self.item.get_parent().remove_child(self.item);
