class_name Holdable
extends Pressable

signal button_hold_finished;

enum HoldFinishedMode {
	DESTROY,
	RESET,
	WAIT_NEXT_PRESS,
	QUEUE_FREE,
}

@export var animation_loops:int = 3;
@export var hold_finished_mode:HoldFinishedMode;
@export var vfx_destroy:PackedScene;
@export var vfx_hold_finished:PackedScene;
@export var condition_to_exist:Condition;
@export var condition:Condition;
@export var condition_needs_true_so_label_appears = false;
@export var condition_true_task:Task;
@export var condition_false_task:Task;
@export var button_pressed_feedback: HoldableChargingFeedback
@export var button_graphic : HoldableButtonGraphic
@export var queue_free_on_exit_screen:bool = true;
@export var score_giver_on_finish:ScoreGiver
@export var screen_notifier:VisibleOnScreenNotifier3D

@export_category("cost")
@export var _initial_cost:int = 0
@export var _coins_changer_tag:CoinsChangerTag

var waiting_next_press:bool
var loops:int = 0;

func protect_against_leaving_screen():
	queue_free_on_exit_screen = false;

func set_cost(cost):
	if _coins_changer_tag:
		_initial_cost = cost #just in case it's set before enter tree
		_coins_changer_tag.set_change_amount(-cost)

func _start_pressing(p:Player.TouchData):
	waiting_next_press = false
	loops = 0;
	button_graphic.btn_graphic_press();
	if _coins_changer_tag:
		_coins_changer_tag.start_interacting()
		if !_coins_changer_tag.check_enough_coins():
			return
	if animation_loops < 0:
		return
	button_pressed_feedback.set_pressed(true);

func _end_pressing(p:Player.TouchData):
	loops = 0;
	waiting_next_press = false
	button_graphic.btn_graphic_unpress();
	button_pressed_feedback.set_pressed(false);
	if _coins_changer_tag:
		_coins_changer_tag.stop_interacting()

var readied:bool;
func _ready()->void:
	readied = true;
	button_pressed_feedback.looped.connect(on_animation_looped);

func _enter_tree() -> void:
	if _coins_changer_tag:
		_coins_changer_tag.set_change_amount(-_initial_cost)

	if not readied:
		await self.ready;
	if condition:
		check_condition_graphic();
		condition.condition_changed_set.connect(check_condition_graphic_set);
		
	if condition_to_exist:
		if not condition_to_exist.is_condition():
			_clean_queue_free();
		

func _exit_tree() -> void:
	if condition:
		condition.condition_changed_set.disconnect(check_condition_graphic_set);

func on_animation_looped():
	loops += 1;
	if loops % animation_loops == 0:
		finish_holding();

func check_condition_graphic()->void:
	check_condition_graphic_set(condition.is_condition());

func check_condition_graphic_set(cond:bool):
	if is_instance_valid(button_graphic):
		button_graphic.set_full_graphic(cond == condition_needs_true_so_label_appears);

func _pressing_process(touch:Player.TouchData, delta:float):
	if waiting_next_press:
		return

func finish_holding() -> void:
	if !_coins_changer_tag || _coins_changer_tag.do_change():
		button_hold_finished.emit()
		if vfx_hold_finished:
			InstantiateUtils.InstantiateInTree(vfx_hold_finished, self)

		if score_giver_on_finish:
			score_giver_on_finish.give_score()

		if condition:
			if condition.is_condition():
				if condition_true_task:
					condition_true_task.start_task();
			else:
				if condition_false_task:
					condition_false_task.start_task();
		else:
			if condition_false_task:
				condition_false_task.start_task();
			elif condition_true_task:
				condition_true_task.start_task();

		match hold_finished_mode:
			HoldFinishedMode.DESTROY:
				destroy();
			HoldFinishedMode.RESET:
				loops = 0;
			HoldFinishedMode.WAIT_NEXT_PRESS:
				waiting_next_press = true
				button_pressed_feedback.set_pressed(false);
			HoldFinishedMode.QUEUE_FREE:
				_clean_queue_free()
	else:
		waiting_next_press = true
		button_pressed_feedback.set_pressed(false);

func destroy():
	if vfx_destroy:
		InstantiateUtils.InstantiateInTree(vfx_destroy, self);
	_clean_queue_free();

func _clean_queue_free():
	_sfx_released = null
	button_pressed_feedback.set_pressed(false);
	self.queue_free();

func _on_area_3d_body_entered(body):
	self.add_touched(body);

func _on_area_3d_body_exited(body):
	self.remove_touched(body);

func _on_visible_on_screen_notifier_3d_screen_exited():
	if queue_free_on_exit_screen:
		_clean_queue_free();
