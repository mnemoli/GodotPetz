extends Behaviour

var cursor
var tick = 0

func advertise(_pet, _object, _with):
	return 99
	
func execute(pet, _object, _with):
	var scp = pet.get_node("SCP")
	cursor = get_tree().get_first_node_in_group("cursor")
	pet.ball_rotation = 180
	#Engine.time_scale = 0.5
	while true:
		var cursor_pos = cursor.global_position
		var vec = ((cursor_pos - pet.belly_position) as Vector2)
		var vecl = vec.length()
		var screen_boundaries = get_viewport().get_visible_rect()
		if tick % 7 == 0:
			var rand = randi_range(0, 100)
			if rand < 30:
				pet.head_target_type = pet.HEAD_TARGET_TYPE.TARGET
				pet.eye_target_type = pet.EYE_TARGET_TYPE.TARGET
			elif rand < 60:
				pet.head_target_type = pet.HEAD_TARGET_TYPE.USER
				pet.eye_target_type = pet.EYE_TARGET_TYPE.USER
			else:
				pet.head_target_type = pet.HEAD_TARGET_TYPE.FORWARD
				pet.eye_target_type = pet.EYE_TARGET_TYPE.FORWARD
		tick += 1
		
	#pet.target_sprite = cursor
	#scp.push_action(40)
		if(vecl > 500):
			if scp.last_action in [0x20e, 0x6]:
				if !screen_boundaries.has_point(pet.global_position):
					pet.turn_delta = 10.0
				else:
					pet.turn_delta = 6.0
				pet.target_sprite = cursor
			scp.push_action(0x20e)
			await scp.action_done
		elif(vecl < 150):
			pet.turn_delta = 0
			scp.push_action(40)
			await scp.action_done
		else:
			if scp.last_action in [0x20e, 0x6]:
				pet.turn_delta = 6.0
				pet.target_sprite = cursor
			scp.push_action(0x6)
			await scp.action_done
