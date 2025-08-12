@tool 
extends PanelContainer
signal preset_changed
signal preset_rename_requested
var presets = {}
var special_base_types = []
var tweak_mode_only = false

func _ready():	
	if Engine.is_editor_hint():		
		%close_button.visible = false
		if EditorInterface.get_edited_scene_root() == self or EditorInterface.get_edited_scene_root().is_ancestor_of(self):						
			return		
	else:
		if get_parent() == get_tree().root: 
			push_error("trying to run preset manager as a scene: it should be child of theme editor, or managed by editor plugin")
			get_tree().quit() 
			return
		%close_button.visible = false #true
		%close_button.pressed.connect(hide)
	load_presets()
	if not tweak_mode_only:
		%add_number_preset_button.pressed.connect(add_number_preset)
		%add_color_preset_button.pressed.connect(add_color_preset)
		%add_stylebox_preset_button.pressed.connect(add_stylebox_preset)
		%add_font_preset_button.pressed.connect(add_font_preset)
		%add_textures_preset_button.pressed.connect(add_texture_preset)
	else:
		%add_number_preset_button.visible = false
		%add_color_preset_button.visible = false
		%add_stylebox_preset_button.visible = false
		%add_font_preset_button.visible = false
		%add_textures_preset_button.visible = false
		
	%colors_search.text_changed.connect(do_search.bind("colors"))	
	%fonts_search.text_changed.connect(do_search.bind("fonts"))
	%numbers_search.text_changed.connect(do_search.bind("numbers"))
	%styleboxes_search.text_changed.connect(do_search.bind("styleboxes"))
	%textures_search.text_changed.connect(do_search.bind("presets"))

func do_search(text, category):
	if category == "colors":
		for child in %color_preset_list.get_children():
			child.visible = child.preset_name.containsn(text) or text.is_empty()
	elif category == "fonts":
		for child in %font_preset_list.get_children():
			child.visible = child.preset_name.containsn(text) or text.is_empty()
	elif category == "numbers":
		for child in %number_preset_list.get_children():
			child.visible = child.preset_name.containsn(text) or text.is_empty()
	if category == "styleboxes":
		for child in %stylebox_preset_list.get_children():
			child.visible = child.preset_name.containsn(text) or text.is_empty()
	if category == "presets":
		for child in %textures_preset_list.get_children():
			child.visible = child.preset_name.containsn(text) or text.is_empty()
			
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
	node.tweak_mode_only = tweak_mode_only
	%number_preset_list.add_child(node)
	node.value_changed.connect(func(new_value):
		presets.numbers[node.preset_name] = new_value
		preset_changed.emit("numbers", node.preset_name)
	)
	if not tweak_mode_only:
		node.rename_requested.connect(rename_preset.bind("numbers", node))	
		node.remove_requested.connect(remove_preset.bind("numbers", node))
	
	
func add_color_preset_ui(key):	
	if key == "default": return	
	var node = preload("color_preset_picker.tscn").instantiate()
	node.preset_name = key
	node.preset_color = presets.colors[key]
	node.tweak_mode_only = tweak_mode_only
	%color_preset_list.add_child(node)
	node.color_changed.connect(func(new_color):
		presets.colors[node.preset_name] = new_color
		preset_changed.emit("colors", node.preset_name)
	)
	if not tweak_mode_only:
		node.rename_requested.connect(rename_preset.bind("colors", node))	
		node.remove_requested.connect(remove_preset.bind("colors", node))
	
		
func add_stylebox_preset_ui(key):
	if key == "default": return
	var node = preload("stylebox_preset_editor.tscn").instantiate()
	node.presets = presets
	node.preset_name = key
	node.tweak_mode_only = tweak_mode_only
	node.is_texture = presets.styleboxes[key].is_texture
	%stylebox_preset_list.add_child(node)		
	node.stylebox_changed.connect(func(): 
		preset_changed.emit("styleboxes", node.preset_name)
	)
	if not tweak_mode_only:
		node.rename_requested.connect(rename_preset.bind("styleboxes", node))	
		node.remove_requested.connect(remove_preset.bind("styleboxes", node))
		node.stylebox_duplicated.connect(add_stylebox_preset_ui)
	
	
func add_font_preset_ui(key):
	if key == "default": return
	var node = preload("font_preset_editor.tscn").instantiate()	
	node.preset_name = key
	node.initial_font_path = presets.fonts[key]			
	node.tweak_mode_only = tweak_mode_only
	%font_preset_list.add_child(node)	
	node.font_changed.connect(func(preset, path):
		presets.fonts[preset] = path
		preset_changed.emit("fonts", node.preset_name)
	)
	if not tweak_mode_only:
		node.font_duplicated.connect(func(new_name, old_name):
			presets.fonts[new_name] = presets.fonts[old_name].duplicate(true)
			add_font_preset_ui(new_name)
		)
		node.rename_requested.connect(rename_preset.bind("fonts", node))	
		node.remove_requested.connect(remove_preset.bind("fonts", node))

func add_texture_preset_ui(key):
	if key == "default": return
	var node = preload("texture_preset_editor.tscn").instantiate()	
	node.preset_name = key
	node.initial_texture_path = presets.textures[key]			
	node.tweak_mode_only = tweak_mode_only
	%textures_preset_list.add_child(node)		
	node.texture_changed.connect(func(preset, path):
		presets.textures[preset] = path
		preset_changed.emit("textures", node.preset_name)
	)
	if not tweak_mode_only:
		node.texture_duplicated.connect(func(new_name, old_name):
			presets.textures[new_name] = presets.textures[old_name].duplicate(true)
			add_texture_preset_ui(new_name)
		)
		node.rename_requested.connect(rename_preset.bind("textures", node))	
		node.remove_requested.connect(remove_preset.bind("textures", node))	
	
func rename_preset(new_name, category, node):			
	if " " in new_name or new_name in presets[category].keys(): 			
		node.reset_name()		
	else:				
		if node.preset_name == new_name: return		
		preset_rename_requested.emit(category, node.preset_name, new_name)
		node.preset_name = new_name
		load_presets()
		
func remove_preset(preset_name, category, node):
	var dictionary_parent = presets[category]
	var dialog := ConfirmationDialog.new()
	var users = []	
	for type in presets.classes.keys():		
		var is_special = len(presets.classes[type].base_type)==1 and presets.classes[type].base_type[0] in special_base_types
		if is_special:
			for sub_type in presets.classes[type].keys():
				if sub_type == "base_type":continue
				for prop in presets.classes[type][sub_type].keys():
					var value = presets.classes[type][sub_type][prop]			
					if typeof(value) == TYPE_STRING and preset_name == value:
						users.push_back([type,sub_type, prop])
		else:
			for prop in presets.classes[type].keys():
				var value = presets.classes[type][prop]			
				if typeof(value) == TYPE_STRING and preset_name == value:
					users.push_back([type,prop])
	dialog.dialog_text = "Are you sure you want to delete %s? current users: %s" % [preset_name, len(users) ]
	dialog.confirmed.connect(func():
		for user in users:				
			if len(user) == 3:
				presets.classes[user[0]][user[1]][user[2]] = "default"				
			else:
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
	var keys: Array = presets.colors.keys()
	keys.sort()
	for key in keys:			
		add_color_preset_ui(key)
	keys = presets.numbers.keys()
	keys.sort()
	for key in keys:			
		add_number_preset_ui(key)
	keys = presets.styleboxes.keys()
	keys.sort()
	for key in keys:			
		add_stylebox_preset_ui(key)
	keys = presets.fonts.keys()
	keys.sort()
	for key in keys:			
		add_font_preset_ui(key)	
	keys = presets.textures.keys()
	keys.sort()
	for key in keys:			
		add_texture_preset_ui(key)
	#if _theme_path != null:
		#%Accordion.recalculate.call_deferred()
