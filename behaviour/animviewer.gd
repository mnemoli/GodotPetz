extends Behaviour

var go = false
var pet_rotation = 0
var scp_start = 130
var scp_action

func execute(pet, _object, _with):
	Engine.time_scale = 1.0
	var scp = pet.get_node("SCP")
	scp.current_state = 130
	pet.ball_rotation = 180-45
	while true:
		pet.reset_pet()
		while true:
			if go:
				break
			pet.turn_delta = 3
			scp.push_action(210)
			await scp.action_done
		while true:
			if !go:
				break
			pet.reset_pet()
			pet.ball_rotation = pet_rotation
			scp.current_state = scp_start
			scp.push_action(scp_action)
			await scp.action_done

func in_registry():
	return false
