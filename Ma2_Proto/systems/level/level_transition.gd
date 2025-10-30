class_name LevelTransition extends Switch_Oning_Offing_AnimationPlayer

@export var progress_bar:ProgressBar
@export var inform_ended_as_soon_as_outing:bool = true
@export var input_blocker:Control

var may_transition:bool = false

func _enter_tree() -> void:
	turned_on.connect(set_may_transition)

func transition_in(level_info:LevelInfo):
	if LevelManager.is_transitioning:
		push_warning("[Level Transition] Trying to transition when already trasitioning. Will ignore")
		queue_free()
	input_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	LevelManager.inform_transition_started()
	set_switch(true)
	may_transition = false
	while !may_transition:
		await get_tree().process_frame
	transition_out(level_info)

func set_may_transition():
	may_transition = true

func transition_out(level_info:LevelInfo):
	LevelManager.change_level_by_info(level_info)
	await LevelManager.level_started
	set_switch(false)
	if inform_ended_as_soon_as_outing:
		LevelManager.inform_transition_ended()
		input_blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	await turned_off
	queue_free()
	if !inform_ended_as_soon_as_outing:
		input_blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		LevelManager.inform_transition_ended()

func _process(delta: float) -> void:
	if progress_bar:
		if LevelManager.is_transitioning:
			progress_bar.value = LevelManager.loading_progress[0]
		else:
			progress_bar.value = 0
