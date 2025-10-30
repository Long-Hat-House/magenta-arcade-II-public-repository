class_name ChallengePanelMetrics extends ChallengePanel

@export var _displays_container:Control
@export var _displays_parent:Control
@export var _particles_container:Control

func _ready() -> void:
	super._ready()
	for child in _displays_container.get_children():
		child.queue_free()


func panel_show():
	super.panel_show()
	_displays_parent.visible = _displays_container.get_child_count() > 0

	for particle in _particles_container.get_children():
		if particle is CPUParticles2D:
			particle.emitting = true
		if particle is GPUParticles2D:
			particle.emitting = true

func add_metric_display(instance:Control):
	_displays_container.add_child(instance)

func hide_and_clear():

	for particle in _particles_container.get_children():
		if particle is CPUParticles2D:
			particle.emitting = false
		if particle is GPUParticles2D:
			particle.emitting = false

	panel_hide()

	for child in _displays_container.get_children():
		child.queue_free()
