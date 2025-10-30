class_name ChallengePanelVictory  extends ChallengePanel

@export var _title:Label
@export var _text:Label

@export var _altar_scene:PackedScene

var _altars:Array[GenericAltar]
var _default_grid_positions:Array[Vector2i] = [Vector2(-3,22),Vector2(0, 18),Vector2(3,22)]
var _default_y_rotations:Array[float] = [5,0,-5]

func set_info(info:ChallengeInfo, grid_positions:Array[Vector2i], create_altars:bool = true):

	_title.text = info.challenge_victory_title
	_text.text = info.challenge_victory_subtitle

	if create_altars:
		make_altars(info, grid_positions);
	
	
		
func make_altars(info:ChallengeInfo, grid_positions:Array[Vector2i]):
	if grid_positions.size() <= 0:
		grid_positions = _default_grid_positions

	var i:int = 0
	var prev_altar:GenericAltar = null
	for a in _altars:
		if is_instance_valid(a):
			a.queue_free()
	_altars.clear()
	for scene in info.scene_prizes:
		if grid_positions.size() > i:
			var grid:Vector2i = grid_positions[i]
			var rotation:float = _default_y_rotations[i] if _default_y_rotations.size() > i else 0.0
			var altar:GenericAltar = LevelObjectsController.instance.create_object(
				_altar_scene, "", LevelStageController.instance.get_grid(grid.x, grid.y)) as GenericAltar
			if altar:
				altar.rotate_y(deg_to_rad(rotation))
				altar.add_obj(scene.instantiate())
				altar.obj_hold_finished.connect(panel_hide)
				if prev_altar:
					prev_altar.connect_altar(altar)
				prev_altar = altar
				_altars.append(altar)
		i+=1

func panel_show():
	super.panel_show()
	open_altars();
		
func open_altars():
	for altar in _altars:
		altar.start_altar()
	
