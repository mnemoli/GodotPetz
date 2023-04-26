extends Node2D

var texture = preload("res://ball_shader.tres")
var eye_texture = preload("res://eye_shader.tres")
@export var tex: Texture2D
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

var ball_polys: Dictionary

func polar_to_cartesian(rho, phi):
	var x = rho * cos(phi)
	var y = rho * sin(phi)
	return Vector2(x,y)

func _calculate_polygon(radius) -> PackedVector2Array:
	radius /= draw_scale
	var th = 2*PI/4
	var pts = PackedVector2Array()
	for i in range(4):
		pts.append(polar_to_cartesian(radius, deg_to_rad(45) + i*th))
	return pts

func _ready():
	var frame_balls = ContentLoader.animations.get_frame(0).ball_array as Array
	var chest_ball = frame_balls[6]
	last_chest_pos = chest_ball.position
	
	for i in frame_balls.size():
		if i not in iris_balls and i not in omitted_balls:
			var circle = Polygon2D.new()
			add_child(circle)
			circle.position = Vector2(frame_balls[i].position.x, frame_balls[i].position.y) * draw_scale
			var ball_sizes = ContentLoader.animations.get_ball_sizes()
			var radius = (ball_sizes[i] / 2.0) * draw_scale
			circle.polygon = _calculate_polygon(radius)
			if i in eye_balls:
				circle.material = eye_texture.duplicate()
				var irisno = eye_balls.find(i)
				var iris_ball_no = iris_balls[irisno]
				var iris = frame_balls[iris_ball_no]
				circle.material.set_shader_parameter("iris_center", global_position + (Vector2(iris.position.x, iris.position.y)) * draw_scale)
				circle.material.set_shader_parameter("iris_radius", float((ball_sizes[iris_ball_no] - 5) * draw_scale))
				circle.material.set_shader_parameter("iris_outline_width", 3.0)
				if irisno == 1:
					circle.material.set_shader_parameter("eyelid_tilt_direction", -1.0)
			else:
				circle.material = texture.duplicate()
			ball_polys[i] = circle
			circle.material.set_shader_parameter("center", circle.global_position)
			circle.material.set_shader_parameter("radius", float(radius))
			circle.material.set_shader_parameter("outline_width", 1.0)
			circle.material.set_shader_parameter("tex", tex)

func custom_sort(a: Dictionary, b: Dictionary):
	return a.pos.z < b.pos.z
	
func apply_head_tracking(ball_pos: Vector3, head_pos: Vector3):
	head_pos *= draw_scale
	var headfwd = Vector3.LEFT.rotated(Vector3.UP, deg_to_rad(ball_rotation))
	var head_pos2 = Vector2(head_pos.x, head_pos.y)
	$ForwardLine.points = [head_pos2, head_pos2 + Vector2(headfwd.x, headfwd.y) * 50.0]
	var target_location = target_sprite.global_position
	var targetvec = (Vector3(global_position.x, global_position.y, global_position.y) + head_pos).direction_to(Vector3(target_location.x, target_location.y, 999))
	$TargetLine.points = [head_pos2, head_pos2 + Vector2(targetvec.x, targetvec.y) * 50.0]
	head_pos /= draw_scale
	# cancel existing rotation
	var x = (ball_pos - head_pos).rotated(Vector3.UP, deg_to_rad(-ball_rotation))
	var angle1 = atan2(targetvec.y, targetvec.z)
	var angle2 = asin(targetvec.x)
	angle1 = clampf(angle1, deg_to_rad(-55.0), deg_to_rad(40.0))
	angle1 = lerp_angle(last_head_rot.x, angle1, delta / 2.0)
	x = x.rotated(Vector3.FORWARD, angle1)
	var diff = wrapf(rad_to_deg(angle2) + 90 - ball_rotation, -180, 180)
	diff = clampf(diff, -70, 70)
	var last_diff = last_head_rot.y
	angle2 = lerpf(last_diff, diff, delta / 2.0)
	angle2 = clampf(angle2, -70, 70)
	angle2 = deg_to_rad(ball_rotation + angle2)
	x = x.rotated(Vector3.UP, angle2)
	last_head_rot = Vector2(angle1, diff)
	rottext.text = "angle1 " + str(rad_to_deg(angle1)) + "\nangle2 " + str(rad_to_deg(angle2)) + "\ndelta " + str(delta) + "\nballrot - angle2 " + str(ball_rotation - rad_to_deg(angle2))

	return x + head_pos

func apply_iris_tracking(iris_pos: Vector3, eye_pos: Vector3, eye_size: int):
	eye_pos *= draw_scale
	var target_location = target_sprite.global_position
	var targetvec = (target_location - (global_position + Vector2(eye_pos.x, eye_pos.y)))
	targetvec /= draw_scale
	targetvec = targetvec.limit_length(eye_size)
	iris_pos.x += targetvec.x
	if targetvec.y < (-eye_size / 3.0) * 2.0:
		targetvec.y = (-eye_size / 3.0) * 2.0
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
				new_ball_positions[i].pos = apply_iris_tracking(new_ball_positions[i].pos, new_ball_positions[eye_balls[iris_ctr]].pos, (ball_sizes[eye_balls[iris_ctr]] / 2.0) * draw_scale)
				new_ball_positions[i].pos.z += (ball_sizes[eye_balls[iris_ctr]] / 2.0) * draw_scale
				iris_ctr += 1
		var ball_positions_by_id = new_ball_positions
		new_ball_positions = new_ball_positions.values()
		new_ball_positions.sort_custom(custom_sort)

		for ball in new_ball_positions:
			if ball.idx not in iris_balls and ball.idx not in omitted_balls:
				var ball_frame_data = frame.ball_array[ball.idx] as Dictionary
				var p = ball.pos
				var pos = Vector2(p.x, p.y)
				var size = ball_sizes[ball.idx] / 2.0
				pos *= draw_scale;
				size *= draw_scale;
				ball_polys[ball.idx].position = pos
				ball_polys[ball.idx].material.set_shader_parameter("center", pos + global_position)
				(ball_polys[ball.idx] as Polygon2D).z_index = p.z * draw_scale
				if ball.idx in eye_balls:
					var iriscnt = eye_balls.find(ball.idx)
					var iris_no = iris_balls[iriscnt]
					var iris = ball_positions_by_id[iris_no]
					pos = Vector2(iris.pos.x, iris.pos.y) * draw_scale
					ball_polys[ball.idx].material.set_shader_parameter("iris_center", pos + global_position)
				
				if ball.idx == 2:
					belly_position = pos + global_position

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
		if loop and frames_length > 1:
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
