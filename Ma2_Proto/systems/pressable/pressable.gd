class_name Pressable extends Node3D

var current:Player.TouchData;

@export var pressable_priority:int = 0;
@export var pressable_tether_distance:float;
@export var pressable_area:Area3D;
@export var pressable_only_if_downwards:bool;
@export var search_for_area_inside:bool = false;
@export var debug:bool = false;

@export_category("Pressable Audio")
@export var _sfx_pressed:WwiseEvent
@export var _sfx_released:WwiseEvent

var _is_disabled:bool = false

var _pressed_count:int;
var is_pressed:bool:
	get:
		return _pressed_count > 0;

signal pressed();
signal changed_pressed_state(pressed:bool);
signal pressed_player(touch:Player.TouchData);
signal pressed_process(touch:Player.TouchData, delta:float);
signal released();
signal released_player(touch:Player.TouchData);
signal tethered(inwards:bool);
signal tethered_player(touch:PlayerToken);
signal tether_released();
signal tether_released_player(touch:PlayerToken);
signal disabled_changed(is_disabled:bool)

var current_tethered:PlayerToken = null;

##Find a presseable in an arbitrary node.
static func FindPressable(node:Node, recursive:bool = true, includeInternal:bool = false, debug:bool = false) -> Pressable:
	if node is Pressable:
		if debug:
			print("FOUND in %s" % [node]);
		return node as Pressable;
	if recursive:
		for child in node.get_children(includeInternal):
			if debug:
				print("looking for presseable in %s's %s (%s), recursive: %s" % [node, child, child is Pressable, recursive])
			var recursivePresseable := FindPressable(child, recursive, includeInternal, debug);
			if recursivePresseable:
				return recursivePresseable;
	if debug:
		print("found no presseable in %s" % [node]);
	return null;

### To override

func _start_pressing(touch:Player.TouchData):
	pass

func _end_pressing(touch:Player.TouchData):
	pass

func _pressing_process(touch:Player.TouchData, delta:float):
	pass;

func set_disabled(disabled:bool):
	if _is_disabled == disabled: return
	_is_disabled = disabled

	if _is_disabled:
		process_mode = Node.PROCESS_MODE_DISABLED
	else:
		process_mode = Node.PROCESS_MODE_INHERIT

	disabled_changed.emit()

func _ready():
	if pressable_area:
		setup_area(pressable_area);
	elif search_for_area_inside:
		for child in get_children():
			if child is Area3D:
				var area:Area3D = child as Area3D;
				setup_area(area);

func setup_area(area:Area3D):
	area.disable_mode = CollisionObject3D.DISABLE_MODE_REMOVE
	area.body_entered.connect(add_touched);
	area.body_exited.connect(remove_touched);
	area.area_entered.connect(add_touched);
	area.area_exited.connect(remove_touched);

func _physics_process(delta: float) -> void:
	if current_tethered != null and is_instance_valid(current_tethered):
		_tether_process(current_tethered, delta);

func _tether_process(who:PlayerToken, delta:float) -> void:
	if !who.is_in_game() or ((who.global_position - global_position).length() > pressable_tether_distance):
		remove_tether(who, true);


### Public methods:
#region For Player Use
func start_pressing(touch:Player.TouchData):
	if touch != null:
		if pressable_only_if_downwards and not touch.is_downwards():
			return;
		current = touch;
		if debug: print("[PRESSABLE] Pressing %s" % self);
		_pressed_count += 1;
		_start_pressing(current);
		pressed.emit()
		pressed_player.emit(touch);
		changed_pressed_state.emit(true);
		if _sfx_pressed:
			_sfx_pressed.post(self)

func end_pressing(touch:Player.TouchData):
	current = null;
	if debug: print("[PRESSABLE] Unpressing %s" % self);
	_pressed_count -= 1;
	_end_pressing(touch);
	released.emit()
	released_player.emit(touch);
	changed_pressed_state.emit(false);
	if _sfx_released:
		_sfx_released.post(self)

func pressing_process(touch:Player.TouchData, delta:float):
	pressed_process.emit(touch, delta);
	_pressing_process(touch, delta);
#endregion


func check_for_player_token(node:Node3D) -> PlayerToken:
	return node as PlayerToken;

func add_touched(node:Node3D) -> void:
	var token := check_for_player_token(node);
	if debug:
		print("[PRESSABLE] touched by %s (is it token? %s) [%s]" % [node, token, Engine.get_physics_frames()]);
	if token:
		if debug: print("[PRESSABLE] %s PRESSED player %s" % [self, token]);
		if token == current_tethered:
			remove_tether(token, false);
		else:
			if current_tethered != null and is_instance_valid(current_tethered):
				remove_tether(current_tethered, true);
			token.add_presseable(self);

func remove_touched(node:Node3D, force:bool = false) -> void:
	var token := check_for_player_token(node);
	if debug:
		print("[PRESSABLE] untouched by %s (is it token? %s) [%s]" % [node, token, Engine.get_physics_frames()]);
	if token:
		if debug: print("[PRESSABLE] %s unpressed player %s" % [self, token]);
		if !force and pressable_tether_distance > 0 and token.is_in_game():
			add_tether(token);
		else:
			token.remove_presseable(self);

func add_tether(who:PlayerToken):
	if debug:
		print("[PRESSABLE] tethered %s [%s]" % [who, Engine.get_physics_frames()]);
	current_tethered = who;

	tethered.emit();
	tethered_player.emit(who);

func remove_tether(who:PlayerToken, also_remove_touched:bool):
	if debug:
		print("[PRESSABLE] try to remove tethered %s (current: %s)) [%s]" % [who, current_tethered, Engine.get_physics_frames()]);
	if current_tethered == who:
		current_tethered = null;

		tether_released.emit(!also_remove_touched);
		tether_released_player.emit(who);

		if also_remove_touched:
			remove_touched(who, true);
