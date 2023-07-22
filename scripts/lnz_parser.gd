extends Node
class_name LnzParser

var r = RegEx.new()
var str_r = RegEx.new()

var species = 0
var scales = Vector2(255, 255)
var leg_extensions = Vector2(0, 0)
var body_extension = 0
var face_extension = 0
var ear_extension = 0
var head_enlargement = Vector2(100, 0)
var foot_enlargement = Vector2(100, 0)
var moves = []
var balls = {}
var lines = []
var addballs = {}
var paintballs = {}
var omissions = {}
var project_ball = []
var texture_list = []
var whiskers = []

var file_path

func get_next_section(file, section_name: String):
	file.seek(0)
	var this_line = ""
	while !this_line.begins_with("[" + section_name + "]") and !file.eof_reached():
		this_line = file.get_line()
	if file.eof_reached():
		return false
	return true
	
func get_parsed_lines(file, keys: Array):
	var return_array = []
	while true:
		var line = file.get_line().dedent()
		if line.is_empty() or line.begins_with("[") or file.eof_reached() or line.begins_with("#2"):
			break
		if line.begins_with(";") or line.begins_with("#"):
			continue
		var parsed = r.search_all(line)
		var dict = {}
		var i = 0
		for key in keys:
			dict[key] = int(parsed[i].get_string())
			i += 1
		return_array.append(dict)
	return return_array
	
func get_parsed_line_strings(file, keys: Array):
	var return_array = []
	while true:
		var line = file.get_line().dedent()
		if line.is_empty() or line.begins_with("[") or file.eof_reached() or line.begins_with("#2"):
			break
		if line.begins_with(";") or line.begins_with("#"):
			continue
		var parsed = str_r.search_all(line)
		var dict = {}
		var i = 0
		for key in keys:
			dict[key] = parsed[i].get_string()
			i += 1
		return_array.append(dict)
	return return_array
	
static func fromtext(text):
	var file = FileAccess.open("user://tmp.lnz", FileAccess.WRITE)
	file.store_string(text)
	file.close()
	var r = LnzParser.new("user://tmp.lnz")
	DirAccess.open("user://").remove("tmp.lnz")
	return r
	
func _init(init_file_path):
	self.file_path = init_file_path
	r.compile("[-.\\d]+")
	str_r.compile("[\\S]+")
	var file = FileAccess.open(file_path, FileAccess.READ)
	
	var this_line = ""
	
	get_texture_list(file)
	get_species(file)
	get_default_scales(file)
	get_leg_extensions(file)
	get_body_extension(file)
	get_face_extension(file)
	get_ear_extension(file)
	get_head_enlargement(file)
	get_feet_enlargement(file)
	get_omissions(file)
	get_lines(file)
	get_balls(file)
	
	file.seek(0)
	
	get_addballs(file)
	get_project_balls(file)
	
	get_whiskers(file)
		
	## Get paintballz
	while this_line != "[Paint Ballz]" and !file.eof_reached():
		this_line = file.get_line()
	while(true):
		this_line = file.get_line()
		if this_line.is_empty() or this_line.begins_with("[") or file.eof_reached() or this_line.begins_with("#2"):
			break
		if this_line.begins_with(";") or this_line.begins_with('#'):
			continue
		var split_line = r.search_all(this_line)
		var base = int(split_line[0].get_string())
		var diameter_percent = int(split_line[1].get_string())
		var x = float(split_line[2].get_string())
		var y = float(split_line[3].get_string())
		var z = float(split_line[4].get_string())
		var color = int(split_line[5].get_string())
		var outline_color = int(split_line[6].get_string())
		if (outline_color == -1):
			outline_color = 0
		var fuzz = int(split_line[7].get_string())
		var outline = int(split_line[8].get_string())
		var texture = int(split_line[10].get_string())
		var anchored = 0
		if split_line.size() > 11:
			anchored = int(split_line[11].get_string())
		var paintball = PaintBallData.new(base, diameter_percent, Vector3(x,y,z), color, outline_color, outline, fuzz, 0, texture, anchored)
		var pb_array = self.paintballs.get(base, [])
		pb_array.append(paintball)
		self.paintballs[base] = pb_array
		
	## Get move data
	file.seek(0)
	while !this_line.begins_with("[Move]") and !file.eof_reached():
		this_line = file.get_line()
	while(true):
		this_line = file.get_line()
		if this_line.is_empty() or this_line.begins_with("[") or file.eof_reached() or this_line.begins_with("#2"):
			break
		if this_line.begins_with(";") or this_line.begins_with('#'):
			continue
		var split_line = r.search_all(this_line)
		var base = int(split_line[0].get_string())
		var x = int(split_line[1].get_string())
		var y = int(split_line[2].get_string())
		var z = int(split_line[3].get_string())
		var relative_ball = base
		if split_line.size() > 4:
			relative_ball = int(split_line[4].get_string())
		var pos = Vector3(x, y, z)
		moves.push_back({base = base, position = pos, relative_to = relative_ball})
		
	file.close()
	
func get_default_scales(file):
	get_next_section(file, "Default Scales")
	var parsed_lines = get_parsed_lines(file, ["scale"])
	if parsed_lines.size() > 0:
		scales = Vector2(parsed_lines[0].scale / 255.0, parsed_lines[1].scale / 255.0)
	
func get_leg_extensions(file):
	get_next_section(file, "Leg Extension")
	var parsed_lines = get_parsed_lines(file, ["extension"])
	if parsed_lines.size() > 0:
		leg_extensions = Vector2(parsed_lines[0].extension, parsed_lines[1].extension)
	
func get_body_extension(file):
	get_next_section(file, "Body Extension")
	var parsed_lines = get_parsed_lines(file, ["extension"])
	if parsed_lines.size() > 0:
		body_extension = parsed_lines[0].extension
	
func get_face_extension(file):
	get_next_section(file, "Face Extension")
	var parsed_lines = get_parsed_lines(file, ["extension"])
	if parsed_lines.size() > 0:
		face_extension = parsed_lines[0].extension

func get_ear_extension(file):
	get_next_section(file, "Ear Extension")
	var parsed_lines = get_parsed_lines(file, ["extension"])
	if parsed_lines.size() > 0:
		ear_extension = parsed_lines[0].extension
	
func get_head_enlargement(file):
	get_next_section(file, "Head Enlargement")
	var parsed_lines = get_parsed_lines(file, ["scale"])
	if parsed_lines.size() > 0:
		head_enlargement = Vector2(parsed_lines[0].scale, parsed_lines[1].scale)
	
func get_feet_enlargement(file):
	get_next_section(file, "Feet Enlargement")
	var parsed_lines = get_parsed_lines(file, ["scale"])
	if parsed_lines.size() > 0:
		foot_enlargement = Vector2(parsed_lines[0].scale, parsed_lines[1].scale)
	
func get_omissions(file):
	get_next_section(file, "Omissions")
	var parsed_lines = get_parsed_lines(file, ["ball_no"])
	omissions = {}
	for line in parsed_lines:
		omissions[line.ball_no] = true
		
func get_lines(file):
	get_next_section(file, "Linez")
	var parsed_lines = get_parsed_lines(file, ["start", "end", "fuzz", "color", "l_color", "r_color", "start_thickness", "end_thickness"])
	for line in parsed_lines:
		var line_data = LineData.new(line.start, line.end, line.start_thickness, line.end_thickness, line.fuzz, line.color, line.l_color, line.r_color)
		lines.append(line_data)
		
func get_balls(file):
	get_next_section(file, "Ballz Info")
	var parsed_lines = get_parsed_lines(file, ["color", "outline_color", "speckle", "fuzz", "outline", "size", "group", "texture"])
	var i = 0
	for line in parsed_lines:
		var bd = BallData.new(
			line.size, 
			Vector3.ZERO, 
			i, 
			Vector3.ZERO,
			line.color,
			line.outline_color, 
			line.outline, 
			line.fuzz, 
			0.0, 
			line.group, 
			line.texture)
		self.balls[i] = bd
		i += 1

func get_addballs(file):
	get_next_section(file, "Add Ball")
	var parsed_lines = get_parsed_lines(file, ["base", "x", "y", "z", "color", "outline_color", "speckle", "fuzz", "group", "outline", "size", "body_area", "add_group", "texture"])
	var max_ball_num = balls.keys().max() + 1
	for line in parsed_lines:
		var pos = Vector3(line.x, line.y, line.z)
		var ball = AddBallData.new(
			line.base,
			max_ball_num, 
		line.size, 
		pos,
		line.color, 
		line.outline_color, 
		line.outline, 
		line.fuzz,
		0, 
		line.group, 
		line.body_area, 
		line.texture)
		addballs[max_ball_num] = ball
		max_ball_num += 1
		
func get_project_balls(file):
	get_next_section(file, "Project Ball")
	var parsed_lines = get_parsed_lines(file, ["base", "projected", "amount"])
	for line in parsed_lines:
		project_ball.append({ball = line.projected, base = line.base, amount = line.amount})
		
func get_whiskers(file):
	get_next_section(file, "Whiskers")
	var parsed_lines = get_parsed_lines(file, ["start", "end"])
	for line in parsed_lines:
		whiskers.push_back({start = line.start, end = line.end})

func get_species(file):
	get_next_section(file, "Species")
	var parsed_lines = get_parsed_lines(file, ["species"])
	if parsed_lines.size() == 0:
		species = 2
	else:
		species = parsed_lines[0].species

func get_texture_list(file):
	get_next_section(file, "Texture List")
	var parsed_lines = get_parsed_line_strings(file, ["filepath", "transparent_color"])
	for line in parsed_lines:
		var filename = line.filepath.get_file()
		texture_list.append({filename = filename, transparent_color = line.transparent_color})

var cat_ball_names = [
	"ankleL", 
"ankleR", 
"belly", 
"butt", 
"cheekL", 
"cheekR", 
"chest", 
"chin", 
"earL1", 
"earL2", 
"earR1", 
"earR2", 
"elbowL", 
"elbowR", 
"eyeL", 
"eyeR", 
"fingerL1", 
"fingerL2", 
"fingerL3", 
"fingerR1", 
"fingerR2", 
"fingerR3", 
"handL", 
"handR", 
"head", 
"hipL", 
"hipR", 
"irisL", 
"irisR", 
"jaw", 
"jowlL",
"jowlR", 
"kneeL", 
"kneeR",
"knuckleL", 
"knuckleR", 
"neck", 
"nose", 
"shoulderL", 
"shoulderR", 
"snout",
"soleL", 
"soleR", 
"tail1", 
"tail2", 
"tail3", 
"tail4", 
"tail5", 
"tail6", 
"toeL1", 
"toeL2", 
"toeL3", 
"toeR1", 
"toeR2", 
"toeR3", 
"tongue1", 
"tongue2", 
"whiskerL1",
"whiskerL2", 
"whiskerL3", 
"whiskerR1",
"whiskerR2", 
"whiskerR3", 
"wristL", 
"wristR", 
"zorient",
"ztrans",
"mountalign",
"capturedtoy",
"digalign",
"fillhole",
"pillow",
"drop",
"util74",
"util75",
"util76",
"nose1",
"nose2",
"nose3",
"ear80",
"ear81",
"ear82",
"ear83",
"ear84",
"ear85",
"ear86",
"ear87",
"ear88",
"ear89",
"ear90",
"ear91"]

var colors = [
	Color.from_string("000000", Color.WHITE),
Color.from_string("800000", Color.WHITE),
Color.from_string("008000", Color.WHITE),
Color.from_string("808000", Color.WHITE),
Color.from_string("000080", Color.WHITE),
Color.from_string("800080", Color.WHITE),
Color.from_string("008080", Color.WHITE),
Color.from_string("C0C0C0", Color.WHITE),
Color.from_string("C8C8C8", Color.WHITE),
Color.from_string("F8D8D8", Color.WHITE),
Color.from_string("E7E2DD", Color.WHITE),
Color.from_string("E3DED8", Color.WHITE),
Color.from_string("DFDAD4", Color.WHITE),
Color.from_string("DBD6D0", Color.WHITE),
Color.from_string("D7D2CC", Color.WHITE),
Color.from_string("D3CEC7", Color.WHITE),
Color.from_string("CFCAC3", Color.WHITE),
Color.from_string("CBC6BF", Color.WHITE),
Color.from_string("C7C2BB", Color.WHITE),
Color.from_string("C3BEB6", Color.WHITE),
Color.from_string("757575", Color.WHITE),
Color.from_string("6F6F6F", Color.WHITE),
Color.from_string("6A6A6A", Color.WHITE),
Color.from_string("656565", Color.WHITE),
Color.from_string("606060", Color.WHITE),
Color.from_string("5B5B5B", Color.WHITE),
Color.from_string("565656", Color.WHITE),
Color.from_string("515151", Color.WHITE),
Color.from_string("4C4C4C", Color.WHITE),
Color.from_string("464646", Color.WHITE),
Color.from_string("424242", Color.WHITE),
Color.from_string("3A3A3A", Color.WHITE),
Color.from_string("333333", Color.WHITE),
Color.from_string("2C2C2C", Color.WHITE),
Color.from_string("242424", Color.WHITE),
Color.from_string("1D1D1D", Color.WHITE),
Color.from_string("161616", Color.WHITE),
Color.from_string("0E0E0E", Color.WHITE),
Color.from_string("070707", Color.WHITE),
Color.from_string("000000", Color.WHITE),
Color.from_string("DCC296", Color.WHITE),
Color.from_string("D5BB90", Color.WHITE),
Color.from_string("CFB58A", Color.WHITE),
Color.from_string("C8AF85", Color.WHITE),
Color.from_string("C2A97F", Color.WHITE),
Color.from_string("BBA27A", Color.WHITE),
Color.from_string("B59C74", Color.WHITE),
Color.from_string("AE966F", Color.WHITE),
Color.from_string("A89069", Color.WHITE),
Color.from_string("A28963", Color.WHITE),
Color.from_string("874122", Color.WHITE),
Color.from_string("7F3D20", Color.WHITE),
Color.from_string("77391E", Color.WHITE),
Color.from_string("70351C", Color.WHITE),
Color.from_string("68311A", Color.WHITE),
Color.from_string("612D18", Color.WHITE),
Color.from_string("592916", Color.WHITE),
Color.from_string("522514", Color.WHITE),
Color.from_string("4A2112", Color.WHITE),
Color.from_string("421D10", Color.WHITE),
Color.from_string("B47316", Color.WHITE),
Color.from_string("AF6D13", Color.WHITE),
Color.from_string("AA6811", Color.WHITE),
Color.from_string("A5630E", Color.WHITE),
Color.from_string("A15E0C", Color.WHITE),
Color.from_string("9C5809", Color.WHITE),
Color.from_string("975307", Color.WHITE),
Color.from_string("934E04", Color.WHITE),
Color.from_string("8E4902", Color.WHITE),
Color.from_string("894400", Color.WHITE),
Color.from_string("F09EB7", Color.WHITE),
Color.from_string("E999B2", Color.WHITE),
Color.from_string("E395AD", Color.WHITE),
Color.from_string("DD91A8", Color.WHITE),
Color.from_string("D68DA3", Color.WHITE),
Color.from_string("D0889E", Color.WHITE),
Color.from_string("CA8499", Color.WHITE),
Color.from_string("C38094", Color.WHITE),
Color.from_string("BD7C8F", Color.WHITE),
Color.from_string("B7778B", Color.WHITE),
Color.from_string("A82901", Color.WHITE),
Color.from_string("A42801", Color.WHITE),
Color.from_string("9F2701", Color.WHITE),
Color.from_string("9B2601", Color.WHITE),
Color.from_string("972501", Color.WHITE),
Color.from_string("922401", Color.WHITE),
Color.from_string("8E2301", Color.WHITE),
Color.from_string("8A2201", Color.WHITE),
Color.from_string("852101", Color.WHITE),
Color.from_string("812001", Color.WHITE),
Color.from_string("6B4A0C", Color.WHITE),
Color.from_string("65440B", Color.WHITE),
Color.from_string("603E0B", Color.WHITE),
Color.from_string("5B390B", Color.WHITE),
Color.from_string("56330B", Color.WHITE),
Color.from_string("512D0A", Color.WHITE),
Color.from_string("4C270A", Color.WHITE),
Color.from_string("47220A", Color.WHITE),
Color.from_string("421C0A", Color.WHITE),
Color.from_string("3C1609", Color.WHITE),
Color.from_string("A68A38", Color.WHITE),
Color.from_string("A28537", Color.WHITE),
Color.from_string("9E8137", Color.WHITE),
Color.from_string("9A7D37", Color.WHITE),
Color.from_string("967836", Color.WHITE),
Color.from_string("937436", Color.WHITE),
Color.from_string("8F7036", Color.WHITE),
Color.from_string("8B6B35", Color.WHITE),
Color.from_string("876735", Color.WHITE),
Color.from_string("846235", Color.WHITE),
Color.from_string("62707D", Color.WHITE),
Color.from_string("5D6976", Color.WHITE),
Color.from_string("586370", Color.WHITE),
Color.from_string("535D69", Color.WHITE),
Color.from_string("4E5763", Color.WHITE),
Color.from_string("49505D", Color.WHITE),
Color.from_string("444A56", Color.WHITE),
Color.from_string("3F4450", Color.WHITE),
Color.from_string("3A3E4A", Color.WHITE),
Color.from_string("363843", Color.WHITE),
Color.from_string("9A8E73", Color.WHITE),
Color.from_string("968A70", Color.WHITE),
Color.from_string("93876D", Color.WHITE),
Color.from_string("90846B", Color.WHITE),
Color.from_string("8C8168", Color.WHITE),
Color.from_string("897E66", Color.WHITE),
Color.from_string("867B63", Color.WHITE),
Color.from_string("827861", Color.WHITE),
Color.from_string("7F755E", Color.WHITE),
Color.from_string("7C715B", Color.WHITE),
Color.from_string("55AB57", Color.WHITE),
Color.from_string("3CA147", Color.WHITE),
Color.from_string("159917", Color.WHITE),
Color.from_string("358336", Color.WHITE),
Color.from_string("307B1C", Color.WHITE),
Color.from_string("107919", Color.WHITE),
Color.from_string("276217", Color.WHITE),
Color.from_string("2F5E2B", Color.WHITE),
Color.from_string("135C14", Color.WHITE),
Color.from_string("104111", Color.WHITE),
Color.from_string("2B61C3", Color.WHITE),
Color.from_string("3846E3", Color.WHITE),
Color.from_string("333BFF", Color.WHITE),
Color.from_string("3343CE", Color.WHITE),
Color.from_string("161AD7", Color.WHITE),
Color.from_string("2E3CB6", Color.WHITE),
Color.from_string("161CA9", Color.WHITE),
Color.from_string("2A4290", Color.WHITE),
Color.from_string("192277", Color.WHITE),
Color.from_string("111953", Color.WHITE),
Color.from_string("D8F0FF", Color.WHITE),
Color.from_string("ACE0FF", Color.WHITE),
Color.from_string("99D6FF", Color.WHITE),
Color.from_string("82CAFF", Color.WHITE),
Color.from_string("75B6E8", Color.WHITE),
Color.from_string("68C0FF", Color.WHITE),
Color.from_string("5196DC", Color.WHITE),
Color.from_string("189CCE", Color.WHITE),
Color.from_string("568BB9", Color.WHITE),
Color.from_string("1E89A9", Color.WHITE),
Color.from_string("EBEDA7", Color.WHITE),
Color.from_string("EAEB90", Color.WHITE),
Color.from_string("D1CC77", Color.WHITE),
Color.from_string("F7F400", Color.WHITE),
Color.from_string("EDE832", Color.WHITE),
Color.from_string("C3C40B", Color.WHITE),
Color.from_string("C3C334", Color.WHITE),
Color.from_string("9FA217", Color.WHITE),
Color.from_string("9F9F43", Color.WHITE),
Color.from_string("6E7A2E", Color.WHITE),
Color.from_string("FFFFFF", Color.WHITE),
Color.from_string("C0E4E7", Color.WHITE),
Color.from_string("ACC6D5", Color.WHITE),
Color.from_string("A7A7B1", Color.WHITE),
Color.from_string("A0A0A8", Color.WHITE),
Color.from_string("74A0B6", Color.WHITE),
Color.from_string("8399B1", Color.WHITE),
Color.from_string("8399B1", Color.WHITE),
Color.from_string("8098B0", Color.WHITE),
Color.from_string("8098B0", Color.WHITE),
Color.from_string("E2BEAC", Color.WHITE),
Color.from_string("D59390", Color.WHITE),
Color.from_string("D7766E", Color.WHITE),
Color.from_string("B87367", Color.WHITE),
Color.from_string("9F7773", Color.WHITE),
Color.from_string("A26A5D", Color.WHITE),
Color.from_string("896458", Color.WHITE),
Color.from_string("98574D", Color.WHITE),
Color.from_string("6A4542", Color.WHITE),
Color.from_string("5A3C31", Color.WHITE),
Color.from_string("729E8C", Color.WHITE),
Color.from_string("008080", Color.WHITE),
Color.from_string("427A75", Color.WHITE),
Color.from_string("008080", Color.WHITE),
Color.from_string("397860", Color.WHITE),
Color.from_string("3D5A63", Color.WHITE),
Color.from_string("265847", Color.WHITE),
Color.from_string("21412B", Color.WHITE),
Color.from_string("123930", Color.WHITE),
Color.from_string("FFFFFF", Color.WHITE),
Color.from_string("FFFFFF", Color.WHITE),
Color.from_string("F4F6D8", Color.WHITE),
Color.from_string("E9D8C2", Color.WHITE),
Color.from_string("2C5F59", Color.WHITE),
Color.from_string("D3F4C5", Color.WHITE),
Color.from_string("C4D39F", Color.WHITE),
Color.from_string("FFC71A", Color.WHITE),
Color.from_string("B0B89B", Color.WHITE),
Color.from_string("AFB177", Color.WHITE),
Color.from_string("A5948E", Color.WHITE),
Color.from_string("ACA98F", Color.WHITE),
Color.from_string("D7A014", Color.WHITE),
Color.from_string("C67F08", Color.WHITE),
Color.from_string("CA6E46", Color.WHITE),
Color.from_string("798E61", Color.WHITE),
Color.from_string("997E4D", Color.WHITE),
Color.from_string("808080", Color.WHITE),
Color.from_string("659B2A", Color.WHITE),
Color.from_string("00CB16", Color.WHITE),
Color.from_string("A76C39", Color.WHITE),
Color.from_string("FF4200", Color.WHITE),
Color.from_string("976442", Color.WHITE),
Color.from_string("99652A", Color.WHITE),
Color.from_string("DD346A", Color.WHITE),
Color.from_string("294475", Color.WHITE),
Color.from_string("5869B5", Color.WHITE),
Color.from_string("426B84", Color.WHITE),
Color.from_string("506480", Color.WHITE),
Color.from_string("75594A", Color.WHITE),
Color.from_string("99B4D1", Color.WHITE),
Color.from_string("BFCDDB", Color.WHITE),
Color.from_string("F0F0F0", Color.WHITE),
Color.from_string("FFFFFF", Color.WHITE),
Color.from_string("646464", Color.WHITE),
Color.from_string("000000", Color.WHITE),
Color.from_string("000000", Color.WHITE),
Color.from_string("000000", Color.WHITE),
Color.from_string("B4B4B4", Color.WHITE),
Color.from_string("F4F7FC", Color.WHITE),
Color.from_string("ABABAB", Color.WHITE),
Color.from_string("0078D7", Color.WHITE),
Color.from_string("FFFFFF", Color.WHITE),
Color.from_string("F0F0F0", Color.WHITE),
Color.from_string("0078D7", Color.WHITE),
Color.from_string("000000", Color.WHITE),
Color.from_string("FFFFFF", Color.WHITE),
Color.from_string("6D6D6D", Color.WHITE),
Color.from_string("000000", Color.WHITE),
Color.from_string("808080", Color.WHITE),
Color.from_string("FF0000", Color.WHITE),
Color.from_string("00FF00", Color.WHITE),
Color.from_string("FFFF00", Color.WHITE),
Color.from_string("0000FF", Color.WHITE),
Color.from_string("FF00FF", Color.WHITE),
Color.from_string("00FFFF", Color.WHITE),
Color.from_string("000000", Color.WHITE)
]
