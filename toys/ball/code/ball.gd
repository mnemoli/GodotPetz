extends Toy

func _process(delta):
	super(delta)
	if toy_state == ToyState.DEFAULT:
		$AnimatedSprite2D.speed_scale = linear_velocity.length() / 100.0

