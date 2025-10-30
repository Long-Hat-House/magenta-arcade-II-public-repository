extends Level

const ENEMY_CRAZY_CAR = preload("res://elements/enemy/crazy_car/enemy_crazy_car.tscn")

const CHALLENGE_TRAFFIC_CRAZY = preload("res://systems/challenge/challenges/challenge_traffic_crazy.tres")
const CHALLENGE_TRAFFIC_EASY = preload("res://systems/challenge/challenges/challenge_traffic_easy.tres")

const ENEMY_ROBOTO_COPTER = preload("res://elements/enemy/copter/enemy_roboto_copter.tscn")
enum Style{
	Easy,
	Crazy
}

@export var style:Style = Style.Easy

@export var street_pieces:Array[PackedScene]
@export var message_semaphor:String = "challenge_traffic_semaphor"

var _wait_group = "cars"

func _ready() -> void:
	await await_for_level_ready()
	stage.set_pivot_offset(Vector3.ZERO)
	stage.repivot();

	match style:
		Style.Easy:
			traffic_easy()
		Style.Crazy:
			traffic_crazy()

func traffic_easy():
	cmd_array([
		CMD_Callable.new(func():
			stage.fill_with(street_pieces, 10);
			stage.set_pivot_offset_x(-6);
			stage.repivot();
			_create_street();
			cam.tween_position(stage.get_pos_x(), 2, LevelCameraController.MovementAxis.X);
			),
		CMD_Wait_Seconds.new(1),
	], false)

	scene_traffic_template(CHALLENGE_TRAFFIC_EASY, [5, -1, 3], 1.5, 1);

func traffic_crazy():
	cmd_array([
		CMD_Callable.new(func():
			stage.fill_with(street_pieces, 10);
			stage.set_pivot_offset_x(6);
			stage.repivot();
			_create_street();
			cam.tween_position_vector(stage.get_grid(0,0), 2);
			#cam.tween_position_vector(stage.get_grid(0,0), 2);
			),
		CMD_Wait_Seconds.new(1.8),
	], false)

	scene_traffic_template(CHALLENGE_TRAFFIC_CRAZY, [-5, 3], 1.75, 0.75, func(car):
		car.turn_target_getter = func():
			if Player.instance.currentTouches.size() > 0:
				return Player.get_closest_position(car.global_position);
			else:
				return car.global_position + Vector3.BACK * 10;
		)

func _create_street():
	stage.fill_with(street_pieces, 100);

func scene_traffic_template(challenge_info:ChallengeInfo, lastCarsPosition:Array[float], time_between_cars_first:float, time_between_cars_challenge:float, everyCar:Callable = Callable()):
	var trafficID:Array[int] = [-3, 0];

	var sequence_of_last_cars:Array[CMD] = [];
	for dist in lastCarsPosition:
		sequence_of_last_cars.append(CMD_Callable.new(func():
			var car1 = objs.create_object(ENEMY_CRAZY_CAR, _wait_group, cam.get_stage_grid_pos(stage, -dist, -1));
			var car2 = objs.create_object(ENEMY_CRAZY_CAR, _wait_group, cam.get_stage_grid_pos(stage, dist, -5));
			if everyCar:
				everyCar.call(car1);
				everyCar.call(car2);
			));
		sequence_of_last_cars.append(CMD_Wait_Seconds.new(time_between_cars_challenge));

	var create_car = func create_car():
		var car = objs.create_object(ENEMY_CRAZY_CAR, _wait_group, cam.get_stage_grid_pos(stage, trafficID[0], -1));
		if everyCar: everyCar.call(car);
		if trafficID[1] < 4:
			trafficID[0] = ((trafficID[0] + 3 + 4) % 8) - 4; ##add 3 and 2 between -4 and 4?
		else:
			trafficID[0] = ((trafficID[0] + 4 + 2) % 8) - 4; ##add 2 and 2 between -4 and 4?
		trafficID[1] += 1;

	cmd_array([
		cam.cmd_speed(-2, 3, LevelCameraController.MovementAxis.Z, Tween.TRANS_CIRC, Tween.EASE_OUT),
		CMD_Wait_Seconds.new(0.09),
		CMD_Sequence.new([
			CMD_Callable.new(create_car),
			CMD_Wait_Seconds.new(time_between_cars_first),
			CMD_Callable.new(create_car),
			#CMD_Wait_Seconds.new(time_between_cars_first),
			#CMD_Callable.new(create_car),
		]),
		cam.cmd_speed(0, 12, LevelCameraController.MovementAxis.Z, Tween.TRANS_SINE, Tween.EASE_OUT),
		ChallengeController.instance.cmd_begin(challenge_info),
		DisplaySemaphor.cmd_semaphor(self, message_semaphor,
			## Semaphor condition
			func(): return Player.instance.currentTouches.size() > 0,
			## The semaphor
			CMD_Sequence.new([
				CMD_Callable.new(func(): trafficID[1] = 0),
				cam.cmd_speed(-5, 2, LevelCameraController.MovementAxis.Z, Tween.TRANS_CIRC, Tween.EASE_OUT),

				CMD_Parallel_Complete.new([
					## The cars
					CMD_Sequence.new([
						CMD_Callable.new(create_car),
						CMD_Wait_Seconds.new(time_between_cars_challenge),
					], 8),

					## The copters
					CMD_Sequence.new([
						AI_Roboto_Copter.cmd_make_copters_quick(self, [ENEMY_ROBOTO_COPTER], [1,1,1,1,1,1,1],
								cam.get_stage_grid_pos.bind(stage, -7,-6), Vector3.RIGHT, [8,-5]),
						CMD_Wait_Seconds.new(time_between_cars_challenge * 5),

						AI_Roboto_Copter.cmd_make_copters_quick(self, [ENEMY_ROBOTO_COPTER], [1,1,1,1,1,1,1],
								cam.get_stage_grid_pos.bind(stage, 7,-6), Vector3.LEFT, [-8,4]),
					]),
				]),

				CMD_Sequence.new(sequence_of_last_cars),
				CMD_Wait_Seconds.new(1),
				objs.cmd_wait_group(_wait_group),
			]),
			## On success
			CMD_Sequence.new([
				#cam.cmd_speed(0, 2, LevelCameraController.MovementAxis.Z),
				CMD_Callable.new(
					func():
						stage.repivot()
						cam.tween_position(stage.get_pos_z(), 2, LevelCameraController.MovementAxis.Z)
						),
				ChallengeController.instance.cmd_victory(challenge_info, 2)
			]),
			## On fail
			CMD_Sequence.new([
				cam.cmd_speed(0, 2, LevelCameraController.MovementAxis.Z),
				ChallengeController.instance.cmd_fail(challenge_info),
			]),
			1.25
		),
		CMD_Wait_Seconds.new(0.75),
	], false);
