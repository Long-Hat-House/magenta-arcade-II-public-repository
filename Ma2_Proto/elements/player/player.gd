class_name Player
extends Node3D

const UPGRADE_TAP_SPEED = preload("res://systems/ma2_meta/upgrades/upgrade_tap_speed.tres")
const UPGRADE_TAP_MAX = preload("res://systems/ma2_meta/upgrades/upgrade_tap_max.tres")
const UPGRADE_TAP_PROJECTILES = preload("res://systems/ma2_meta/upgrades/upgrade_tap_projectiles.tres")

const UPGRADE_HOLD_START = preload("res://systems/ma2_meta/upgrades/upgrade_hold_start.tres")
const UPGRADE_HOLD_SPEED = preload("res://systems/ma2_meta/upgrades/upgrade_hold_speed.tres")
const UPGRADE_HOLD_FIRERATE = preload("res://systems/ma2_meta/upgrades/upgrade_hold_firerate.tres")

const UPGRADE_HEALTH_INITIAL = preload("res://systems/ma2_meta/upgrades/upgrade_health_initial.tres")
const UPGRADE_HEALTH_REVENGE = preload("res://systems/ma2_meta/upgrades/upgrade_health_revenge.tres")
const UPGRADE_HEALTH_HEAL = preload("res://systems/ma2_meta/upgrades/upgrade_health_heal.tres")

const TAP_BAR_RECOVER_PER_DAMAGE:float = .5;
const TAP_BAR_RECOVER_PER_TICK:float = 0;
const TAP_BAR_RECOVER_TICK_DURATION:float = 2;

@export var emergency_heal:EmergencyHeal
@export var equippedHold:PlayerWeaponHold
var equippedTap:PlayerWeaponTap

@export_category("Configuration")
@export var playerTokenScene:PackedScene;
@export var tapTime:float = 0.15;
@export var immunity_time:float = 0.15;

@export_category("Weapon configuration")
@export_group("Hold")
@export var hold_warm_up_duration_per_level:Curve;
@export var hold_warm_up_multiplier_per_upgrade:Curve;
@export var hold_warm_down_speed_per_no_touch_time:Curve
@export var hold_damage_up_curve_per_upgrade:Curve;

@export_category("Start state")
@export var maxHP:int = 3;

@onready var finger_cast:ShapeCast3D = %FingerCast3D

var equipped_taps:Array[PlayerWeaponTap]
var tap_bar_recover_timer;

var hp:int;
var hp_percentage:float:
	get:
		return float(hp)/float(maxHP);
var groundPlane:Plane;
var currentTouches:Array[TouchData];
var lastValidTouch:TouchData;
var _touches_locked:bool

var immunity_count:float;

signal hp_change(hp:int, pos:Vector3)
signal finger_took_damage(token:PlayerToken);
signal dead;

signal hold_level_change(level:int);
signal hold_potencial_change(potencial:int);
signal hold_potencial_progress_change(progress:float);
signal tap_bar_change(amount:float);
signal use_tap(finger:PlayerToken);
signal try_tap;
signal failed_tap;
signal tap_level_change(level:int);
signal weapon_any_change;

signal equipment_change;
signal tap_equipped_change;
signal hold_equipped_change;
signal try_add_equipment;
signal any_equipment_powerup;

signal did_damage(damageData:Health.DamageData);
signal did_any_damage();


signal just_holded(t:TouchData);
signal just_released(t:TouchData);
signal just_moved_any_physics_process(move:Vector3);
signal just_holded_any;
signal just_released_any;
signal just_released_after;
signal just_holded_all;
signal just_released_all;
signal just_tapped(t:TouchData);
signal just_tapped_any;

var is_holding:bool:
	get:
		return currentTouches and not currentTouches.is_empty();
var is_in_max_potential_hold_level:bool:
	get:
		return currentState.hold_potencial == currentState.hold_level;

static var instance:Player;

var mouse_position:Vector3;

static func get_closest_position(pos:Vector3, include_latest_valid:bool = false, default:Vector3 = Vector3.ZERO) -> Vector3:
	var leastDist:float = 999999;
	var leastPos:Vector3 = default;
	var anyTouch:bool = false;
	for touch in instance.currentTouches:
		anyTouch = true;
		var touchPos:Vector3 = touch.instance.position;
		var dist:float = (touchPos - pos).length_squared();
		if dist < leastDist:
			leastDist = dist;
			leastPos = touchPos;
	if include_latest_valid and not anyTouch:
		if instance.lastValidTouch:
			var touchPos:Vector3 = instance.touch_position_to_world_position(instance.lastValidTouch.touchPosition);
			var dist:float = (touchPos - pos).length_squared();
			if dist < leastDist:
				leastDist = dist;
				leastPos = touchPos;
	return leastPos;

static func get_closest_direction(pos:Vector3, include_latest_valid:bool = false, default:Vector3 = Vector3.BACK) -> Vector3:
	var playerPos:Vector3 = get_closest_position(pos, include_latest_valid, Vector3.ZERO);
	if not playerPos.is_zero_approx():
		playerPos = Vector3(playerPos.x, pos.y, playerPos.z);
		return playerPos - pos;
	else:
		return default;

static func get_medium_position() -> Vector3:
	var posSum:Vector3 = Vector3.ZERO;
	var touchesTotal:int = 0;
	for touch in instance.currentTouches:
		var touchPos:Vector3 = touch.instance.position;
		posSum += touchPos;
		touchesTotal += 1;
	return posSum / touchesTotal;

class TouchData extends RefCounted:
	var touchIndex:int;
	var touchPosition:Vector2;
	var lastFrameTouchPosition:Vector2;
	var instance:PlayerToken;
	var health:Health;
	var timeStamp:float;
	var pressedInLifetime:bool;
	var leftInLifetime:bool = false;

	func _init():
		timeStamp = Time.get_ticks_msec();

	func _to_string() -> String:
		return "%s:%s (%s)" % [touchIndex, instance, instance.position];

	func time_alive_seconds()->float:
		return float(Time.get_ticks_msec() - timeStamp) / 1000.0;

	func is_downwards()->bool:
		return time_alive_seconds() <= 0.15 and !pressedInLifetime;

	func already_left()->bool:
		return leftInLifetime;

class PlayerState extends RefCounted:
	var amountTouches:int;
	var no_touch_time:float

	#check player.get_max_hold_level for the maximum level with upgrade
	var hold_level:int; #the current powerup level for Hold (or max potencial)
	var hold_potencial:int; #the current "sub level" for Hold
	var hold_potencial_bar:float; #the current state in the "hold potencial" from 0 to 1

	var extra_shot_level:int = 0

	var emergency_heal_level:int = 0;

	var hold_warm_up_level:int = 0
	var hold_fire_rate_level:int = 0

	var tap_level:int;
	var tap_bar_value:float; ## -100 to 100 always
	var tap_bar_max:float

	var tap_missile_level:int = 0;

	var revenge_level:int = 3;

	func _init(hold:int, tap:int):
		hold_level = hold;
		tap_level = tap;
		tap_bar_value = tap;

var currentState:PlayerState;

func get_tap_bar() -> float:
	return currentState.tap_bar_value

func get_tap_bar_max() -> float:
	return currentState.tap_bar_max

func set_tap_bar(bar:float):
	bar = clampf(bar, 0, get_tap_bar_max())

	if currentState.tap_bar_value != bar:
		currentState.tap_bar_value = bar
		tap_bar_change.emit(currentState.tap_bar_value)
		_on_any_weapon_change()

func clear_taps():
	add_tap(null)

func add_tap(tap_weapon:PlayerWeaponTap):
	if !tap_weapon:
		for tap in equipped_taps:
			tap.queue_free()

		equipped_taps.clear()
	else:
		var current_parent = tap_weapon.get_parent()
		if current_parent:
			push_warning("WILL REMOVE CHILD")
			current_parent.remove_child(tap_weapon);
		add_child(tap_weapon);
		equipped_taps.append(tap_weapon)
		if get_tap_level() >= get_max_tap_level():
			equipped_taps.pop_front()

	equippedTap = tap_weapon

	var tap_bar_max:float = 0
	for tap in equipped_taps:
		tap_bar_max += tap.get_tap_cost()

	currentState.tap_bar_max = tap_bar_max
	currentState.tap_level = equipped_taps.size()

	charge_tap_bar_fully()
	tap_level_change.emit(currentState.tap_level);
	tap_equipped_change.emit()
	_on_any_weapon_change();

func get_tap_level() -> int:
	return currentState.tap_level

func get_max_tap_level() -> int:
	return 1 + UPGRADE_TAP_MAX.get_progress()

func charge_tap_bar_fully()->void:
	set_tap_bar(currentState.tap_bar_max);

func charge_tap_bar(amount:float) -> void:
	set_tap_bar(get_tap_bar() + amount)

func get_hold_level()->int:
	return currentState.hold_level;

func get_max_hold_level() -> int:
	return 5

func set_hold_level(level:int):
	level = clampi(level, 0, get_max_hold_level())

	if level != currentState.hold_level:
		currentState.hold_level = level;
		hold_level_change.emit(level);
		_on_any_weapon_change();
		_on_any_equipment_powerup();

func add_hold_level(levelAdd:int):
	set_hold_level(get_hold_level() + levelAdd);

func set_hold_potencial(potencial:int):
	potencial = clampi(potencial, 0, currentState.hold_level);
	if potencial != currentState.hold_potencial:
		currentState.hold_potencial = potencial;
		hold_potencial_change.emit(potencial);
		_on_any_weapon_change();

func get_seed_based_on_equipped_items(arbitrary_sum:int = 128):
	return _get_hash(equippedHold) + _get_hash(get_current_tap()) + arbitrary_sum;

func _get_hash(wpn:PlayerWeapon)->int:
	if wpn:
		return wpn.name.hash();
	else:
		return 0;

func just_did_damage(dam:Health.DamageData, remaining_hp:float):
	if dam.recover_tap_ammo:
		charge_tap_bar(minf(dam.amount, remaining_hp) * get_tap_recover_level() * TAP_BAR_RECOVER_PER_DAMAGE);

	did_damage.emit(dam);
	did_any_damage.emit();

func _enter_tree():
	_prepare_debug()

func _exit_tree():
	_release_debug()

func _player_state_debug() -> String:
	var property_list = currentState.get_property_list()
	var log_string = "PLAYER STATE:\n"

	for property in property_list:
		var property_name = property.name
		var property_value = currentState.get(property_name)
		log_string += "\t" + property_name + ": " + str(property_value) + "\n"

	log_string += "\n========"
	log_string += "\n\tMax Hold Level: " + str(get_max_hold_level())
	log_string += "\n\tMax Tap Level: " + str(get_max_tap_level())

	log_string += "\n========"
	log_string += "\n\tTouches: " + str(currentTouches.size())
	for t in currentTouches:
		log_string += "\n\t\t== " + str(t.touchIndex) + " =="
		log_string += "\n\t\tTerrain: " + t.instance.get_current_terrain_type_name()

	return log_string

func _prepare_debug():
	DevManager.add_debug_callback(_player_state_debug, "PlayerState")

func _release_debug():
	DevManager.remove_debug_callback("PlayerState")

# Called when the node enters the scene tree for the first time.
func _ready():
	instance = self;

	currentState = PlayerState.new(0, 0);
	currentState.hold_level = UPGRADE_HOLD_START.get_progress()
	currentState.hold_warm_up_level = UPGRADE_HOLD_SPEED.get_progress()
	currentState.hold_fire_rate_level = UPGRADE_HOLD_FIRERATE.get_progress()

	currentState.tap_missile_level = UPGRADE_TAP_PROJECTILES.get_progress()

	currentState.revenge_level = UPGRADE_HEALTH_REVENGE.get_progress()
	currentState.emergency_heal_level = UPGRADE_HEALTH_HEAL.get_progress()
	maxHP += UPGRADE_HEALTH_INITIAL.get_progress();
	hp = maxHP;
	groundPlane = Plane(Vector3.UP, Vector3.ZERO);
	Input.set_use_accumulated_input(false);
	_on_any_weapon_change();

	just_holded.connect(_on_just_holded_private);
	just_released.connect(_on_just_released_private);
	just_tapped.connect(_on_just_tapped_private);

	tap_equipped_change.connect(_on_just_changed_equipment);
	hold_equipped_change.connect(_on_just_changed_equipment);

	print("PLAYER READY");

func _on_just_changed_equipment()->void:
	equipment_change.emit();

func _on_just_holded_private(t:TouchData)->void:
	just_holded_any.emit();
	if currentTouches.size() == 1:
		just_holded_all.emit();

func _on_just_released_private(t:TouchData)->void:
	just_released_any.emit();
	if currentTouches.size() == 0:
		just_released_all.emit();

func _on_just_tapped_private(t:TouchData)->void:
	just_tapped_any.emit();


func _on_any_equipment_powerup():
	any_equipment_powerup.emit();

func _on_any_weapon_change()->void:
	weapon_any_change.emit();


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta:float):
	if instance == self:
		Ma2MetaManager.process_playtime(delta)

	if immunity_count > 0:
		immunity_count -= delta;

	currentState.amountTouches = currentTouches.size();

	## If it is touching
	if currentState.amountTouches > 0:
		currentState.no_touch_time = 0
		if currentState.hold_potencial < currentState.hold_level:
			var delta_up_multiplier:float = hold_warm_up_multiplier_per_upgrade.sample(currentState.hold_warm_up_level) / hold_warm_up_duration_per_level.sample(currentState.hold_potencial)
			currentState.hold_potencial_bar += delta * delta_up_multiplier;
			if currentState.hold_potencial_bar > 1:
				currentState.hold_potencial_bar -= 1;
				set_hold_potencial(currentState.hold_potencial + 1);

		tap_bar_recover_timer -= delta;

		while(tap_bar_recover_timer < 0):
			tap_bar_recover_timer += TAP_BAR_RECOVER_TICK_DURATION
			charge_tap_bar(TAP_BAR_RECOVER_PER_TICK * get_tap_recover_level());
	else: ## If it is not touching
		currentState.no_touch_time += delta
		if currentState.hold_potencial > 0 || currentState.hold_potencial_bar > 0:

			## Potencial going down
			currentState.hold_potencial_bar -= delta * hold_warm_down_speed_per_no_touch_time.sample(currentState.no_touch_time);
			if currentState.hold_potencial_bar < 0:
				if currentState.hold_potencial > 0:
					currentState.hold_potencial_bar += 1;
				else:
					currentState.hold_potencial_bar = 0
				set_hold_potencial(currentState.hold_potencial - 1);

		tap_bar_recover_timer = TAP_BAR_RECOVER_TICK_DURATION;

	hold_potencial_progress_change.emit(currentState.hold_potencial_bar);

	for touch in currentTouches:
		touch.instance.check_for_presseable_process(touch, delta); ## Doesnt do anything
		if touch.instance.currentPresseable and is_instance_valid(touch.instance.currentPresseable):
			touch.instance.currentPresseable.pressing_process(touch, delta);
		else:
			equippedHold.hold(touch, touch.instance, currentState, delta);
		touch.lastFrameTouchPosition = touch.touchPosition;

	if Input.is_key_pressed(KEY_K):
		Game.instance.kill_all_enemies(false);

func _physics_process(delta:float):
	for touch in currentTouches:
		var new_pos:Vector3 = touch_position_to_world_position(touch.touchPosition);
		var old_pos:Vector3 = touch.instance.position;
		touch.instance.position = new_pos;
		var dist:Vector3 = new_pos - old_pos;
		if !dist.is_zero_approx():
			just_moved_any_physics_process.emit(dist);

	_simulate_secondary_touch(Input.is_key_pressed(KEY_L));

var _secondary_touch_event:InputEventScreenTouch
func _simulate_secondary_touch(trigger:bool):
	if _touches_locked:
		_secondary_touch_event = null
		return

	if _secondary_touch_event && !trigger: ## exit screen
		_secondary_touch_event.pressed = false
		Input.parse_input_event(_secondary_touch_event);
		_secondary_touch_event = null
	elif !_secondary_touch_event && trigger: ## enter screen
		_secondary_touch_event = InputEventScreenTouch.new()
		_secondary_touch_event.index = 10;
		var pos:Vector2 = DisplayServer.window_get_size()/2
		_secondary_touch_event.position = pos
		_secondary_touch_event.pressed = true;
		Input.parse_input_event(_secondary_touch_event);
	elif _secondary_touch_event:
		Input.parse_input_event(_secondary_touch_event);
	#if _simulating_secondary_touch:
		#var event := InputEventScreenTouch.new();
		#event.index = 1;
		#if !currentTouches.is_empty():
			#event.position = currentTouches[0].touchPosition + Vector2.RIGHT * 100;
		#else:
			#event.position = Player.instance.lastValidTouch.touchPosition + Vector2.RIGHT * 100;
		#event.pressed = trigger;
#
		##print("[PLAYER] 1 making false input on %s while %s" % [event.position, event.pressed]);
		#Input.parse_input_event(event);
	#_simulating_secondary_touch = trigger;

func _unhandled_input(event:InputEvent):
	if _touches_locked: return

	## Touch controls
	if event is InputEventScreenDrag:
		var dragEvent = event as InputEventScreenDrag;
		var index = find_index_in_current_touches(dragEvent.index);
		if index != -1: #If not probably removed by damaged
			currentTouches[index].touchPosition = dragEvent.position;
	if event is InputEventScreenTouch:
		var touchEvent := event as InputEventScreenTouch;
		if touchEvent.pressed: ##Just pressed touch
			var data:TouchData;
			var index := find_index_in_current_touches(touchEvent.index);
			if index >= 0:
				data = currentTouches[index]
				data.touchPosition = touchEvent.position;
				data.instance.position = touch_position_to_world_position(data.touchPosition);
			else:
				data = TouchData.new()
				data.touchIndex = touchEvent.index;
				data.instance = playerTokenScene.instantiate() as PlayerToken;
				data.health = Health.FindHealth(data.instance as Node, true, false, true);
				if data.health:
					data.health.hit.connect(_on_hit);
				data.touchPosition = touchEvent.position;
				data.instance.position = touch_position_to_world_position(data.touchPosition);
				self.add_child(data.instance);
				if equippedHold:
					equippedHold.start_hold(data);
				currentTouches.push_back(data);
				just_holded.emit(data);
				print("[PLAYER] hi %s (screen %s) (world pos %s) [%s]" % [data.touchIndex, data.touchPosition, data.instance.position, Engine.get_physics_frames()]);
		else: ## Just removed touch
			var index := find_index_in_current_touches(touchEvent.index);
			if index != -1:
				print("[PLAYER] REMOVE TOUCH %s in %s (pressed %s, time: %s miliseconds, is_tap_time: %s) [%s]" % [str(touchEvent.index), touchEvent.position,
						currentTouches[index].pressedInLifetime,
						Time.get_ticks_msec() - currentTouches[index].timeStamp,
						Time.get_ticks_msec() - currentTouches[index].timeStamp <= (tapTime * 1000),
						Engine.get_physics_frames()
						]);
				currentTouches[index].leftInLifetime = true;
				just_released.emit(currentTouches[index]);
				if not currentTouches[index].pressedInLifetime:
					var milisecondsSinceTouch:float = Time.get_ticks_msec() - currentTouches[index].timeStamp;
					if milisecondsSinceTouch <= (tapTime * 1000): ## try tap
						try_tap.emit();
						currentTouches[index].instance.tap_feedback()
						print("[PLAYER] Attempted tap successfully! [%s]" % [Engine.get_physics_frames()])
						var tap = get_current_tap()
						if tap and can_use_tap():
							use_tap.emit(currentTouches[index].instance);
							set_tap_bar(currentState.tap_bar_value - tap.get_tap_cost());
							tap.tap(currentTouches[index], currentTouches[index].instance, currentTouches.size());
							just_tapped.emit(currentTouches[index]);
						else:
							failed_tap.emit()
				_remove_touch(index);
				just_released_after.emit();
			else:
				printerr("[PLAYER] REMOVE TOUCH (BUT TOUCH NOT FOUND %s in %s)" % [str(touchEvent.index), touchEvent.position]);

func can_use_tap()->bool:
	var tap = get_current_tap()
	return tap and currentState.tap_bar_value >= tap.get_tap_cost()

func get_current_tap() -> PlayerWeaponTap:
	return equippedTap

func get_tap_recover_level() -> int:
	return UPGRADE_TAP_SPEED.get_progress()

func lock_touches():
	remove_all_touches()
	_touches_locked = true

func unlock_touches():
	_touches_locked = false

func remove_all_touches() -> void:
	while currentTouches.size() > 0:
		_remove_touch(0)

func _remove_touch(index:int) -> void:
	if index <= -1 or index >= currentTouches.size():
		print("[PLAYER] removing touch out of bounds " + str(index));
		return
	currentTouches[index].instance.end_token();
	if index <= -1 or index >= currentTouches.size():
		printerr("[PLAYER] removing touch out of bounds WHAT " + str(index));
		return
	lastValidTouch = currentTouches[index];
	print("[PLAYER] bye %s (pos:%s)" % [index, currentTouches[index].instance.position]);
	currentTouches.remove_at(index);

func find_touch_data_from_token(token:PlayerToken) -> TouchData:
	for touch in currentTouches:
		if touch.instance == token:
			return touch;
	return null;

func find_index_in_current_touches(index:int) -> int:
	var arrayPos = 0;
	for ct in currentTouches:
		var td = ct as TouchData;
		if(not td):
			continue;
		if(td.touchIndex == index):
			return arrayPos;
		arrayPos = arrayPos + 1;
	return -1;

func find_health_in_current_touches(health:Health) -> int:
	var arrayPos = 0;
	for ct in currentTouches:
		var td = ct as TouchData;
		if(not td):
			continue;
		if(td.health == health):
			return arrayPos;
		arrayPos = arrayPos + 1;
	return -1;

func touch_position_to_world_position(touchPosition:Vector2) -> Vector3:
	var ray_length:float = 100.0;
	var cam = LevelCameraController.main_camera
	var from:Vector3 = cam.project_ray_origin(touchPosition);
	var toRelative:Vector3 = cam.project_ray_normal(touchPosition) * ray_length;

	finger_cast.global_position = from;
	finger_cast.target_position = toRelative;
	finger_cast.force_shapecast_update();

	var results := finger_cast.collision_result;
	var least_distance_sqrd:float = ray_length * ray_length;
	var least_distance_point:Vector3 = Vector3.ZERO;
	if results.size() > 0:
		for c in results:
			var point:Vector3 = c["point"];
			var distance_sqrd:float = point.distance_squared_to(from);

			if distance_sqrd < least_distance_sqrd:
				least_distance_point = point;
		return least_distance_point + toRelative.normalized() * 0.5;
	return groundPlane.intersects_ray(from, toRelative);

func add_weapon(weapon:PlayerWeapon) -> void:
	print("[PLAYER] Add weapon %s" % [weapon]);
	if weapon is PlayerWeaponHold:
		var touch_only_id:PlayerWeapon.WeaponID = PlayerWeapon.WeaponID.TOUCH_ONLY
		if weapon.id == touch_only_id || equippedHold.id == touch_only_id:
			set_hold_level(UPGRADE_HOLD_START.get_progress())
		set_hold_potencial(currentState.hold_level);
		if not is_it_same_weapon(weapon, equippedHold):
			var current_parent = weapon.get_parent()
			if current_parent:
				push_warning("WILL REMOVE CHILD")
				current_parent.remove_child(weapon);
			add_child(weapon);
			equippedHold.queue_free();
			equippedHold = weapon;
			_on_any_weapon_change();
			hold_equipped_change.emit();

	elif weapon is PlayerWeaponTap:
		add_tap(weapon)

	_on_any_equipment_powerup();
	try_add_equipment.emit();

func downgrade_weapon_hold() -> void:
	set_hold_level(currentState.hold_level - 1);
	set_hold_potencial(currentState.hold_level);

func downgrade_weapon_tap() -> void:
	var removed_tap:PlayerWeaponTap = equipped_taps.pop_front()
	if !is_instance_valid(removed_tap):
		return
	removed_tap.queue_free()

	if equipped_taps.size() <= 0:
		equippedTap = null

	var tap_bar_max:float = 0
	for tap in equipped_taps:
		tap_bar_max += tap.get_tap_cost()

	currentState.tap_bar_max = tap_bar_max
	currentState.tap_level = equipped_taps.size()

	charge_tap_bar_fully()
	tap_level_change.emit(currentState.tap_level);
	tap_equipped_change.emit()
	_on_any_weapon_change();

func upgrade_hold_firerate_level():
	currentState.hold_fire_rate_level += 1
	_on_any_equipment_powerup();
	_on_any_weapon_change()

func downgrade_hold_firerate_level():
	currentState.hold_fire_rate_level -= 1
	if currentState.hold_fire_rate_level < 0:
		currentState.hold_fire_rate_level = 0
	_on_any_weapon_change()

func upgrade_hold_warmup_level():
	currentState.hold_warm_up_level += 1
	_on_any_equipment_powerup();
	_on_any_weapon_change()

func downgrade_hold_warmup_level():
	currentState.hold_warm_up_level -= 1
	if currentState.hold_warm_up_level < 0:
		currentState.hold_warm_up_level = 0
	_on_any_weapon_change()

func add_extra_shot_level(add:int):
	if add == 0:
		return

	currentState.extra_shot_level += add
	_on_any_equipment_powerup();
	_on_any_weapon_change()

#Check if the same weapon is being added twice, and that is should level up. Or not.
func is_it_same_weapon(wpn1:PlayerWeapon, wpn2:PlayerWeapon) -> bool:
	if (wpn1 && !wpn2) || (wpn2 && !wpn1): return false
	return wpn1.id == wpn2.id;

func heal(amount:int, if_maxed_increase_max_health:bool = true):
	hp += amount
	if hp > maxHP and if_maxed_increase_max_health:
		maxHP = hp
	hp_change.emit(hp, Vector3.ZERO)
	_on_any_equipment_powerup();

func _on_hit(d:Health.DamageData, h:Health) -> void:
	print("[PLAYER] Took damage! Immune? %s or %s by %s on %s" % [
		DevManager.is_player_imune(), immunity_count > 0, d, h,
	]);
	if DevManager.is_player_imune(): return
	if immunity_count <= 0:
		var indexHealth = find_health_in_current_touches(h);
		if indexHealth != -1:
			var touch:TouchData = currentTouches[indexHealth]
			finger_took_damage.emit(touch.instance)
			damage(1, touch.instance.global_position)
			_remove_touch(indexHealth);
		else:
			damage(1)

func damage(amount:int = 1, damage_world_position:Vector3 = Vector3.INF):
	hp -= amount;
	immunity_count = immunity_time;
	set_hold_potencial(0);
	hp_change.emit(hp, Vector3.ZERO);
	if HUD.instance:
		HUD.instance.make_screen_effect(HUD.ScreenEffect.Damaged, damage_world_position);
	if Game.instance:
		Game.instance.kill_all_projectiles();
	if hp <= 0:
		dead.emit();

func get_ground_plane_position(touchPosition:Vector2) -> Vector3:
	var ray_length:float = 100.0;
	var cam = LevelCameraController.main_camera
	var from:Vector3 = cam.project_ray_origin(touchPosition);
	var toRelative:Vector3 = cam.project_ray_normal(touchPosition) * ray_length;
	return groundPlane.intersects_ray(from, toRelative);


func kill():
	damage(hp);
