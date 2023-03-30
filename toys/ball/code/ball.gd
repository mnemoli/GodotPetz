extends RigidBody2D

var held = false
var last_pos = Vector2.ZERO

func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		freeze = true
		held = true
		$AnimatedSprite2D.animation = "rest"

func _on_sleeping_state_changed():
	if sleeping:
		$AnimatedSprite2D.pause()

func _process(delta):
	var bounds = get_viewport_rect().size
	if held:
		var mp = get_global_mouse_position()
		if mp.x > 0 and mp.x < bounds.x and mp.y > 0 and mp.y < bounds.y:
			last_pos = mp
			global_transform.origin = last_pos
	else:
		$AnimatedSprite2D.speed_scale = linear_velocity.length() / 100.0
		if !Rect2(Vector2.ZERO, bounds).has_point(global_position):
			var vec_back_to_screen = (bounds/2.0 - global_position)
			apply_central_force(vec_back_to_screen / 3)

func _unhandled_input(event):
	if event is InputEventMouseButton and !event.pressed and held:
		freeze = false
		held = false
		var vec = get_global_mouse_position() - last_pos
		$AnimatedSprite2D.animation = "used1"
		$AnimatedSprite2D.play()
		vec.clamp(Vector2(200,200), Vector2(300,300))
		apply_central_impulse(vec * 3)
