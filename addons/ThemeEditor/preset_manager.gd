@tool 
extends PanelContainer
signal presets_changed
var presets = {"colors":{}, "numbers":{}}

func _ready():	
	if Engine.is_editor_hint():
		%close_button.visible = false
	else:
		if get_parent() == get_tree().root: 
			push_error("trying to run preset manager as a scene: it should be child of theme editor, or managed by editor plugin")
			get_tree().quit() 
			return
		%close_button.visible = true
		%close_button.pressed.connect(queue_free)
	load_presets()
	%add_number_preset_button.pressed.connect(add_number_preset)
	%add_color_preset_button.pressed.connect(add_color_preset)
	%add_stylebox_preset_button.pressed.connect(add_stylebox_preset)
	%add_font_preset_button.pressed.connect(add_font_preset)
	%add_textures_preset_button.pressed.connect(add_texture_preset)

func add_stylebox_preset():
	var i = 0
	var new_name = "new_stylebox"
	while presets.styleboxes.has(new_name):
		i+=1
		new_name = "new_stylebox_" + str(i)
	presets.styleboxes[new_name] = {
		"is_texture": false,
		"background_color":"default",
		"background_enabled":"default",
		"background_skew_x":"default",
		"background_skew_y":"default",
		"border_color":"default",
		"border_left":"default", 
		"border_top":"default",
		"border_right":"default",
		"border_bottom":"default",
		"border_blend":"default",
		"corners_top_left":"default",
		"corners_top_right":"default",
		"corners_bottom_left":"default",
		"corners_bottom_right":"default",
		"corners_detail":"default",
		"margins_left":"default",
		"margins_top":"default",
		"margins_right":"default",
		"margins_bottom":"default",
		"shadow_color":"default",
		"shadow_size":"default",
		"shadow_offset_x":"default",
		"shadow_offset_y":"default",
	}
	add_stylebox_preset_ui(new_name)
	
func add_font_preset():
	var i = 0
	var new_name = "new_font"
	while presets.fonts.has(new_name):
		i+=1
		new_name = "new_font_" + str(i)
	presets.fonts[new_name] = 0
	add_font_preset_ui(new_name)
	
func add_texture_preset():
	var i = 0
	var new_name = "new_texture"
	while presets.textures.has(new_name):
		i+=1
		new_name = "new_texture_" + str(i)
	presets.textures[new_name] = 0
	add_texture_preset_ui(new_name)
	
func add_number_preset():
	var i = 0
	var new_name = "new_number"
	while presets.numbers.has(new_name):
		i+=1
		new_name = "new_number_" + str(i)
	presets.numbers[new_name] = 0
	add_number_preset_ui(new_name)

func add_color_preset():
	var i = 0
	var new_name = "new_color"
	while presets.colors.has(new_name):
		i+=1
		new_name = "new_color_" + str(i)
	presets.colors[new_name] = Color.BLACK
	add_color_preset_ui(new_name)
	
func add_number_preset_ui(key):
	if key == "default": return
	var value = presets.numbers[key]
	var node = preload("number_preset_editor.tscn").instantiate()	
	node.preset_name = key
	node.preset_value = value if value else 0		
	%number_preset_list.add_child(node)
	node.value_changed.connect(func(new_value):
		presets.numbers[node.preset_name] = new_value
		presets_changed.emit("numbers", node.preset_name)
	)
	node.rename_requested.connect(rename_preset.bind(presets.numbers, node))	
	node.remove_requested.connect(remove_preset.bind(presets.numbers, node))
	
	
func add_color_preset_ui(key):	
	if key == "default": return	
	var node = preload("color_preset_picker.tscn").instantiate()
	node.preset_name = key
	node.preset_color = presets.colors[key]
	%color_preset_list.add_child(node)
	node.color_changed.connect(func(new_color):
		presets.colors[node.preset_name] = new_color
		presets_changed.emit("colors", node.preset_name)
	)
	node.rename_requested.connect(rename_preset.bind(presets.colors, node))	
	node.remove_requested.connect(remove_preset.bind(presets.colors, node))
	
		
func add_stylebox_preset_ui(key):
	if key == "default": return
	var node = preload("stylebox_preset_editor.tscn").instantiate()
	node.presets = presets
	node.preset_name = key
	node.is_texture = false	
	%stylebox_preset_list.add_child(node)	
	node.stylebox_duplicated.connect(add_stylebox_preset_ui)
	node.stylebox_changed.connect(func(): 
		presets_changed.emit("styleboxes", node.preset_name)
	)
	node.rename_requested.connect(rename_preset.bind(presets.styleboxes, node))	
	node.remove_requested.connect(remove_preset.bind(presets.styleboxes, node))
	
	
func add_font_preset_ui(key):
	if key == "default": return
	var node = preload("font_preset_editor.tscn").instantiate()	
	node.preset_name = key
	node.initial_font_path = presets.fonts[key]			
	%font_preset_list.add_child(node)	
	node.font_changed.connect(func(preset, path):
		presets.fonts[preset] = path
		presets_changed.emit("fonts", node.preset_name)
	)
	node.font_duplicated.connect(func(new_name, old_name):
		presets.fonts[new_name] = presets.fonts[old_name].duplicate(true)
		add_font_preset_ui(new_name)
	)
	node.rename_requested.connect(rename_preset.bind(presets.fonts, node))	
	node.remove_requested.connect(remove_preset.bind(presets.fonts, node))
	
	
	
func add_texture_preset_ui(key):
	if key == "default": return
	var node = preload("texture_preset_editor.tscn").instantiate()	
	node.preset_name = key
	node.initial_texture_path = presets.textures[key]			
	%textures_preset_list.add_child(node)		
	node.texture_changed.connect(func(preset, path):
		presets.textures[preset] = path
		presets_changed.emit("textures", node.preset_name)
	)
	node.texture_duplicated.connect(func(new_name, old_name):
		presets.textures[new_name] = presets.textures[old_name].duplicate(true)
		add_texture_preset_ui(new_name)
	)
	node.rename_requested.connect(rename_preset.bind(presets.textures, node))	
	node.remove_requested.connect(remove_preset.bind(presets.textures, node))
	
func rename_preset(new_name, dictionary_parent,node):
	if " " in new_name or new_name in dictionary_parent.keys(): 			
		node.reset_name()		
	else:
		var old_name = node.preset_name
		dictionary_parent[new_name] = dictionary_parent[old_name]
		dictionary_parent.erase(old_name)
		node.preset_name = new_name
		for type in presets.classes.keys():			
			for prop in presets.classes[type].keys():
				var value = presets.classes[type][prop]			
				if typeof(value) == TYPE_STRING and value == old_name:
					presets.classes[type][prop] = new_name		
		for type in presets.styleboxes.keys():
			if type == "default": continue
			for prop in presets.styleboxes[type].keys():
				var value = presets.styleboxes[type][prop]			
				if typeof(value) == TYPE_STRING and value == old_name:
					presets.styleboxes[type][prop] = new_name
		load_presets()
		
func remove_preset(preset_name, dictionary_parent, node):
	var dialog := ConfirmationDialog.new()
	var users = []
	for type in presets.classes.keys():
		for prop in presets.classes[type].keys():
			var value = presets.classes[type][prop]			
			if typeof(value) == TYPE_STRING and preset_name == value:
				users.push_back([type,prop])
	dialog.dialog_text = "Are you sure you want to delete %s? current users: %s" % [preset_name, len(users) ]
	dialog.confirmed.connect(func():
		for user in users:				
			presets.classes[user[0]][user[1]] = "default"				
		dictionary_parent.erase(preset_name)
		node.queue_free()
	)
	add_child(dialog)
	dialog.popup_centered()


func clear_preset_ui():
	for child in %color_preset_list.get_children():
		%color_preset_list.remove_child(child)
		child.queue_free()
	for child in %number_preset_list.get_children():
		%number_preset_list.remove_child(child)
		child.queue_free()
	for child in %stylebox_preset_list.get_children():
		%stylebox_preset_list.remove_child(child)
		child.queue_free()
	for child in %font_preset_list.get_children():
		%font_preset_list.remove_child(child)
		child.queue_free()
	for child in %textures_preset_list.get_children():
		%textures_preset_list.remove_child(child)
		child.queue_free()	
		
func load_presets(_theme_path = null):
	clear_preset_ui()		
	var keys = presets.colors.keys()
	keys.sort()
	for key in keys:			
		add_color_preset_ui(key)
	keys = presets.numbers.keys()
	keys.sort()
	for key in keys:			
		add_number_preset_ui(key)
	keys = presets.styleboxes.keys()
	for key in keys:			
		add_stylebox_preset_ui(key)
	keys = presets.fonts.keys()
	for key in keys:			
		add_font_preset_ui(key)	
	keys = presets.textures.keys()
	for key in keys:			
		add_texture_preset_ui(key)
