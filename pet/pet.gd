extends Node2D

enum HEAD_TARGET_TYPE {
	TARGET,
	RANDOM,
	USER,
	FORWARD
}

enum EYE_TARGET_TYPE {
	TARGET,
	RANDOM,
	USER,
	FORWARD
}

var texture = preload("res://shaders/ball_shader.tres")
var eye_texture = preload("res://shaders/eye_shader.tres")
var line_texture = preload("res://shaders/line_shader.tres")
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
#@onready var rottext = get_tree().root.get_node("Root/CanvasLayer/Rot") as Label
#@onready var rottext2 = get_tree().root.get_node("Root/CanvasLayer/Rot2") as Label
var last_head_rot = Vector2.ZERO
var lnz: LnzParser
var process_speed_tick = 0
@export var anim_speed_divider = 2
@export var apply_anim_movement = true
var head_target_type = HEAD_TARGET_TYPE.FORWARD
var eye_target_type = EYE_TARGET_TYPE.FORWARD
var target_look_location: Vector2

var layers = [null, null, null, null, null, null]

signal animation_done
signal layered_animation_done(layer)

var head_balls = [4,5,7,8,9,10,11,14,15,24,27,28,29,30,31,37,40,55,56,57,58,59,60,61,62]
var head_ball = 24
var iris_balls = [27, 28]
var eye_balls = [14, 15]
var omitted_balls = [65, 66, 55, 56]

var ball_polys: Dictionary
var lines: Array
var whiskers: Array

func polar_to_cartesian(rho, phi):
	var x = rho * cos(phi)
	var y = rho * sin(phi)
	return Vector2(x,y)

func _calculate_polygon(radius) -> PackedVector2Array:
	radius /= ball_scale
	radius = max(radius, 3.0)
	radius *= 2.0
	var th = 2*PI/4
	var pts = PackedVector2Array()
	for i in range(4):
		pts.append(polar_to_cartesian(radius, deg_to_rad(45) + i*th))
	return pts

func calculate_rectangle(start: Vector2, end: Vector2, start_width, end_width, convert_to_int = true):
	var pts = PackedVector2Array()
	var length = (end - start).length() / 2.0
	if convert_to_int:
		start_width = round(start_width)
		end_width = round(end_width)
	pts.append(Vector2(length, start_width * 2.0))
	pts.append(Vector2(-length, end_width * 2.0))
	pts.append(Vector2(-length, -end_width * 2.0))
	pts.append(Vector2(length, -start_width * 2.0))
	
	var uvs = PackedVector2Array()
	uvs.append(Vector2(length, 0))
	uvs.append(Vector2(0, 0))
	uvs.append(Vector2(0, end_width * 4.0))
	uvs.append(Vector2(length, start_width * 4.0))
	
	var raws = Vector2(start_width * 4.0, end_width * 4.0)
	
	return [pts, uvs, raws]

func calculate_addball_position(ball_no, base_pos, base_rot):
	var vec = lnz.addballs[ball_no].position
	base_rot = (base_rot / 255.0) * 360.0
	base_rot = Vector3(deg_to_rad(base_rot.x), deg_to_rad(base_rot.y), deg_to_rad(base_rot.z))
	var q = Quaternion.from_euler(base_rot)
	vec = vec.rotated(Vector3.UP, deg_to_rad(ball_rotation))
	vec *= q
	vec = vec.rotated(Vector3.LEFT, deg_to_rad(15))
	return base_pos.pos + vec

func setup_lnz():
	var frame_balls = ContentLoader.animations.get_frame(0).ball_array as Array
	draw_scale = lnz.scales[0]
	ball_scale = lnz.scales[1]
	omitted_balls = lnz.omissions.keys()
	
	for i in ball_polys:
		remove_child(ball_polys[i])
	for i in lines:
		remove_child(i)
	for i in whiskers:
		remove_child(i)
		
	ball_polys = {}
	lines = []
	whiskers = []
	
	# don't ask, moronic godot behaviour
	var test_texture = GradientTexture2D.new()
	test_texture.height = 1
	test_texture.width = 1
	
	for i in frame_balls.size() + lnz.addballs.size():
		if i not in iris_balls and i not in omitted_balls:
			var circle = Polygon2D.new()
			add_child(circle)
			if i < 91:
				circle.name = lnz.cat_ball_names[i]
			if i < frame_balls.size():
				circle.position = Vector2(frame_balls[i].position.x, frame_balls[i].position.y) * draw_scale
			else:
				circle.position = Vector2.ZERO
			var ball_sizes = ContentLoader.animations.get_ball_sizes() + lnz.addballs.values().map(func(a): return a.size)
			var radius = (ball_sizes[i] / 2.0) * ball_scale
			radius = max(radius, 3.0)
			radius -= 1
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
				circle.material.set_shader_parameter("color_index", lnz.balls[i].color_index as float)
				circle.material.set_shader_parameter("outline_color", lnz.colors[lnz.balls[i].outline_color_index])
				circle.material.set_shader_parameter("fuzz", lnz.balls[i].fuzz as float)
			else:
				circle.material.set_shader_parameter("outline_width", lnz.addballs[i].outline as float)
				circle.material.set_shader_parameter("color_index", lnz.addballs[i].color_index as float)
				circle.material.set_shader_parameter("outline_color", lnz.colors[lnz.addballs[i].outline_color_index])
				circle.material.set_shader_parameter("fuzz", lnz.addballs[i].fuzz as float)
			
	for l in lnz.lines:
		if l.start in omitted_balls or l.end in omitted_balls:
			continue
		var line = Polygon2D.new()
		add_child(line)
		if l.start < 67 and l.end < 67:
			var startname = lnz.cat_ball_names[l.start]
			var endname = lnz.cat_ball_names[l.end]
			line.name = "Line " + startname + " " + endname
		else:
			line.name = "Addball line " + str(l.start) + " " + str(l.end)
		lines.push_back(line)
		line.material = line_texture.duplicate()
		line.material.set_shader_parameter("tex", tex)
		line.texture = test_texture
		if l.r_color_index == -1:
			line.material.set_shader_parameter("outline1_enabled", 0.0)
		else:
			line.material.set_shader_parameter("outline1_color", lnz.colors[l.r_color_index])
		if l.l_color_index == -1:
			line.material.set_shader_parameter("outline2_enabled", 0.0)
		else:
			line.material.set_shader_parameter("outline2_color", lnz.colors[l.l_color_index])
		if l.color_index == -1:
			var ball_color
			if l.start < 67:
				ball_color = lnz.balls[l.start].color_index
				
			else:
				ball_color = lnz.addballs[l.start].color_index
			line.material.set_shader_parameter("color_index", ball_color)
		else:
			line.material.set_shader_parameter("color_index", l.color_index)
			
	for w in lnz.whiskers:
		var line = Polygon2D.new()
		add_child(line)
		line.color = lnz.colors[lnz.balls[w.end].color_index]
		whiskers.push_back(line)
		ball_polys[w.end].visible = false

func _ready():
	var frame_balls = ContentLoader.animations.get_frame(0).ball_array as Array
	var chest_ball = frame_balls[6]
	last_chest_pos = chest_ball.position
	
	lnz = LnzParser.new("res://lnz/bw.lnz.txt")
	setup_lnz()

func sort_by_z(a: Dictionary, b: Dictionary):
	return a.pos.z < b.pos.z
	
func apply_head_tracking(ball_pos: Vector3, head_pos: Vector3):
	$Icon.visible = false
	match head_target_type:
		HEAD_TARGET_TYPE.TARGET:
			$Icon.visible = true
			$Icon.global_position = target_look_location
			#head_pos *= draw_scale
			var headfwd = Vector3.FORWARD.rotated(Vector3.UP, deg_to_rad(ball_rotation))
			var targetvec = Vector3(target_look_location.x, target_look_location.y, target_look_location.y) - Vector3(global_position.x, global_position.y, global_position.y)
			var headfwd2d = Vector2(headfwd.x, headfwd.y)
			var target2d = Vector2(targetvec.x, targetvec.y)
			$ForwardLine.points = [Vector2.ZERO, headfwd2d * 50.0]
			$TargetLine.points = [Vector2.ZERO, target2d]
			#head_pos /= draw_scale
			var x = (ball_pos - head_pos)
			var test = Vector2(headfwd.x, headfwd.z).angle_to(Vector2(targetvec.x, targetvec.z))
			var angle = -test
			angle = clampf(angle, deg_to_rad(-60.0), deg_to_rad(60))
			angle = lerp_angle(last_head_rot.x, angle, delta)
			x = x.rotated(Vector3.LEFT, deg_to_rad(-15))
			x = x.rotated(Vector3.UP, angle)
			var angle2 = Vector2(headfwd.x, headfwd.y).angle_to(Vector2(targetvec.x, targetvec.y))
			angle2 = angle2
			angle2 = clampf(angle2, deg_to_rad(-60), deg_to_rad(60))
			angle2 = lerp_angle(last_head_rot.y, angle2, delta)
			var rotaxis = Vector3.LEFT.rotated(Vector3.UP, deg_to_rad(ball_rotation))
			if ball_rotation >= 180 or ball_rotation < 0:
				rotaxis = -rotaxis
			x = x.rotated(rotaxis, angle2)
			last_head_rot = Vector2(angle, angle2)

			return x + head_pos
		HEAD_TARGET_TYPE.USER:
			var angle_to_fwd = -ball_rotation + 180.0
			angle_to_fwd = wrapf(angle_to_fwd, -180, 180)
			angle_to_fwd = clampf(angle_to_fwd, -100, 100)
			angle_to_fwd = deg_to_rad(angle_to_fwd)
			angle_to_fwd = lerp_angle(last_head_rot.x, angle_to_fwd, delta)
			var other_angle = lerp_angle(last_head_rot.y, 0, delta)
			var x = ball_pos - head_pos
			x = x.rotated(Vector3.LEFT, deg_to_rad(-15))
			x = x.rotated(Vector3.UP, angle_to_fwd)
			var rotaxis = Vector3.LEFT.rotated(Vector3.UP, deg_to_rad(ball_rotation))
			if ball_rotation >= 180 or ball_rotation < 0:
				rotaxis = -rotaxis
			x = x.rotated(rotaxis, other_angle)
			last_head_rot.x = angle_to_fwd
			last_head_rot.y = other_angle
			return head_pos + x
		HEAD_TARGET_TYPE.FORWARD:
			var angle = lerp_angle(last_head_rot.x, 0, delta)
			var other_angle = lerp_angle(last_head_rot.y, 0, delta)
			var x = ball_pos - head_pos
			x = x.rotated(Vector3.LEFT, deg_to_rad(-15))
			x = x.rotated(Vector3.UP, angle)
			var rotaxis = Vector3.LEFT.rotated(Vector3.UP, deg_to_rad(ball_rotation))
			if ball_rotation >= 180 or ball_rotation < 0:
				rotaxis = -rotaxis
			x = x.rotated(rotaxis, other_angle)
			last_head_rot.x = angle
			last_head_rot.y = other_angle
			return head_pos + x

func apply_iris_tracking(iris_pos: Vector3, eye_pos: Vector3, eye_size: int):
	match eye_target_type:
		EYE_TARGET_TYPE.TARGET:
			var headfwd = Vector3.FORWARD.rotated(Vector3.UP, deg_to_rad(ball_rotation))
			var targetvec = (target_look_location - (global_position + Vector2(eye_pos.x, eye_pos.y)))
			targetvec = targetvec.limit_length(eye_size)
			iris_pos.x += targetvec.x
			if targetvec.y < (-eye_size / 3.0) * 2.0:
				targetvec.y = (-eye_size / 3.0) * 2.0
			iris_pos.y += targetvec.y
			return iris_pos
		EYE_TARGET_TYPE.USER:
			return eye_pos
		EYE_TARGET_TYPE.FORWARD:
			return iris_pos
	
@warning_ignore("shadowed_variable")
func _process(delta):
	self.delta = delta
	if process_speed_tick == 0 and current_frame != -999:
		current_frame = current_frame + (1 * self.anim_direction)
		if abs(current_frame) == frames_length:
			emit_signal("animation_done")
		else:
			current_frame = current_frame % frames_length
		queue_redraw()
		
		var l = 0
		for layer in layers:
			if layer != null:
				layer.current += 1
				if layer.current == layer.size:
					emit_signal("layered_animation_done", l)
					layers[l] = null
			l += 1
	process_speed_tick = (process_speed_tick + 1) % anim_speed_divider

func _draw():
	var next_chest_pos
	if target_sprite or turn_delta:
		ball_rotation = fmod(ball_rotation + get_next_rotation(), 360.0)
	if current_frame != -999:
		var ball_sizes = ContentLoader.animations.get_ball_sizes()
		var last_frame_data = ContentLoader.animations.get_frame(last_frame) as Dictionary
		var frame = ContentLoader.animations.get_frame(start_frame + current_frame) as Dictionary
		var new_ball_positions = Dictionary()
		var center = frame.ball_array[2].position
		var last_center = last_frame_data.ball_array[2].position
		if apply_anim_movement:
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
			new_ball_positions[i] = {idx = i, pos = rotated, rot = ball.rotation}
			if i == 6:
				next_chest_pos = rotated
		
		var baseframe = frame
		for layer in layers:
			if layer != null:
				var layerframe = ContentLoader.animations.get_frame(layer.start_frame + layer.current) as Dictionary
				for i in ball_sizes.size():
					var ball = layerframe.ball_array[i] as Dictionary
					var base_ball = baseframe.ball_array[i]
					var ball_position = ball.position - base_ball.position
					var rotated = ball_position.rotated(Vector3.UP, deg_to_rad(ball_rotation))
					rotated = rotated.rotated(Vector3.LEFT, deg_to_rad(15))
					rotated += new_ball_positions[i].pos
					new_ball_positions[i] = {idx = i, pos = rotated, rot = new_ball_positions[i].rot + ball.rotation}
					if i == 6:
						next_chest_pos = rotated
		
		for i in lnz.addballs:
			if i not in omitted_balls:
				var base_pos = new_ball_positions[lnz.addballs[i].base]
				var base_rot = frame.ball_array[lnz.addballs[i].base].rotation
				var ball_position = calculate_addball_position(i, base_pos, base_rot)
				new_ball_positions[i] = {idx = i, pos = ball_position, rot = 0.0}
				
		for m in lnz.moves:
			var base = m.base 
			var relative_to = m.relative_to
			var ball_pos = new_ball_positions[base].pos
			var ball_rot = frame.ball_array[relative_to].rotation
			var vec: Vector3 = m.position
			vec *= draw_scale
			vec = vec.rotated(Vector3.UP, deg_to_rad(ball_rotation))
			ball_rot = (ball_rot / 255.0) * 360.0
			ball_rot = Vector3(deg_to_rad(ball_rot.x), deg_to_rad(ball_rot.y), deg_to_rad(ball_rot.z))
			var q = Quaternion.from_euler(ball_rot)
			vec = vec * q
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
			
		for i in head_balls:
			new_ball_positions[i].pos = apply_head_tracking(new_ball_positions[i].pos, new_ball_positions[head_ball].pos)
			var add_rot = Vector3(rad_to_deg(last_head_rot.x), rad_to_deg(last_head_rot.y), 0)
			new_ball_positions[i].rot = new_ball_positions[i].rot + add_rot 
		for i in lnz.addballs:
			if lnz.addballs[i].base in head_balls:
				new_ball_positions[i].pos = apply_head_tracking(new_ball_positions[i].pos, new_ball_positions[head_ball].pos)
		var iris_ctr = 0
		for i in iris_balls:
			new_ball_positions[i].pos = apply_iris_tracking(new_ball_positions[i].pos, new_ball_positions[eye_balls[iris_ctr]].pos, (ball_sizes[eye_balls[iris_ctr]] / 2.0) * draw_scale)
			new_ball_positions[i].pos.z += (ball_sizes[eye_balls[iris_ctr]] / 2.0) * draw_scale
			iris_ctr += 1
			
			
		var new_ball_positions_by_id = new_ball_positions
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
					size *= ball_scale
					ball_polys[ball.idx].material.set_shader_parameter("radius", float(size))
					#ball_polys[ball.idx].visible = false
				pos *= draw_scale;
				ball_polys[ball.idx].position = pos
				ball_polys[ball.idx].material.set_shader_parameter("center", pos + global_position)
				move_child(ball_polys[ball.idx], ctr)
				if ball.idx in eye_balls:
					var iriscnt = eye_balls.find(ball.idx)
					var iris_no = iris_balls[iriscnt]
					var iris = new_ball_positions_by_id[iris_no]
					pos = Vector2(iris.pos.x, iris.pos.y) * draw_scale
					ball_polys[ball.idx].material.set_shader_parameter("iris_center", pos + global_position)
					#ball_polys[ball.idx].material.set_shader_parameter("head_tilt_deg", ball.rot.z)
					
				
				if ball.idx == 2:
					belly_position = pos + global_position
			
				ctr += 1
				
		var linectr = 0		
		for line in lnz.lines:
			var start = ball_polys[line.start]
			var end = ball_polys[line.end]
			var raw_radius_start = ball_polys[line.start].material.get_shader_parameter("radius")
			var raw_radius_end = ball_polys[line.end].material.get_shader_parameter("radius")
			var start_radius = raw_radius_start * (line.s_thick / 100.0)
			var end_radius = raw_radius_end * (line.e_thick / 100.0)
			if start_radius < 1 or end_radius < 1 or start.position == end.position:
				lines[linectr].visible = false
				continue
			else:
				lines[linectr].visible = true
			var rect = calculate_rectangle(start.position, end.position, start_radius, end_radius)
			lines[linectr].polygon = rect[0]
			lines[linectr].uv = rect[1]
			var z_sort = min(start.get_index(), end.get_index())
			move_child(lines[linectr], z_sort)
			lines[linectr].position = start.position + (end.position - start.position) / 2.0
			lines[linectr].material.set_shader_parameter("max_uvs", rect[2])
			lines[linectr].material.set_shader_parameter("center", lines[linectr].position + global_position)
			var angle = end.position.angle_to_point(start.position)
			(lines[linectr] as Polygon2D).rotation = angle
			var anglevec = Vector2.from_angle(angle)
			lines[linectr].material.set_shader_parameter("vec_to_upright", anglevec)
			#lines[linectr].visible = false
			linectr += 1
		
		var whisker_ctr = 0
		for whisker in lnz.whiskers:
			var start = ball_polys[whisker.start]
			var end = ball_polys[whisker.end]
			var rect = calculate_rectangle(start.position, end.position, 0.25, 0.25, false)
			whiskers[whisker_ctr].polygon = rect[0]
			whiskers[whisker_ctr].position = start.position + (end.position - start.position) / 2.0
			var angle = end.position.angle_to_point(start.position)
			whiskers[whisker_ctr].rotation = angle
			var z_sort = min(start.get_index(), end.get_index()) + 1
			move_child(whiskers[whisker_ctr], z_sort)
			whisker_ctr += 1
					
		last_chest_pos = next_chest_pos
		last_frame = start_frame + current_frame


@warning_ignore("shadowed_variable")
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
		if apply_anim_movement:
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
		#rottext2.text = "vec: " + str(vec) + "\nangle: " + str(angle) + "\noutput: " + str(min(turn_delta, abs(angle)) * -sign(angle))
		return min(turn_delta, abs(angle)) * -sign(angle)
	elif turn_delta:
		return turn_delta

func reset_pet():
	$SCP.reset()
	current_frame = -999
	start_frame = 0
	last_frame = 0
	ball_rotation = 0
	anim_direction = 1
	turn_delta = 0
	frames_length = 0
	loop = false
	layers = [null, null, null, null, null, null]
	eye_target_type = EYE_TARGET_TYPE.FORWARD
	head_target_type = HEAD_TARGET_TYPE.FORWARD
	
func set_lnz_raw(lnz_text):
	lnz = LnzParser.fromtext(lnz_text)
	setup_lnz()
