extends Node2D

@export var draw_scale = 0.5;
var current_frame = -1;
var start_frame = 0
var frames_length = 20
var ball_rotation = 0
var target_sprite = null
var last_chest_pos = Vector3.ZERO
var turn_delta = 0
var reset = false
var belly_position = Vector3.ZERO
var loop = false
var delta = 0
@onready var rottext = get_tree().root.get_node("Root/CanvasLayer/Rot") as Label
var last_head_rot = Vector2.ZERO

signal animation_done

var head_balls = [4,5,7,8,9,10,11,14,15,24,27,28,29,30,31,37,40,55,56,57,58,59,60,61,62]
var head_ball = 24
var iris_balls = [27, 28]
var eye_balls = [14, 15]
var omitted_balls = [65, 66, 55, 56]

func _ready():
	var frame_balls = ContentLoader.animations.get_frame(0).ball_array
	var chest_ball = frame_balls[6]
	last_chest_pos = chest_ball.position

func custom_sort(a: Dictionary, b: Dictionary):
	return a.pos.z < b.pos.z
	
func apply_head_tracking(ball_pos: Vector3, head_pos: Vector3):
	head_pos *= draw_scale
	var headfwd = Vector3.LEFT.rotated(Vector3.UP, deg_to_rad(ball_rotation))
	var head_pos2 = Vector2(head_pos.x, head_pos.y)
	$ForwardLine.points = [head_pos2, head_pos2 + Vector2(headfwd.x, headfwd.y) * 50.0]
	var target_location = target_sprite.global_position
	var targetvec = (Vector3(global_position.x, global_position.y, global_position.y) + head_pos).direction_to(Vector3(target_location.x, target_location.y, target_location.y))
	$TargetLine.points = [head_pos2, head_pos2 + Vector2(targetvec.x, targetvec.y) * 50.0]
	head_pos /= draw_scale
	var x = (ball_pos - head_pos).rotated(Vector3.UP, deg_to_rad(-ball_rotation))
	var angle1 = atan2(targetvec.y, targetvec.z)
	var angle2 = asin(targetvec.x / targetvec.length())
	angle1 = clampf(angle1, deg_to_rad(-45.0), deg_to_rad(45.0))
	angle2 = clampf(angle2, deg_to_rad(-70.0), deg_to_rad(70.0))
	angle1 = lerp_angle(last_head_rot.x, angle1, delta)
	angle2 = lerp_angle(last_head_rot.y, angle2, delta)
	x = x.rotated(Vector3.FORWARD, angle1)
	x = x.rotated(Vector3.UP, angle2)			
	rottext.text = str(rad_to_deg(angle1)) + "\n" + str(rad_to_deg(-angle2)) + "\n" + str(delta * 2.0)
	last_head_rot = Vector2(angle1, angle2)
	return x.rotated(Vector3.UP, deg_to_rad(ball_rotation)) + head_pos

func apply_iris_tracking(iris_pos: Vector3, eye_pos: Vector3, eye_size: int):
	eye_pos *= draw_scale
	var target_location = target_sprite.global_position
	var targetvec = (target_location - global_position + Vector2(eye_pos.x, eye_pos.y)).limit_length(eye_size + 5)
	iris_pos.x += targetvec.x
	iris_pos.y += targetvec.y
	return iris_pos
	
func _process(delta):
	self.delta = delta

func _draw():
	if current_frame > -1:
		var this_turn_delta = turn_delta
		if target_sprite != null and turn_delta > 0:
			this_turn_delta = get_next_turn_delta()
			ball_rotation += this_turn_delta
			ball_rotation = fmod(ball_rotation + 360.0, 360.0)
		var ball_sizes = ContentLoader.animations.get_ball_sizes()
		var frame = ContentLoader.animations.get_frame(start_frame + current_frame) as Dictionary
		var new_ball_positions = Dictionary()
		var this_chest_pos = frame.ball_array[6].position
		var chestrot = this_chest_pos.rotated(Vector3.UP, deg_to_rad(ball_rotation))
		for i in ball_sizes.size():
			var ball = frame.ball_array[i] as Dictionary
			var ball_position = ball.position
			var rotated = ball_position.rotated(Vector3.UP, deg_to_rad(ball_rotation))
			rotated = chestrot + (rotated - chestrot).rotated(Vector3.UP, deg_to_rad(this_turn_delta))
			rotated = rotated.rotated(Vector3.LEFT, deg_to_rad(15))
			new_ball_positions[i] = {idx = i, pos = rotated}
			if i == 6:
				last_chest_pos = rotated
		if target_sprite != null:
			for i in head_balls:
				new_ball_positions[i].pos = apply_head_tracking(new_ball_positions[i].pos, new_ball_positions[head_ball].pos)
			var iris_ctr = 0
			for i in iris_balls:
				new_ball_positions[i].pos = apply_iris_tracking(new_ball_positions[i].pos, new_ball_positions[eye_balls[iris_ctr]].pos, (ball_sizes[i] / 2.0) * draw_scale)
				iris_ctr += 1
		new_ball_positions = new_ball_positions.values()
		new_ball_positions.sort_custom(custom_sort)

		for ball in new_ball_positions:
			var ball_frame_data = frame.ball_array[ball.idx] as Dictionary
			var p = ball.pos
			var pos = Vector2(p.x, p.y)
			var size = ball_sizes[ball.idx] / 2.0
			pos *= draw_scale;
			size *= draw_scale;
			if ball.idx not in omitted_balls:
				draw_circle(pos, size, Color.BLACK)
			if ball.idx == 2:
				draw_circle(pos, size - 1, Color.RED)
				belly_position = pos + global_position
				$Icon.global_position = belly_position
			elif ball.idx not in omitted_balls:
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
		if turn_delta > 0 and target_sprite != null:
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
		if loop:
			current_frame = 1
			loop = false
	queue_redraw()
	
func update_pos():
	reset = true

func get_next_turn_delta():
	var forward = Vector2.LEFT.rotated(deg_to_rad(ball_rotation))
	var vec_to_target = target_sprite.global_position - belly_position
	vec_to_target.y *= -1.0
	$TargetLine.points = [Vector2.ZERO, vec_to_target.normalized() * 50.0]
	var angle = forward.angle_to(vec_to_target)
	angle = rad_to_deg(angle)
	var x = min(turn_delta, abs(angle)) * sign(angle)
	if abs(x) < 1.0:
		return 0.0
	return x
