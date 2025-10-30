class_name GameOverLineStarsAll extends GameOverLine

@export var groups:Array[GameOverLineStarAllGroup]
var _current_star:int = 0

func add_star(target_score:int, is_unlocked:bool, is_new:bool):
	var anim_style:GameOverLineStarAllGroup.AnimStyle = GameOverLineStarAllGroup.AnimStyle.Off
	if is_new: anim_style = GameOverLineStarAllGroup.AnimStyle.New
	elif is_unlocked: anim_style = GameOverLineStarAllGroup.AnimStyle.On

	groups[_current_star].set_value(StarInfo.get_score_text(target_score), anim_style)
	_current_star += 1

func line_show():
	_animation.set_switch(true)
	await _animation.turned_on

	for c in groups:
		c.animate()
		while c.is_animating():
			await get_tree().process_frame
			if !is_instance_valid(self) || _show_finished: return

	set_show_finished()

func skip():
	for c in get_children():
		if c is GameOverLineStarAllGroup:
			c.skip()

	super.skip()
