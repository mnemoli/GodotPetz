extends Behaviour

func execute(pet, object, with):
	print("diddle doddle")
	var scp = pet.get_node("SCP")
	var case = get_tree().get_first_node_in_group("case") as Node2D
	var door = case.find_child("door")
	pet.reparent(door)
	pet.position = door.get_node("petattachpoint").position
	case.open_door_for_pet()
	pet.show_behind_parent = true
	pet.ball_rotation = 90
	print("pushing 0x377")
	scp.push_action(0x377)
	await scp.action_done
	pet.update_pos()
	pet.show_behind_parent = false
	print("pushing 0x59e")
	scp.push_action(0x59e)
	await scp.action_done
	print("pushing 0x20e")
	scp.push_action(0x20e)
	await scp.action_done
	print("posting done")
	done = true
	emit_signal("behaviour_done")

func in_registry():
	return false