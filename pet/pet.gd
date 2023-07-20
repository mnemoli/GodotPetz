extends Node2D

var texture = preload("res://ball_shader.tres")
var eye_texture = preload("res://eye_shader.tres")
var line_texture = preload("res://line_shader.tres")
var hair6 = preload("res://images/textures/hair6.bmp")
@export var tex: Texture2D
@export var draw_scale = 0.5
@export var ball_scale = 0.5
var current_frame = -999;
var start_frame = 0
var last_frame = 0
var frames_length = 20
var anim_direction = 1
var ball_rotation = 0
var target_sprite = null
var last_chest_pos = Vector3.ZERO
var turn_delta = 0
var reset = true
var belly_position = Vector2.ZERO
var loop = false
var delta = 0
@onready var rottext = get_tree().root.get_node("Root/CanvasLayer/Rot") as Label
@onready var rottext2 = get_tree().root.get_node("Root/CanvasLayer/Rot2") as Label
var last_head_rot = Vector2.ZERO
var lnz: LnzParser

signal animation_done

var head_balls = [4,5,7,8,9,10,11,14,15,24,27,28,29,30,31,37,40,55,56,57,58,59,60,61,62]
var head_ball = 24
var iris_balls = [27, 28]
var eye_balls = [14, 15]
var omitted_balls = [65, 66, 55, 56]

var ball_polys: Dictionary
var lines: Array

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

func calculate_rectangle(start: Vector2, end: Vector2, start_width: int, end_width: int):
	var pts = PackedVector2Array()
	var length = (end - start).length() / 2.0
	pts.append(Vector2(length, start_width))
	pts.append(Vector2(-length, end_width))
	pts.append(Vector2(-length, -end_width))
	pts.append(Vector2(length, -start_width))
	
	var uvs = PackedVector2Array()
	uvs.append(Vector2(length, 0))
	uvs.append(Vector2(0, 0))
	uvs.append(Vector2(0, end_width * 2.0))
	uvs.append(Vector2(length, start_width * 2.0))
	
	var raws = Vector2(start_width, end_width)
	
	return [pts, uvs, raws]

func calculate_addball_position(ball_no, ball_positions_3d):
	var baseball = lnz.addballs[ball_no].base
	var base_pos = ball_positions_3d[baseball]
	var vec = lnz.addballs[ball_no].position * draw_scale
	vec = vec.rotated(Vector3.UP, ball_rotation)
	vec = vec.rotated(Vector3.LEFT, deg_to_rad(15))
	return vec + base_pos.pos

func _ready():
	var frame_balls = ContentLoader.animations.get_frame(0).ball_array as Array
	var chest_ball = frame_balls[6]
	last_chest_pos = chest_ball.position
	
	lnz = LnzParser.new("res://lnz/bw.lnz.txt")
	draw_scale = lnz.scales[0]
	ball_scale = lnz.scales[1]
	omitted_balls = lnz.omissions.keys()
	
	for i in frame_balls.size() + lnz.addballs.size():
		if i not in iris_balls and i not in omitted_balls:
			var circle = Polygon2D.new()
			add_child(circle)
			if i < frame_balls.size():
				circle.position = Vector2(frame_balls[i].position.x, frame_balls[i].position.y) * draw_scale
			else:
				circle.position = Vector2.ZERO
			var ball_sizes = ContentLoader.animations.get_ball_sizes() + lnz.addballs.values().map(func(a): return a.size)
			var radius = (ball_sizes[i] / 2.0) * ball_scale
			circle.polygon = _calculate_polygon(radius)
			if i in eye_balls:
				circle.material = eye_texture.duplicate()
				var irisno = eye_balls.find(i)
				var iris_ball_no = iris_balls[irisno]
				var iris = frame_balls[iris_ball_no]
				circle.material.set_shader_parameter("iris_center", global_position + (Vector2(iris.position.x, iris.position.y)) * draw_scale)
				circle.material.set_shader_parameter("iris_radius", float((ball_sizes[iris_ball_no] - 5) * ball_scale))
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
			if i < frame_balls.size() - 1:
				circle.material.set_shader_parameter("outline_width", lnz.balls[i].outline as float)
			elif i > frame_balls.size() - 1:
				circle.material.set_shader_parameter("outline_width", lnz.addballs[i].outline as float)
	
	# don't ask, moronic godot behaviour
	var test_texture = GradientTexture2D.new()
	test_texture.height = 1
	test_texture.width = 1
			
	for l in lnz.lines:
		if l.start in omitted_balls or l.end in omitted_balls:
			continue
		var line = Polygon2D.new()
		add_child(line)
		line.name = "Line"
		lines.push_back(line)
		line.material = line_texture.duplicate()
		line.material.set_shader_parameter("tex", tex)
		line.texture = test_texture
		if l.r_color_index == -1:
			line.material.set_shader_parameter("outline1_enabled", 0.0)
		if l.l_color_index == -1:
			line.material.set_shader_parameter("outline2_enabled", 0.0)

func sort_by_z(a: Dictionary, b: Dictionary):
	return a.pos.z < b.pos.z
	
func apply_head_tracking(ball_pos: Vector3, head_pos: Vector3):
	head_pos *= draw_scale
	var headfwd = Vector3.FORWARD.rotated(Vector3.UP, deg_to_rad(ball_rotation))
	var head_pos2 = Vector2(head_pos.x, head_pos.y)
	var target_location = target_sprite.global_position
	var targetvec = Vector3(target_location.x, target_location.y, target_location.y) - Vector3(global_position.x, global_position.y, global_position.y)
	var headfwd2d = Vector2(headfwd.x, headfwd.y)
	var target2d = Vector2(targetvec.x, targetvec.y)
	$ForwardLine.points = [Vector2.ZERO, headfwd2d * 50.0]
	$TargetLine.points = [Vector2.ZERO, target2d]
	head_pos /= draw_scale
	var x = (ball_pos - head_pos)
	var test = Vector2(headfwd.x, headfwd.z).angle_to(Vector2(targetvec.x, targetvec.z))
	var angle = -test
	angle = clampf(angle, deg_to_rad(-60.0), deg_to_rad(60))
	angle = lerp_angle(last_head_rot.x, angle, delta)
	x = x.rotated(Vector3.UP, angle)
	var angle2 = Vector2(headfwd.x, headfwd.y).angle_to(Vector2(targetvec.x, targetvec.y))
	angle2 = angle2
	angle2 = clampf(angle2, deg_to_rad(-20), deg_to_rad(20))
	angle2 = lerp_angle(last_head_rot.y, angle2, delta)
	var rotaxis = Vector3.LEFT.rotated(Vector3.UP, deg_to_rad(ball_rotation))
	if ball_rotation >= 180 or ball_rotation < 0:
		rotaxis = -rotaxis
	x = x.rotated(rotaxis, angle2)
	last_head_rot = Vector2(angle, angle2)
	rottext.text = "angle1 " + str(rad_to_deg(angle)) + "\nangle2 " + str(rad_to_deg(angle2)) + "\ndelta " + str(delta) + "\nballrot " + str(ball_rotation)

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
	var next_chest_pos
	if target_sprite or turn_delta:
		ball_rotation = fmod(ball_rotation + get_next_rotation(), 360.0)
	var fwd = Vector3.FORWARD.rotated(Vector3.UP, deg_to_rad(ball_rotation))
	if current_frame != -999:
		var ball_sizes = ContentLoader.animations.get_ball_sizes()
		var last_frame_data = ContentLoader.animations.get_frame(last_frame) as Dictionary
		var frame = ContentLoader.animations.get_frame(start_frame + current_frame) as Dictionary
		var new_ball_positions = Dictionary()
		var center = frame.ball_array[2].position
		var last_center = last_frame_data.ball_array[2].position
		var vec_to_new_center = center - last_center
		vec_to_new_center = vec_to_new_center.rotated(Vector3.UP, deg_to_rad(ball_rotation))
		vec_to_new_center = vec_to_new_center.rotated(Vector3.LEFT, deg_to_rad(15))
		self.position += Vector2(vec_to_new_center.x, vec_to_new_center.y) * draw_scale
		for i in ball_sizes.size():
			var ball = frame.ball_array[i] as Dictionary
			var ball_position = ball.position
			ball_position -= center
			var rotated = ball_position.rotated(Vector3.UP, deg_to_rad(ball_rotation))
			rotated = rotated.rotated(Vector3.LEFT, deg_to_rad(15))
			new_ball_positions[i] = {idx = i, pos = rotated}
			if i == 6:
				next_chest_pos = rotated
		for i in lnz.addballs:
			var ball_position = calculate_addball_position(i, new_ball_positions)
			new_ball_positions[i] = {idx = i, pos = ball_position}
				
		for m in lnz.moves:
			var base = m.base 
			var ball_pos = new_ball_positions[base].pos
			var vec: Vector3 = m.position
			vec *= draw_scale
			vec = vec.rotated(Vector3.UP, deg_to_rad(ball_rotation))
			vec = vec.rotated(Vector3.LEFT, deg_to_rad(15))
			new_ball_positions[base].pos = ball_pos + vec
			
		for m in lnz.project_ball:
			var base = m.base
			var projected = m.ball
			var amt = m.amount
			var base_pos = new_ball_positions[base].pos
			var projected_pos = new_ball_positions[projected].pos
			var vec = projected_pos - base_pos
			vec *= amt / 100.0
			new_ball_positions[projected].pos = base_pos + vec
			
		if target_sprite != null:
			for i in head_balls:
				new_ball_positions[i].pos = apply_head_tracking(new_ball_positions[i].pos, new_ball_positions[head_ball].pos)
			for i in lnz.addballs:
				if lnz.addballs[i].base in head_balls:
					new_ball_positions[i].pos = apply_head_tracking(new_ball_positions[i].pos, new_ball_positions[head_ball].pos)
			var iris_ctr = 0
			for i in iris_balls:
				new_ball_positions[i].pos = apply_iris_tracking(new_ball_positions[i].pos, new_ball_positions[eye_balls[iris_ctr]].pos, (ball_sizes[eye_balls[iris_ctr]] / 2.0) * draw_scale)
				new_ball_positions[i].pos.z += (ball_sizes[eye_balls[iris_ctr]] / 2.0) * draw_scale
				iris_ctr += 1
			
		
		new_ball_positions = new_ball_positions.values()
		new_ball_positions.sort_custom(sort_by_z)

		var ctr = 0
		for ball in new_ball_positions:
			if ball.idx not in iris_balls and ball.idx not in omitted_balls:
				var p = ball.pos
				var pos = Vector2(p.x, p.y)
				var animballsize = frame.get("sizediffs", Dictionary()).get(ball.idx, 0)
				if ball.idx < ball_sizes.size():
					var size = (ball_sizes[ball.idx] + animballsize + lnz.balls[ball.idx].size) / 2.0
					size *= ball_scale;
					ball_polys[ball.idx].material.set_shader_parameter("radius", float(size))
					#ball_polys[ball.idx].visible = false
				pos *= draw_scale;
				ball_polys[ball.idx].position = pos
				ball_polys[ball.idx].material.set_shader_parameter("center", pos + global_position)
				move_child(ball_polys[ball.idx], ctr)
				if ball.idx in eye_balls:
					var iriscnt = eye_balls.find(ball.idx)
					var iris_no = iris_balls[iriscnt]
					var iris = new_ball_positions[iris_no]
					pos = Vector2(iris.pos.x, iris.pos.y) * draw_scale
					ball_polys[ball.idx].material.set_shader_parameter("iris_center", pos + global_position)
				
				if ball.idx == 2:
					belly_position = pos + global_position
			
				ctr += 1
			
		var linectr = 0		
		for line in lnz.lines:
			#lines[linectr].visible = false
			var start = ball_polys[line.start]
			var end = ball_polys[line.end]
			var raw_radius_start = ball_polys[line.start].material.get_shader_parameter("radius")
			var raw_radius_end = ball_polys[line.end].material.get_shader_parameter("radius")
			var start_radius = raw_radius_start * (line.s_thick / 100.0)
			var end_radius = raw_radius_end * (line.e_thick / 100.0)
			var rect = calculate_rectangle(start.position, end.position, start_radius, end_radius)
			lines[linectr].polygon = rect[0]
			lines[linectr].uv = rect[1]
			var z_sort = min(start.get_index(), end.get_index()) - 1
			move_child(lines[linectr], z_sort)
			lines[linectr].position = start.position + (end.position - start.position) / 2.0
			lines[linectr].material.set_shader_parameter("max_uvs", rect[2])
			lines[linectr].material.set_shader_parameter("center", lines[linectr].position + global_position)
			var angle = end.position.angle_to_point(start.position)
			(lines[linectr] as Polygon2D).rotation = angle
			#lines[linectr].visible = false
			linectr += 1
					
		last_chest_pos = next_chest_pos
		last_frame = start_frame + current_frame

func _on_timer_timeout():
	current_frame = current_frame + (1 * self.anim_direction)
	if abs(current_frame) == frames_length:
		emit_signal("animation_done")
	else:
		current_frame = current_frame % frames_length
		queue_redraw()

func play_anim(start_frame, length, direction):
	self.start_frame = start_frame
	self.frames_length = length
	self.current_frame = 0
	self.anim_direction = direction
	if reset:
		var frame = ContentLoader.animations.get_frame(start_frame) as Dictionary
		var center = frame.ball_array[2].position
		var chest_pos_new_frame = frame.ball_array[6].position
		chest_pos_new_frame -= center
		var rot1 = chest_pos_new_frame.rotated(Vector3.UP, deg_to_rad(ball_rotation))
		rot1 = rot1.rotated(Vector3.LEFT, deg_to_rad(15))
		var diff = Vector2(last_chest_pos.x, last_chest_pos.y) - Vector2(rot1.x, rot1.y)
		position += diff * draw_scale
		last_chest_pos = Vector3.ZERO
		reset = false
		last_frame = start_frame + current_frame
		if loop and frames_length > 1:
			current_frame = 1 * direction
			loop = false
	queue_redraw()
	
func update_pos():
	reset = true

func get_next_rotation():
	if target_sprite:
		var vec = (target_sprite.global_position - belly_position) as Vector2
		var fwd = Vector2.UP.rotated(deg_to_rad(ball_rotation))
		fwd.x *= -1.0
		var angle = fwd.angle_to(vec)
		angle = rad_to_deg(angle)
		if angle > 180:
			angle -= 360
		rottext2.text = "vec: " + str(vec) + "\nangle: " + str(angle) + "\noutput: " + str(min(turn_delta, abs(angle)) * -sign(angle))
		return min(turn_delta, abs(angle)) * -sign(angle)
	elif turn_delta:
		return turn_delta
