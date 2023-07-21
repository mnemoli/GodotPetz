extends Behaviour

var cursor

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
