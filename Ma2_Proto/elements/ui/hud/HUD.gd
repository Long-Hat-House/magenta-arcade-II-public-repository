class_name HUD extends Control

static var instance:HUD;

@export_group("boss")
@export var _boss_hud_animation:Switch_Oning_Offing_AnimationPlayer
@export var _boss_label:Label
@export var _boss_progress:ProgressBar
@export var _boss_progress_curve:Curve
@export var _boss_icon:TextureRect
@export var _boss_presentation_label:Label

@export_group("screen effects")
@export var alpha:ColorRect
@export var add:ColorRect
@export var damage_vfx_scene:PackedScene

@export_group("timer")
@export var timer:HUD_Timer

@export_group("level")
@export var _level_show_animation:AnimationPlayer
@export var _level_name_label:Label
@export var _level_to_set_sign_color:Control

@export_group("instantiate places")
@export var instantiate_place_center:Control;
@export var instantiate_place_high_center:Control;

const boss_flash_duration:float = 8;
const post_boss_flash_duration:float = 1.3;

var _boss_life_getter:Callable;

func _ready()->void:
	LevelManager.removing_current_level.connect(queue_free)
	instance = self;
	hide()

	await get_tree().process_frame
	set_callbacks()
	reparent(LevelManager)

func _process(delta:float) -> void:
	if _boss_life_getter.is_valid():
		var value:float = _boss_life_getter.call();
		if _boss_progress_curve: value = _boss_progress_curve.sample(value);
		_boss_progress.value = _boss_life_getter.call();

func set_callbacks() -> void:
	var player:Player = Player.instance

	if !player:
		return

	show()

enum ScreenEffect{
	ShortFlash,
	LongFlash,
	PowerupFlash,
	Damaged,
	BossDeath
}

func set_seconds_in_game(seconds_in_game:float):
	if timer:
		timer.set_timer(seconds_in_game);

var current_screen_fx_tween:Tween;

func cancel_current_screen_effect():
	if current_screen_fx_tween and current_screen_fx_tween.is_running():
		current_screen_fx_tween.kill();

func make_screen_add(from:Color, to:Color, duration:float, ease:Tween.EaseType = Tween.EASE_IN, trans:Tween.TransitionType = Tween.TRANS_SINE, deactivate_after:bool = true):
	cancel_current_screen_effect();
	add.color = from;
	alpha.color = Color(0,0,0,0);
	current_screen_fx_tween = create_tween();
	current_screen_fx_tween.tween_property(add, "color", to, duration).set_ease(ease).set_trans(trans);

	add.visible = true;
	await current_screen_fx_tween.finished;

	if deactivate_after:
		current_screen_fx_tween = null;
		deactivate_all_over_screen();

func deactivate_all_over_screen():
	add.visible = false;
	alpha.visible = false;

func make_screen_effect(effect:ScreenEffect, effect_world_position:Vector3 = Vector3.INF):
	cancel_current_screen_effect();
	current_screen_fx_tween = create_tween();
	match effect:
		ScreenEffect.ShortFlash:
			add.color = Color(0.8,0.8,0.8,0.25);
			alpha.color = Color(0,0,0,0);
			current_screen_fx_tween.tween_property(add, "color", Color(0.8,0.8,0.8,0), 0.325).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE);
		ScreenEffect.PowerupFlash:
			add.color = Color(0.925,0.925,0.975,0.65);
			alpha.color = Color(0,0,0,0);
			current_screen_fx_tween.tween_property(add, "color", Color(0.8,0.8,0.8,0), 0.525).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE);
		ScreenEffect.LongFlash:
			add.color = Color(1,1,1,1);
			alpha.color = Color(0,0,0,0);
			current_screen_fx_tween.tween_property(add, "color", Color(1,1,1,0), 1).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE);
		ScreenEffect.Damaged:
			add.color = Color(0,0,0,0);
			alpha.color = Color(1,0,1,.5);
			current_screen_fx_tween.tween_property(alpha, "color", Color(1,0,1,0), 2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC);
			#current_screen_fx_tween.tween_property(add, "color", Color(0,0,0,0), 1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE);
			TimeManager.frame_freeze(.5, 0)
			TimeManager.frame_freeze(1)
			if effect_world_position != Vector3.INF:
				if damage_vfx_scene:
					var vfx = damage_vfx_scene.instantiate()
					LevelManager.add_child(vfx)
					if vfx is Control:
						vfx.global_position = LevelCameraController.instance.world_to_screen_position(effect_world_position)
		ScreenEffect.BossDeath:
			add.color = Color(0.5,0.5,0.65,0);
			alpha.color = Color(0,0,0,0);
			current_screen_fx_tween.tween_property(add, "color", Color(1,1,1,1), boss_flash_duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE);
			current_screen_fx_tween.tween_property(add, "color", Color(1,1,1,0), post_boss_flash_duration - 0.05).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUINT).set_delay(0.05);

	add.visible = true;
	alpha.visible = true;
	current_screen_fx_tween.tween_callback(func():
		self.current_screen_fx_tween = null;
		deactivate_all_over_screen();
		)

func show_boss_life(boss_info:BossInfo, life_getter_percentage:Callable, boss_music:int = AK.EVENTS.MUSIC_BOSS_START):
	if _boss_hud_animation.is_set_to_on():
		return
	_boss_life_getter = life_getter_percentage
	_boss_label.text = boss_info.boss_id
	_boss_presentation_label.text = boss_info.boss_presentation_text
	_boss_icon.texture = boss_info.boss_icon
	_boss_hud_animation.set_switch(true)
	AudioManager.post_music_event(boss_music)

func hide_boss_life():
	_boss_life_getter = Callable();
	_boss_hud_animation.set_switch(false)

func show_boss_death(pauses_timer:bool = true, custom_audio_event:int = AK.EVENTS.MUSIC_STOP):
	hide_boss_life()
	AudioManager.post_music_event(custom_audio_event)

	if pauses_timer && is_instance_valid(Game.instance):
		Game.instance.pause_timer()

func show_level_info(info:LevelInfo):
	_level_name_label.text = info.lvl_id
	_level_to_set_sign_color.self_modulate = info.lvl_color
	_level_show_animation.play("show")
	if is_instance_valid(Game.instance):
		Game.instance.release_timer()
