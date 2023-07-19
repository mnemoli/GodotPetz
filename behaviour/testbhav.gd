extends Behaviour

func execute(pet, object, with):
	Engine.time_scale = 1.0
	var scp = pet.get_node("SCP")
	scp.push_action(0x377)
	await scp.action_done
	while true:
		pet.turn_delta = 3.0
		scp.push_action(0x6)
		await scp.action_done
	

func in_registry():
	return false
