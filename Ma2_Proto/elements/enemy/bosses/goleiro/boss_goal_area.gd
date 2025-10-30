extends Area3D

@export var allied:bool;
@export var goal_center:Node3D;
@export var ball_spawn_position:Node3D;
@export var final_jump_to_neutral_height:float= 40;
@export var final_jump_duration:float = 1.5;
@export var time_to_center:float = 1;
@export var delay_after_center:float = 0.6;
@export var task_before_goal:Task;
@export var task_after_goal:Task;

func _on_body_entered(body: Node3D) -> void:
	print("body entered %s! %s" % [self, body])
	if body is Boss_Goleiro_Ball:
		body.set_active(false);
		await body.create_tween().tween_property(body, "global_position", 
				goal_center.global_position, time_to_center)\
				.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)\
				.finished;
		if is_not_ok(): return;
		
		await get_tree().create_timer(delay_after_center).timeout;
		if is_not_ok(): return;
		
		if task_before_goal:
			await task_before_goal.start_task();
			if is_not_ok(): return;
			
		body.goal(allied);
		if task_after_goal:
			await task_after_goal.start_task();
			if is_not_ok(): return;
			
		var t:Tween = body.create_tween();
		TransformUtils.tween_jump_global(
				body, 
				t, 
				ball_spawn_position.global_position, 
				Vector3.UP * final_jump_to_neutral_height, 
				final_jump_duration
				)

func is_not_ok()->bool:
	return !is_instance_valid(self) and self.get_parent() != null;
