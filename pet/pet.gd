extends Node2D

@export var draw_scale = 0.5;
var current_frame = -1;
var start_frame = 0
var frames_length = 20
var ball_rotation = 0
var target_rotation = 0
var last_chest_pos = Vector3.ZERO
var turn_delta = 0
var reset = false
var belly_position = Vector3.ZERO
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
		$TargetLine.points = [Vector2.ZERO, Vector2.LEFT.rotated(deg_to_rad(target_rotation)) * 50.0]
		if target_rotation != ball_rotation and turn_delta > 0:
			this_turn_delta = get_next_turn_delta()
			rottext.text = str(ball_rotation) + "\n" + str(target_rotation) + "\n" + str(this_turn_delta)
			ball_rotation += this_turn_delta
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
				last_chest_pos = ball_position
			if i == 2:
				belly_position = Vector2(rotated.x, rotated.y) + global_position
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
			else:
				draw_circle(pos, size - 1, Color.ANTIQUE_WHITE)

func _on_timer_timeout():
	current_frame = current_frame + 1
	if current_frame == frames_length:
		emit_signal("animation_done")
	current_frame = current_frame % frames_length
	queue_redraw()

func play_anim(start_frame, length):
	self.start_frame = start_frame
	self.frames_length = length
	self.current_frame = 0
	if reset:
		var frame = ContentLoader.animations.get_frame(start_frame + current_frame) as Dictionary
		var turn_delta = get_next_turn_delta()
		var chest_pos = frame.ball_array[6].position
		var chestrot = chest_pos.rotated(Vector3.UP, deg_to_rad(ball_rotation))
		chestrot = chestrot.rotated(Vector3.LEFT, deg_to_rad(15))
		var rot1 = chest_pos.rotated(Vector3.UP, deg_to_rad(ball_rotation))
		rot1 = rot1.rotated(Vector3.LEFT, deg_to_rad(15))
		var rot2 = last_chest_pos.rotated(Vector3.UP, deg_to_rad(ball_rotation))
		rot2 = rot2.rotated(Vector3.LEFT, deg_to_rad(15))
		var diff = Vector2(rot1.x, rot1.y) - Vector2(rot2.x, rot2.y)
		position += diff * draw_scale * -1.0
		reset = false
	queue_redraw()
	
func update_pos():
	reset = true

func get_next_turn_delta():
	var diff = fmod((target_rotation - ball_rotation), 360.0) - 180.0
	var this_turn_delta = turn_delta * sign(diff)
	if diff < 0:
		this_turn_delta = max(this_turn_delta, diff)
	else:
		this_turn_delta = min(this_turn_delta, diff)
	return -this_turn_delta
