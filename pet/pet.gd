extends Node2D

@export var draw_scale = 0.5;
var current_frame = -1;
var start_frame = 0
var frames_length = 20
var ball_rotation = 0
var target_location = null
var last_chest_pos = Vector3.ZERO
var turn_delta = 0
var reset = false
var belly_position = Vector3.ZERO
var loop = false
@onready var rottext = get_tree().root.get_node("Root/CanvasLayer/Rot") as Label

signal animation_done

func _ready():
	var frame_balls = ContentLoader.animations.get_frame(0).ball_array
	var chest_ball = frame_balls[6]
	last_chest_pos = chest_ball.position

func custom_sort(a: Dictionary, b: Dictionary):
	return a.pos.z < b.pos.z

func _draw():
	if current_frame > -1:
		var this_turn_delta = turn_delta
		$ForwardLine.points = [Vector2.ZERO, Vector2.LEFT.rotated(deg_to_rad(ball_rotation)) * 50.0]
		if target_location != null and turn_delta > 0:
			this_turn_delta = get_next_turn_delta()
			rottext.text = str(ball_rotation) + "\n" + str(target_location) + "\n" + str(this_turn_delta)
			ball_rotation += this_turn_delta
			ball_rotation = fmod(ball_rotation + 360.0, 360.0)
		var ball_sizes = ContentLoader.animations.get_ball_sizes()
		var frame = ContentLoader.animations.get_frame(start_frame + current_frame) as Dictionary
		var new_ball_positions: Array
		var this_chest_pos = frame.ball_array[6].position
		var chestrot = this_chest_pos.rotated(Vector3.UP, deg_to_rad(ball_rotation))
		for i in ball_sizes.size():
			var ball = frame.ball_array[i] as Dictionary
			var ball_position = ball.position
			var rotated = ball_position.rotated(Vector3.UP, deg_to_rad(ball_rotation))
			rotated = chestrot + (rotated - chestrot).rotated(Vector3.UP, deg_to_rad(this_turn_delta))
			rotated = rotated.rotated(Vector3.LEFT, deg_to_rad(15))
			new_ball_positions.push_back({idx = i, pos = rotated})
			if i == 6:
				last_chest_pos = rotated
		new_ball_positions.sort_custom(custom_sort)

		for ball in new_ball_positions:
			var ball_frame_data = frame.ball_array[ball.idx] as Dictionary
			var p = ball.pos
			var pos = Vector2(p.x, p.y)
			var size = ball_sizes[ball.idx] / 2.0
			pos *= draw_scale;
			size *= draw_scale;
			draw_circle(pos, size, Color.BLACK)
			if ball.idx == 2:
				draw_circle(pos, size - 1, Color.RED)
				belly_position = pos + global_position
				$Icon.global_position = belly_position
			else:
				if ball.idx == 0:
					draw_circle(pos, size - 1, Color.MEDIUM_PURPLE)
				else:
					draw_circle(pos, size - 1, Color.ANTIQUE_WHITE)

func _on_timer_timeout():
	current_frame = current_frame + 1
	if current_frame == frames_length:
		emit_signal("animation_done")
	else:
		current_frame = current_frame % frames_length
		queue_redraw()

func play_anim(start_frame, length):
	self.start_frame = start_frame
	self.frames_length = length
	self.current_frame = 0
	if reset:
		var this_turn_delta = 0.0
		if turn_delta > 0 and target_location != null:
			this_turn_delta = get_next_turn_delta()
		var frame = ContentLoader.animations.get_frame(start_frame + current_frame) as Dictionary
		var chest_pos_new_frame = frame.ball_array[6].position
		var chestrot = chest_pos_new_frame.rotated(Vector3.UP, deg_to_rad(ball_rotation))
		chestrot = chestrot.rotated(Vector3.LEFT, deg_to_rad(15))
		var rot1 = chest_pos_new_frame.rotated(Vector3.UP, deg_to_rad(ball_rotation))
		rot1 = rot1.rotated(Vector3.LEFT, deg_to_rad(15))
		rot1 = rot1.rotated(Vector3.UP, deg_to_rad(this_turn_delta))
		var rot2 = last_chest_pos
		var diff = Vector2(rot1.x, rot1.y) - Vector2(rot2.x, rot2.y)
		position += diff * draw_scale * -1.0
		reset = false
		if loop and frames_length > 1:
			current_frame = 1
			pass
	queue_redraw()
	
func update_pos():
	reset = true

func get_next_turn_delta():
	var forward = Vector2.LEFT.rotated(deg_to_rad(ball_rotation))
	var vec_to_target = target_location - belly_position
	vec_to_target.y *= -1.0
	$TargetLine.points = [Vector2.ZERO, vec_to_target.normalized() * 50.0]
	var angle = forward.angle_to(vec_to_target)
	angle = rad_to_deg(angle)
	var x = min(turn_delta, abs(angle)) * sign(angle)
	if abs(x) < 1.0:
		return 0.0
	return x
