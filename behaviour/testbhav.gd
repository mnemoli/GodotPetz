extends Behaviour

func execute(pet, _object, _with):
	Engine.time_scale = 1.0
	var scp = pet.get_node("SCP")
	scp.current_state = 130
	pet.ball_rotation = 180-45
	while true:
		pet.turn_delta = 3
		scp.push_action(210)
		await scp.action_done
	

func in_registry():
	return false
