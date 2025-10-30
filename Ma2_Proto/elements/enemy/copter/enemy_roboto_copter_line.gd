extends VisibleOnScreenNotifier3D

const ENEMY_ROBOTO_COPTER = preload("res://elements/enemy/copter/enemy_roboto_copter.tscn")
const ENEMY_ROBOTO_COPTER_CANNON = preload("res://elements/enemy/copter/enemy_roboto_copter_cannon.tscn")

@onready var graphic = $robotocopter_graphic

@export var time_between_copters:float = 1;
@export var space_between_copters:float = 0;
@export var numberOfCopters:int = 5;
@export var _line:ChildLine3D;
var _looked_for_line:bool;
@export var wait_group:String;
var behaviourNow:int = 0;

var _level:Level;
var _readied:bool;

var line:ChildLine3D:
	get:
		if not _looked_for_line and _line == null:
			for child in get_children():
				if child is ChildLine3D:
					_line = child as ChildLine3D;
					break;
			_looked_for_line = true;
		return _line;

func _ready():
	graphic.queue_free();
	_readied = true;

	var p := self as Node;
	while p != null:
		if p is Level:
			_level = p as Level;
			return;
		p = p.get_parent();

func _enter_tree():
	if not _readied:
		await self.ready;
	start_behaviour(Time.get_ticks_usec());

func _exit_tree():
	behaviourNow = 0;

func start_behaviour(id:int):
	behaviourNow = id;
	if not is_on_screen():
		await screen_entered;
		if behaviourNow != id: return;

	var spaceNow:float;
	while numberOfCopters > 0:
		create_copter(spaceNow);
		spaceNow -= space_between_copters;
		if time_between_copters != 0:
			await get_tree().create_timer(time_between_copters).timeout;
			if behaviourNow != id: return;
		numberOfCopters -= 1;


func create_copter(spaceAdd:float):
	_level.objs.create_object(
			ENEMY_ROBOTO_COPTER,
			wait_group,
			line.get_position_in_line(spaceAdd)
			).set_line(line, false, spaceAdd);

func _on_screen_entered():
	pass # Replace with function body.


func _on_screen_exited():
	queue_free();
