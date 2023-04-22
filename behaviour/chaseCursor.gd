extends Behaviour

func advertise(pet, object, with):
	return 99
	
func execute(pet, object, with):
	var scp = pet.get_node("SCP")
	#Engine.time_scale = 0.1
	while true:
		var cursor_pos = get_viewport().get_mouse_position()
		var vec = ((cursor_pos - pet.belly_position) as Vector2)
		var vecl = vec.length()
		var vecrotation = Vector2.LEFT.rotated(deg_to_rad(pet.ball_rotation))
		var angle = rad_to_deg(Vector2.LEFT.angle_to(vec))
		if(vecl > 700):
			if scp.last_action in [0x20e, 0x6]:
				pet.turn_delta = 5
				pet.target_rotation = -angle + 360.0
			scp.push_action(0x20e)
			await scp.action_done
		elif(vecl < 100):
			pet.turn_delta = 0
			scp.push_action(130)
			await scp.action_done
		else:
			if scp.last_action in [0x20e, 0x6]:
				pet.turn_delta = 5
				pet.target_rotation = -angle + 360.0
			scp.push_action(0x6)
			await scp.action_done
			
	
	
