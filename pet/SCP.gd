extends Node

@onready var pet = get_parent()
var scp: PetzScpResource = preload("res://animations/CAT.scp")
var breed_overrides = {}
var breed_scp: PetzScpResource = null:
	set(value):
		breed_scp = value
		if value == null:
			update_graph(scp)
		else:
			update_graph(value)
var graph: Dictionary
var actionStack = []
var processing = false
var current_state = scp.get_start_state()
var script_stack = []
var last_action = -1
var next_state = -1
var current_script_no = 0
var layered_stacks = [[], [], [], [], [], []]
var current_base_frame = -1
var step_ctr = 0

signal action_done

func _ready():
	randomize()
	update_graph(scp)
		
func update_graph(this_scp):
	var actions = this_scp.get_actions()
	for k in actions:
		var a = actions[k]
		var ar = graph.get(a.startState, [])
		ar.push_back({endState = a.endState, actionId = a.id})
		graph[a.startState] = ar

func push_action(goal_action):
	actionStack = find_path(current_state, goal_action)
	current_base_frame = -1
	
func get_action_or_override(action_id):
	if breed_scp != null and breed_scp.has_action(action_id):
		return breed_scp.get_action(action_id)
	else:
		return scp.get_action(action_id)

func find_path(start_state, goal_action):
	var desired_state = get_action_or_override(goal_action).startState
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
	
	return []

func _process(_delta):
	if !actionStack.is_empty() and !processing:
		processing = true
		step_ctr = 0
		var last_chance_succeeded = null
		var curaction = get_action_or_override(actionStack.front())
		next_state = curaction.endState
		pet.loop = last_action == curaction.id
		var numscripts = curaction.scripts.size()
		var randscript = randi_range(0, numscripts - 1)
		script_stack = curaction.scripts[randscript].duplicate(true)
		current_script_no = randscript
		while !script_stack.is_empty():
			var currentelem = script_stack.pop_front()
			step_ctr += 1
			match currentelem:
				0x40000014: #gluescriptsball1
					script_stack.pop_front()
					pet.update_pos()
				0x40000019: #lookatRandomPt0
					pet.head_target_type = pet.HEAD_TARGET_TYPE.TARGET
					print("Looking at random point head")
					pet.target_look_location = pet.global_position + Vector2(randi_range(-100, 100), randi_range(-100, 100))
				0x4000001A: #lookatRandomPtEyes0
					pet.eye_target_type = pet.EYE_TARGET_TYPE.TARGET
					print("Looking at random point eyes")
					pet.target_look_location = pet.global_position + Vector2(randi_range(-100, 100), randi_range(-100, 100))
				0x4000001B: #lookAtSprite1
					pet.head_target_type = pet.HEAD_TARGET_TYPE.TARGET
					script_stack.pop_front()
					pet.target_look_location = pet.global_position + Vector2(0, 100)
					print("Looking at sprite head")
				0x4000001C: #lookAtSpriteEyes1
					pet.eye_target_type = pet.EYE_TARGET_TYPE.TARGET
					pet.target_look_location = pet.global_position + Vector2(0, 100)
					script_stack.pop_front()
					print("Looking at sprite eyes")
				0x4000001D: #lookAtUser0
					pet.head_target_type = pet.HEAD_TARGET_TYPE.USER
					pet.eye_target_type = pet.EYE_TARGET_TYPE.USER
					print("Looking at user")
				0x4000001F: #lookForward0
					pet.head_target_type = pet.HEAD_TARGET_TYPE.FORWARD
					print("Looking forward head")
				0x4000001F: #lookForwardEyes0
					pet.eyes_target_type = pet.EYES_TARGET_TYPE.FORWARD
					print("Looking forward eyes")
				0x40000027: #playaction2
					var actionid = script_stack.pop_front()
					var times = script_stack.pop_front()
					if times == 0x4000002F: #rand2
						var rand1 = script_stack.pop_front()
						var rand2 = script_stack.pop_front()
						times = randi_range(rand1, rand2)
					print("playing " + str(actionid) + " " + str(times) + " times from action " + str(actionStack.front()))
					var newelems = (get_action_or_override(actionid).scripts[0] as Array).duplicate(true)
					var cop = newelems.duplicate(true)
					newelems.push_back(0x40000014)
					newelems.push_back(-1)
					if times > 0:
						for i in range(times - 1):
							newelems.append_array(cop)
					newelems.append_array(script_stack)
					script_stack = newelems
				0x4000002A: #layeredaction3
					var layeredaction = script_stack.pop_front()
					var unknown = script_stack.pop_front()
					if unknown == 0x4000002F:
						var rand1 = script_stack.pop_front()
						var rand2 = script_stack.pop_front()
						unknown = randi_range(rand1, rand2) - 1
					var layer = script_stack.pop_front()
					call_deferred("run_layered_action", layer, layeredaction)
				0x4000002C: #playlayeredactioncallback5
				#callback6 not used in cat scp
					var _chancetype = script_stack.pop_front()
					var action1 = script_stack.pop_front()
					var _action2 = script_stack.pop_front()
					var unknown = script_stack.pop_front()
					if unknown == 0x4000002F:
						var rand1 = script_stack.pop_front()
						var rand2 = script_stack.pop_front()
						unknown = randi_range(rand1, rand2) - 1
					var layer = script_stack.pop_front()
					call_deferred("run_layered_action", layer, action1)
				0x40000033: # seq2
				# 33 and 34 not used in cat scp
					var minframe = script_stack.pop_front()
					var maxframe = script_stack.pop_front()
					var direction = 1
					if maxframe < minframe:
						print("uh oh backwards anim")
						direction = -1
					print("requesting anim from " + str(minframe) + " to " + str(maxframe))
					pet.play_anim(minframe, abs(maxframe - minframe) + 1, direction)
					if current_base_frame == -1:
						current_base_frame = min(maxframe, minframe)
					await pet.animation_done
				0x4000003E: #setlayeredbaseframe2
					var layer = script_stack.pop_front()
					var baseframe = script_stack.pop_front()
					if pet.layers[layer] != null:
						if baseframe == -1:
							#pet.layers[layer].base_frame = current_base_frame
							pet.layers[layer].base_frame = -1
						else:
							pet.layers[layer].base_frame = baseframe
				0x40000055: #startBlockLoop1
					var times = script_stack.pop_front()
					if times == 0x4000002F:
						var rand1 = script_stack.pop_front()
						var rand2 = script_stack.pop_front()
						times = randi_range(rand1, rand2) - 1
					var loopelems = extract_block()
					var cp = loopelems.duplicate()
					if times >= 0:
						for i in times:
							loopelems += cp
					script_stack = loopelems + script_stack
					print("Looping " + str(times) + " times")
				0x40000056: #startBlockCallback2
					var chance1 = []
					script_stack.pop_front()
					script_stack.pop_front()
					chance1 = extract_block()
					last_chance_succeeded = true
					script_stack = chance1 + script_stack
				0x40000057: #startBlockChance1
					var chance = script_stack.pop_front()
					var chancelems = extract_block()
					var rand = randi_range(0, 100)
					if rand < chance:
						script_stack = chancelems + script_stack
						last_chance_succeeded = true
					else:
						last_chance_succeeded = false
				0x40000059: #startBlockElse0
					if last_chance_succeeded == false:
						var chancelems = extract_block()
						script_stack = chancelems + script_stack
					last_chance_succeeded = null
				_: 
					if currentelem < 0x40000000: #frame number
						if currentelem < 0 or currentelem > 16040:
							print("BIG MISTAKE")
						else:
							pet.play_anim(currentelem, 1, 1)
							if current_base_frame == -1:
								current_base_frame = currentelem
							await pet.animation_done
					else:
						var verbname = scpVerbs[currentelem] as String
						var argcount = verbname.right(1)
						if argcount.is_valid_int():
							argcount = argcount as int
						else:
							argcount = 0
						for n in range(argcount):
							var top = script_stack.pop_front()
							if top == 0x4000002F: #rand2
								script_stack.pop_front()
								script_stack.pop_front()
		processing = false
		last_action = actionStack.pop_front()
		current_state = next_state
		pet.update_pos()
		if actionStack.is_empty():
			emit_signal("action_done")
	elif actionStack.is_empty() and !processing:
		emit_signal("action_done")

func reset():
	actionStack = []
	script_stack = []
	layered_stacks = [[], [], [], [], [], []]
	processing = false
	current_state = 130
	last_action = -1
	next_state = 130
	
func run_layered_action(layer, action):
	print("playing layered action " + str(action) + " on layer " + str(layer))
	layered_stacks[layer] = get_action_or_override(action).scripts[0].duplicate() as Array
	while !layered_stacks[layer].is_empty():
		var elem = layered_stacks[layer].pop_front()
		match elem:
			0x40000033: # seq2
				var minframe = layered_stacks[layer].pop_front()
				var maxframe = layered_stacks[layer].pop_front()
				if maxframe < minframe:
					print("uh oh backwards anim in layer - not dealt with")
				var size = abs(maxframe - minframe) + 1
				var b
				if pet.layers[layer] != null:
					b = pet.layers[layer].base_frame
				else:
					b = -1
				pet.layers[layer] = {start_frame = minframe, size = size, current = 0, base_frame = b}
				print("playing layered frames " + str(minframe) + " to " + str(maxframe) + " base " + str(b))
				while await pet.layered_animation_done != layer:
					pass
			_:
				if elem < 0x40000000: #frame number
						if elem < 0 or elem > 16040:
							print("BIG MISTAKE")
						else:
							var b
							if pet.layers[layer] != null:
								b = pet.layers[layer].base_frame
							else:
								b = -1
							pet.layers[layer] = {start_frame = elem, size = 1, current = 0, base_frame = b}
							print("playing layered frames " + str(elem) + " to " + str(elem + 1) + " base " + str(b))
							while await pet.layered_animation_done != layer:
								pass
				else:
					var verbname = scpVerbs[elem] as String
					var argcount = verbname.right(1)
					if argcount.is_valid_int():
						argcount = argcount as int
					else:
						argcount = 0
					for n in range(argcount):
						var top = layered_stacks[layer].pop_front()
						if top == 0x4000002F: #rand2
							layered_stacks[layer].pop_front()
							layered_stacks[layer].pop_front()
							

func extract_block():
	var loopelems = []
	var currentelem = -1
	var depth = 1
	while !(currentelem == 0x40000011 and depth == 0):
		currentelem = script_stack.pop_front()
		if currentelem in blockStarts:
			depth += 1
		elif currentelem in blockEnds:
			depth -= 1
		loopelems.push_back(currentelem)
	return loopelems

var blockStarts = [0x40000055, 0x40000056, 0x40000057, 0x40000058, 0x40000059, 0x4000005A]
var blockEnds = [0x40000011, 0x40000012]

var scpVerbs = {
	0x40000000 : "startPos",

0x40000001 : "actionDone0",

0x40000002 : "actionStart1",

0x40000003 : "alignScripts0",

0x40000004 : "alignBallToPtSetup3",

0x40000005 : "alignBallToPtGo0",

0x40000006 : "alignBallToPtStop0",

0x40000007 : "alignFudgeBallToPtSetup2",

0x40000008 : "blendToFrame3",

0x40000009 : "cueCode1",

0x4000000A : "debugCode1",

0x4000000B : "disableFudgeAim1",

0x4000000C : "disableSwing0",

0x4000000D : "doneTalking0",

0x4000000E : "doneTalking1",

0x4000000F : "enableFudgeAim1",

0x40000010 : "enableSwing1",

0x40000011 : "endBlock0",

0x40000012 : "endBlockAlign0",

0x40000013 : "glueScripts0",

0x40000014 : "glueScriptsBall1",

0x40000015 : "interruptionsDisable0",

0x40000016 : "interruptionsEnable0",

0x40000017 : "lookAtLocation2",

0x40000018 : "lookAtLocationEyes2",

0x40000019 : "lookAtRandomPt0",

0x4000001A : "lookAtRandomPtEyes0",

0x4000001B : "lookAtSprite1",

0x4000001C : "lookAtSpriteEyes1",

0x4000001D : "lookAtUser0",

0x4000001E : "lookForward0",

0x4000001F : "lookForwardEyes0",

0x40000020 : "null0",

0x40000021 : "null1",

0x40000022 : "null2",

 

0x40000023 : "null3",

 

0x40000024 : "null4",

 

0x40000025 : "null5",

 

0x40000026 : "null6",

 

0x40000027 : "playAction2",

 

0x40000028 : "playActionRecall2",

 

0x40000029 : "playActionStore2",

 

0x4000002A : "playLayeredAction3",

 

0x4000002B : "playLayeredAction4",

 

0x4000002C : "playLayeredActionCallback5",

 

0x4000002D : "playLayeredActionCallback6",

 

0x4000002E : "playTransitionToAction1",

 

0x4000002F : "rand2",

 

0x40000030 : "resetFudger1",

 

0x40000031 : "resumeFudging1",

 

0x40000032 : "resumeLayerRotation1",

 

0x40000033 : "sequence2",

0x40000034 : "sequenceToEnd1",

0x40000035 : "sequenceToStart1",

0x40000036 : "setBlendOffset3",

0x40000037 : "setFudgeAimDefaults5",

0x40000038 : "setFudgerDrift2",

0x40000039 : "setFudgerRate2",

0x4000003A : "setFudgerTarget2",

0x4000003B : "setFudgerNow2",

0x4000003C : "setHeadTrackAcuteness",

0x4000003D : "setHeadTrackMode1",

0x4000003E : "setLayeredBaseFrame2",

0x4000003F : "setMotionScale1",

0x40000040 : "setMotionScale2",

0x40000041 : "setReverseHeadTrack1",

0x40000042 : "setRotationPivotBall1",

 

0x40000043 : "soundEmptyQueue0",

 

0x40000044 : "soundLoop1",

 

0x40000045 : "soundSetPan1",

 

0x40000046 : "soundPlay1",

 

0x40000047 : "soundPlay2",

 

0x40000048 : "soundPlay3",

 

0x40000049 : "soundPlay4",

 

0x4000004A : "soundPlay5",

 

0x4000004B : "soundQueue1",

 

0x4000004C : "soundQueue2",

 

0x4000004D : "soundQueue3",

 

0x4000004E : "soundQueue4",

 

0x4000004F : "soundQueue5",

 

0x40000050 : "soundSetDefltVocPitch1",

 

0x40000051 : "soundSetPitch1",

 

0x40000052 : "soundSetVolume1",

 

0x40000053 : "soundStop0",

 

0x40000054 : "startListening0",

 

0x40000055 : "startBlockLoop1",

 

0x40000056 : "startBlockCallback2",

 

0x40000057 : "startBlockChance1",

 

0x40000058 : "startBlockDialogSynch0",

 

0x40000059 : "startBlockElse0",

 

0x4000005A : "startBlockListen0",

 

0x4000005B : "stopFudging1",

 

0x4000005C : "suspendFudging1",

 

0x4000005D : "suspendLayerRotation1",

 

0x4000005E : "tailSetNeutral1",

 

0x4000005F : "tailSetRestoreNeutral1",

 

0x40000060 : "tailSetWag1",

 

0x40000061 : "targetSprite4",

 

0x40000062 : "throwMe0",

 

0x40000063 : "endPos",
}
