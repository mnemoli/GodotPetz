extends Node

var scp: PetzScpResource = preload("res://animations/CAT.scp")
var graph: Dictionary
var actionStack = []
var processing = false
var current_state = scp.get_start_state()
var script_stack = []
var last_action = -1

signal action_done

func _ready():
	for a in scp.get_actions():
		var ar = graph.get(a.startState, [])
		ar.push_back({endState = a.endState, actionId = a.id})
		graph[a.startState] = ar

func push_action(goal_action):
	actionStack = find_path(current_state, goal_action)

func find_path(start_state, goal_action):
	var desired_state = scp.get_action(goal_action).startState
	if start_state == desired_state:
		return [goal_action]
	var explored = Dictionary()
	var q = []
	q.push_back({stateId = start_state, actionId = null, parent = null})
	explored[start_state] = true
	while !q.is_empty():
		var v = q.pop_front()
		if v.actionId == goal_action:
			var path = []
			while v.parent:
				path.push_back(v.actionId)
				v = v.parent
			path.reverse()
			return path
		var edgear = graph.get(v.stateId, []) as Array
		edgear.shuffle()
		for edge in edgear:
			if !explored.has(edge.endState) || edge.actionId == goal_action:
				explored[edge.endState] = true
				var w = {stateId = edge.endState, actionId = edge.actionId, parent = v}
				q.push_back(w)

func _process(_delta):
	if !actionStack.is_empty() and !processing:
		processing = true
		var curaction = scp.get_action(actionStack.front())
		get_parent().loop = last_action == curaction.id
		script_stack = curaction.scripts[0].duplicate()
		while !script_stack.is_empty():
			var currentelem = script_stack.pop_front()
			match currentelem: # seq2
				0x40000033:
					var minframe = script_stack.pop_front()
					var maxframe = script_stack.pop_front()
					var direction = 1
					if maxframe < minframe:
						print("uh oh backwards anim")
						direction = -1
					#print("requesting anim from " + str(minframe))
					get_parent().play_anim(minframe, abs(maxframe - minframe) + 1, direction)
					await get_parent().animation_done
				0x40000027: #playaction2
					var actionid = script_stack.pop_front()
					var times = script_stack.pop_front()
					print("playing " + str(actionid) + " " + str(times) + " times")
					if times == 0x4000002F: #rand2
						var rand1 = script_stack.pop_front()
						var rand2 = script_stack.pop_front()
						times = randi_range(rand1, rand2)
					var newelems = scp.get_action(actionid).scripts[0] as Array
					newelems.push_back(0x40000014)
					var cop = newelems.duplicate()
					for i in range(0, times):
						newelems.append_array(cop)
					newelems.append_array(script_stack)
					script_stack = newelems
				0x4000000F: #enablefudgeaim1
					script_stack.pop_front()
				0x40000009: #cuecode1
					script_stack.pop_front()
				0x40000014: #gluescriptsball1
					get_parent().update_pos()
				_: 
					if currentelem < 0x40000000: #frame number
						get_parent().play_anim(currentelem, 1, 1)
						await get_parent().animation_done
		processing = false
		last_action = actionStack.pop_front()
		current_state = scp.get_action(last_action).endState
		get_parent().update_pos()
		if actionStack.is_empty():
			emit_signal("action_done")
