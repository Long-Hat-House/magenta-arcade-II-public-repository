class_name EndingSequence extends Control

@export var ending_map:Sprite3D;
@export var ending_explosion:SpawnArea;
@export var ending_shake:Node3DShaker;
@export var black_screen_over:ColorRect;

var in_sequence:bool;

func _ready() -> void:
	visible = false;
	
func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_7) and !in_sequence:
		ending_sequence();

func ending_sequence():
	in_sequence = true;
	visible = true;
	HUD.instance.deactivate_all_over_screen();
	
	black_screen_over.visible = true;
	black_screen_over.color = Color.WHITE;
	
	ending_shake.shake_amplitude_ratio = 0.0;
	ending_map.position.y = -0.2;
	var orig_scale := ending_map.scale;
	ending_map.scale *= 2;
	
	var t:= create_tween();
	t.tween_property(ending_map, "position:y", 0.0, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD);
	t.parallel().tween_property(black_screen_over, "color", Color(0.1,0.1,0.1,0), 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD);
	t.parallel().tween_property(ending_map, "scale", orig_scale, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC);
	t.tween_interval(1.0);
	t.tween_property(ending_shake, "shake_amplitude_ratio", 1.0, 1);
	t.tween_callback(func():
		ending_explosion.spawn_tween(20, 1.5).finished.connect(func():
			ending_explosion.spawn_tween(100,6, Tween.EASE_IN_OUT, Tween.TRANS_LINEAR).set_loops(-1);
			);
		
		black_screen_over.visible = true;
		black_screen_over.color.a = 0;
		);
	t.tween_interval(2.5);
	t.tween_property(black_screen_over, "color:a", 1.0, 3.5).set_ease(Tween.EASE_IN_OUT);
	t.tween_interval(4);
	await t.finished;
	in_sequence = false;
