extends Behaviour

func advertise(pet, object, with):
	return 99
	
func execute(pet, object, with):
	var scp = pet.get_node("SCP")
	pet.turn_delta = 1
	while true:
		var cursor_pos = get_viewport().get_mouse_position()
		var vec = ((cursor_pos - pet.global_position) as Vector2)
		if(vec.length() > 10):
			#var angle = pet.global_position.angle_to_point(cursor_pos)
			scp.push_action(11)
			await scp.action_done
			
	
	
