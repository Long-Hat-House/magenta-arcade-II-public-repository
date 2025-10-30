extends Light3D

@export var gradientBegin:GradientTexture1D;
@export var gradientBeginForce:Curve;
@export var gradientEnd:GradientTexture1D;
@export var animationTime:float;

var gradient:GradientTexture1D;
var tweenTime:float = 0;
var oldTweenTime:float;

# Called when the node enters the scene tree for the first time.
func _ready():
	var tween := self.create_tween();
	gradient = gradientBegin;
	tween.tween_property(self, "tweenTime", 1, animationTime);
	await tween.finished;

func _process(delta:float):
	if gradient and oldTweenTime != tweenTime:
		print("tweenTime is %s, point is %s (from %s)" % [tweenTime, gradient.gradient.sample(tweenTime), gradient.gradient.get_point_count()])
		self.light_color = gradient.gradient.sample(tweenTime);
		self.light_energy = gradientBeginForce.sample(tweenTime);
		oldTweenTime = tweenTime;
