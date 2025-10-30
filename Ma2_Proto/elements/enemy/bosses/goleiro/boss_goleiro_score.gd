class_name Boss_Goleiro_Placar extends LHH3D

@export var score_text_template:String = "%s | %s"
@onready var label: Label3D = $Label3D
@onready var mouth: Label3D = $Mouth;

var friend_score:int;
var foe_score:int;

var dead_left:Array[String] = [">", ">", "x", "X", "x", "X", "ó", "U"]
var dead_right:Array[String] = ["<", "<", "x", "X", "x", "X", "ò", "U"]

var idle_humor:Array[String] = ["3", "D", "}", ")" ,"/", "l" ,"(", "c", "C", "u"];
var random_humor:Array[String] = ["|", "3", "o", "B", "^", "b", "P"]
var surprise_humor:Array[String] = ["o", "O", "0"]
var current_humor:int = 2;

func _ready() -> void:
	set_score(friend_score, foe_score);
	set_label(idle_humor[current_humor]);

func dead():
	label.text = score_text_template % ["X", "X"];
	var tween := create_tween();
	tween.tween_interval(0.25);
	tween.tween_callback(func():
		label.text = score_text_template % [dead_left.pick_random(), dead_right.pick_random()];
		);
	tween.set_loops(-1);

func hurt():
	label.text = score_text_template % [">", "<"];
	var tween := create_tween();
	tween.tween_interval(0.25);
	tween.tween_callback(func():
		label.text = score_text_template % ["x", "X"];
		)
	tween.tween_interval(0.45);
	tween.tween_callback(func():
		label.text = score_text_template % ["X", "x"];
		)
	tween.tween_interval(0.65);
	tween.tween_callback(func():
		set_score(friend_score, foe_score);
		)

func do_something():
	change_to_array(["", random_humor.pick_random(), "",  mouth.text]);
	
func do_surprise():
	label.text = score_text_template % [">", "<"]
	change_to_array(["", surprise_humor.pick_random(), surprise_humor.pick_random(), surprise_humor.pick_random(), "", mouth.text]);
	change_tween.tween_callback(func():
		set_score(friend_score, foe_score);
		)

func increase_humor(amount:int):
	var humor:int = current_humor;
	current_humor = (current_humor + amount) % idle_humor.size();
	if humor != current_humor:
		var arr:Array[String] = [""];
		while humor != current_humor:
			humor = int(move_toward(humor, current_humor, 1));
			arr.push_back(idle_humor[humor]);
		change_to_array(arr, 0.1);
	
	
func add_score(boss_score:int, player_score:int):
	friend_score += boss_score;
	foe_score += player_score;
	set_score(friend_score, foe_score);
	increase_humor(player_score * randi_range(1, 3) - boss_score * randi_range(1, 4));
	punch();

func set_score(friend:int, foe:int):
	label.text = score_text_template % [friend, foe];
	
func punch():
	var tween := create_tween();
	var duration:float = 1;
	tween.tween_property(label, "scale", Vector3.ONE * 1.2, 0.1 * duration);
	tween.tween_property(label, "scale", Vector3.ONE * 1.0, 0.9 * duration);
	

var change_tween:Tween;
func change_to_array(arr:Array[String], duration_flash:float = 0.225):
	if change_tween and change_tween.is_running():
		await change_tween.finished;
	change_tween = create_tween();
	for s in arr:
		change_to_tweener(change_tween, s, duration_flash);
	
func change_to_tweener(tween:Tween, s:String, duration:float):
	tween.tween_callback(set_label.bind(s));
	tween.tween_interval(duration);
	
	
func set_label(s:String):
	mouth.text = s;
