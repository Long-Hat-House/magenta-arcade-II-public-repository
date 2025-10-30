class_name Altar extends Node3D

var id:StringName;

@export var vfx_explode:PackedScene;
var carried:Node3D;
var altar_presseable:Pressable;
var entered_screen:bool;
@onready var body:CharacterBody3D = $Body as CharacterBody3D;
@onready var altar_graphic:Graphic_Altar = $Altar_Graphic
@onready var npc_graphic:Graphic_NPC = $Body/NPC_Graphic_Regular

var is_pressed:bool:
	get:
		if altar_presseable and is_instance_valid(altar_presseable):
			return altar_presseable.is_pressed;
		else:
			return false;

signal pressed;
signal released;
signal holdable_done;
signal destroyed;
signal opened;


func _physics_process(delta:float):
	altar_graphic.set_altar_transform(body.global_transform, delta);


func _on_pressed(touch:Player.TouchData):
	altar_graphic.set_pressed(true);
	pressed.emit();

func _on_released(touch:Player.TouchData):
	altar_graphic.set_pressed(false);
	released.emit();

func carry(new_carried:Node3D):
	if not is_node_ready():
		await ready;
	if carried:
		carried.queue_free();
	self.carried = new_carried;
	if carried:
		var parent = carried.get_parent()
		if parent:
			parent.remove_child(carried);
		altar_graphic.get_instantiate_place().add_child(carried);
		carried.position = Vector3.ZERO;
		altar_presseable = Pressable.FindPressable(carried, true, false, true);
		#print("[Altar] Found %s in %s" % [altar_presseable, carried]);
		if altar_presseable:
			#print("[Altar] altar connecting functions");
			altar_presseable.pressed_player.connect(_on_pressed);
			altar_presseable.released_player.connect(_on_released);
		if altar_presseable is Holdable:
			altar_presseable.button_hold_finished.connect(_holded_holdable)
			altar_presseable.button_hold_finished.connect(destroy)

func _holded_holdable():
	holdable_done.emit();


func destroy():
	if vfx_explode:
		InstantiateUtils.InstantiateInTree(vfx_explode, body);
	destroyed.emit();
	self.queue_free();

func open(delay:float):
	if delay > 0:
		await create_tween().tween_interval(delay).finished;
	opened.emit();
	if is_instance_valid(altar_graphic):
		altar_graphic.set_open(true);

func is_open()->bool:
	return altar_graphic.is_open();

func close(delay:float):
	if delay > 0:
		await create_tween().tween_interval(delay).finished;
	if is_instance_valid(altar_graphic):
		altar_graphic.set_open(false);
