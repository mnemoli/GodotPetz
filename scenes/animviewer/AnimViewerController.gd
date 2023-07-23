extends Node

@onready var pet = get_parent()
@onready var scpinfo = get_tree().get_first_node_in_group("scpinfo")
@onready var curscpinfo = get_tree().get_first_node_in_group("curscpinfo")
@onready var lnz = get_tree().get_first_node_in_group("petlnz")
@onready var scp = pet.get_node("SCP")

func _ready():
	pet.apply_anim_movement = false
	
func _on_button_toggled(button_pressed):
	if !lnz.text.is_empty():
		pet.set_lnz_raw(lnz.text)
	var bhav = pet.get_node("Brain").current_bhav
	if button_pressed:
		bhav.scp_start = scpinfo.get_node("startstate").text as int
		bhav.scp_action = scpinfo.get_node("action").text as int
		bhav.pet_rotation = scpinfo.get_node("rotation").text as int + 180
		bhav.go = true
	else:
		bhav.go = false

func _process(delta):
	curscpinfo.get_node("curstate").text = str(scp.current_state)
	curscpinfo.get_node("curaction").text = str(scp.actionStack.front())
	curscpinfo.get_node("nextstate").text = str(scp.next_state)