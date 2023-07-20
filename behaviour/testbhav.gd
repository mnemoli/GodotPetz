extends Behaviour

func execute(pet, object, with):
	Engine.time_scale = 1.0
	var scp = pet.get_node("SCP")
	pet.ball_rotation = 145
	while true:
		pet.turn_delta = 3
		scp.push_action(210)
		await scp.action_done
	

func in_registry():
	return false
