extends Control
class_name ModelTester

# Exposed variables
@export var modelInfos : Array[ModelInfo] = [] # List of scenes/models with names
@export var parentContainer : Node3D = null # Parent container for models
@export var modelSelectButton : OptionButton = null
@export var animationSelectButton : OptionButton = null

# Internal variables
var currentModelInstance : Node3D = null
var currentAnimationPlayer : AnimationPlayer = null

# Called when the node enters the scene tree for the first time.
func _ready():
	#get_tree().root.size = Vector2(2048,2948);
	get_tree().root.content_scale_size = Vector2(3641,2048);
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT;
	
	# Fill modelSelectButton with options from the modelInfos array
	for modelInfo in modelInfos:
		modelSelectButton.add_item(modelInfo.name, modelInfos.find(modelInfo))
		
	on_model_selected(0);
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
# Event handler for model selection
func on_model_selected(index):
	var selectedModelInfo = modelInfos[index]
	
	# Remove current model if exists
	if currentModelInstance != null:
		currentModelInstance.queue_free()

	# Instantiate selected model as a child of the parent container
	currentModelInstance = selectedModelInfo.scene.instantiate()
	parentContainer.add_child(currentModelInstance)

	# Populate animations for the selected model
	currentAnimationPlayer = null;
	
	for child in currentModelInstance.get_children():
		if child is AnimationPlayer:
			currentAnimationPlayer = (child as AnimationPlayer)

	_update_animation_options()
	
# Event handler for animation selection
func on_animation_selected(index):
	if currentModelInstance != null and currentAnimationPlayer != null:
		var selectedAnimation = currentAnimationPlayer.get_animation_list()[index]
		currentAnimationPlayer.play(selectedAnimation)

# Function to update animation options in the UI
func _update_animation_options():
	# Clear previous options
	animationSelectButton.clear()

	# Add animations to the OptionsButton
	if currentAnimationPlayer == null:
		animationSelectButton.disabled = true;
	else:
		animationSelectButton.disabled = false;
		var i = 0
		for anim in currentAnimationPlayer.get_animation_list():
			animationSelectButton.add_item(anim, i)
			i = i + 1

func takeScreenshot():
	await Engine.get_main_loop().process_frame;
	var img = self.get_viewport().get_texture().get_image()
	img.save_png("res://devlocal/screenshots/screenshot.png")
