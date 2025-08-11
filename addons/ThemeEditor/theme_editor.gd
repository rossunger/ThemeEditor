@tool 
extends PanelContainer

# Preset_name aka variable_name
# type aka class (like css class)


signal theme_loaded

@onready var class_list_tree:Tree = %class_list_tree
@onready var details_tree:Tree = %details_tree
var details_tree_nodes = {}
var details_tree_prop_nodes = {}

var control_list = []
var fav_controls_list = "PanelContainer,Label,Button,Panel,CheckBox,CheckButton,TextureRect,ColorRect,NinePatchRect,HSeparator,VSeparator,ItemList,LineEdit,Tree,HSlider,VSlider,SpinBox,OptionButton,HSplitContainer,VSplitContainer".split(',')
var container_list = "HBoxContainer,VBoxContainer,ScrollContainer,HFlowContainer,VFlowContainer,MarginContainer,GridContainer,Container,AspectRatioContainer,TabContainer,BoxContainer,CenterContainer,FlowContainer,SubViewportContainer,SplitContainer".split(',')
var other_controls_list = "Range,ScrollBar,HScrollBar,VScrollBar,Slider,LinkButton,ReferenceRect,TabBar,Separator,HSeparator,VSeparator,ProgressBar,TextureProgressBar,VideoStreamPlayer,TextEdit,CodeEdit,MenuBar,MenuButton,ColorPicker,ColorPickerButton,RichTextLabel,GraphElement,GraphNode,GraphFrame,GraphEdit".split(',')
var special_controls_info = JSON.parse_string( FileAccess.get_file_as_string("res://addons/ThemeEditor/special_base_types.json"))
var special_controls_list = PackedStringArray(special_controls_info.keys()) # "Accordion,CalendarDatePicker,Pagination,SpinBoxExtra,SpinBoxButtons,OptionButtonSpinBox".split(',')

##TREE BUTTON ICONS
var close_icon = preload("icon_close.svg")
var duplicate_icon = preload("icon_duplicate.svg")
var edit_icon = preload("icon_edit.svg")

var current_theme:Theme
##DEFAULTS
var default_theme_path = "res://addons/ThemeEditor/default_theme.theme"
var default_props = JSON.parse_string( FileAccess.get_file_as_string("res://addons/ThemeEditor/base_type_properties.json"))
var extra_node_property_names = JSON.parse_string( FileAccess.get_file_as_string("res://addons/ThemeEditor/extra_node_property_names.json"))
var example_nodes = {}

var styleboxes = {}
var presets = {"colors":{}, "numbers":{}, "styleboxes":{}, "fonts":{}, "textures":{}, "classes":{}}

var preset_manager = null
var tweak_only_mode = false: 
	set(val):
		if tweak_only_mode == val: return
		tweak_only_mode = val		
		%new_theme_button.visible = not tweak_only_mode
		%add_class_button.visible = not tweak_only_mode
		if tweak_only_mode:
			var root = class_list_tree.get_root()
			if not root: return
			for item:TreeItem in class_list_tree.get_root().get_children():
				item.clear_buttons()
var confirmed_edit_default_theme = false
var debug = false

func init_presets(presets_file_path):
	styleboxes.clear()
	if not FileAccess.file_exists(presets_file_path):			
		push_error(presets_file_path, " doesn't exist. loading defaults")			
		presets_file_path = "res://addons/ThemeEditor/default_theme.theme.json"
		if not FileAccess.file_exists(presets_file_path):
			push_error("Failed loading default theme presets. Default file doesnt exist")			
			return						
	presets.clear()
	var new_presets = JSON.parse_string(FileAccess.get_file_as_string(presets_file_path))		
	for key in new_presets.keys():
		presets[key] = new_presets[key]
	for key in presets.colors.keys():			
		var color = presets.colors[key].replace("(","").replace(")","").split(",") if presets.colors[key] else null
		presets.colors[key] = Color(float(color[0]), float(color[1]), float(color[2]), float(color[3])) if color else Color(0,0,0,0)
	for key in presets.numbers.keys():			
		presets.numbers[key] = int(presets.numbers[key])
	for key in presets.styleboxes.keys():		
		if key == "default": continue
		if not presets.styleboxes[key].has("is_texture"):
			presets.styleboxes[key]["is_texture"] = false	

func init_tree_signals():
	class_list_tree.item_edited.connect(class_list_edited)
	class_list_tree.button_clicked.connect( class_list_button_clicked )
	
	class_list_tree.item_activated.connect(func():		
		if class_list_tree.get_selected_column() == 0:
			class_list_tree.edit_selected(true)
		else:
			show_change_base_type_dialog(class_list_tree.get_selected())
	)
	class_list_tree.item_selected.connect( build_details_tree )
	class_list_tree.nothing_selected.connect( details_tree.clear )	
	details_tree.item_edited.connect(detail_edited)
	
func init_examples():
	for child in %example.get_children():
		%example.remove_child(child)
		child.queue_free()
	for type in presets.classes.keys():
		var base_types = presets.classes[type].base_type		
		for base_type in base_types:
			add_item_to_example(type, base_type)		
			
func add_item_to_example(type, base_type):
	if base_type in special_controls_list: return
	if not ClassDB.can_instantiate(base_type): return		
	var node:Control = ClassDB.instantiate(base_type)
	%example.add_child(node)
	node.theme_type_variation = type + "_" +base_type
	example_nodes[type] = node
	if base_type == "Label":
		node.text = "Label: " + type
	if base_type == "Button":
		node.text = "Button: " + type

func change_theme_gui_input(event, who):
	if event is InputEventMouseButton and event.pressed:
		if current_theme and event.button_index == MOUSE_BUTTON_LEFT and who.has_meta("theme_path"):								
			save_presets_to_file()
			switch_theme(who.get_meta("theme_path"))
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if not who.button_pressed:			
				who.queue_free()			

func _ready():			
	init_tree_signals()	
	%add_class_button.pressed.connect(add_class)	
	%open_themes_hbox.set_meta("button_group", ButtonGroup.new())	
	%add_theme_button.pressed.connect(show_add_theme_dialog)	
	%new_theme_button.pressed.connect(show_new_theme_dialog)		
	%edit_presets_button.pressed.connect(show_preset_manager)	
	if debug: 
		load_theme.call_deferred(default_theme_path)
	%examples_split_container.visible = debug
	
func show_new_theme_dialog():
	var dialog := FileDialog.new()	
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.add_filter("*.theme", "theme")
	if current_theme:
		dialog.add_option("Base Theme",["Use Default","Duplicate Active"],0)	
	dialog.title = "Save New Theme"
	dialog.file_selected.connect(func(path:String):		
		if current_theme and dialog.get_selected_options()["Base Theme"] and not current_theme.resource_path.is_empty():
			var to = path.get_basename() + ".theme.json"
			if FileAccess.file_exists(to):
				DirAccess.remove_absolute(to)
			DirAccess.copy_absolute(current_theme.resource_path.get_basename()+".theme.json", to)			
		else: #otherwise, use the defaults
			DirAccess.copy_absolute(default_theme_path.get_basename()+".theme.json", path.get_basename() + ".theme.json")
		var t = Theme.new()
		ResourceSaver.save(t, path)				
		load_theme(path)
		dialog.queue_free()
	)
	add_child(dialog)
	dialog.popup_centered()


func show_add_theme_dialog():
	var dialog := FileDialog.new()	
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.add_filter("*.theme", "theme")
	
	dialog.title = "Load Theme"
	dialog.file_selected.connect(func(path:String):
		var t:Theme
		if FileAccess.file_exists(path):
			if not FileAccess.file_exists(path+".json"): 
				return
			t = load(path) 			
		else:
			t = Theme.new()
			ResourceSaver.save(t, path)		
			DirAccess.copy_absolute(default_theme_path.get_basename()+".theme.json", path.get_basename() + ".theme.json")
		load_theme(path)
		dialog.queue_free()
	)
	add_child(dialog)
	dialog.popup_centered()


func switch_theme(path:String):	
	var base = path.get_basename()	
	var new_theme = load(path) #if FileAccess.file_exists(path) else Theme.new()			
	init_presets(base + ".theme.json")		
	build_tree()	
	if debug:
		init_examples()
	change_theme(new_theme)
	theme_loaded.emit(path)
	
func load_theme(path:String):	
	if path == default_theme_path:
		if not confirmed_edit_default_theme:
			var dialog = ConfirmationDialog.new()
			dialog.dialog_text = "Are you sure you want to edit the default theme?"
			dialog.confirmed.connect(func():
				confirmed_edit_default_theme = true
				load_theme.call_deferred(path)
				dialog.queue_free()
			)		
			dialog.canceled.connect(dialog.queue_free)
			dialog.close_requested.connect(dialog.queue_free)
			add_child(dialog)	
			dialog.popup_centered.call_deferred()
			return
		else:
			confirmed_edit_default_theme = false
	var theme_name = path.get_file().get_basename()
	if %open_themes_hbox.has_node(theme_name): 
		%open_themes_hbox.get_node(theme_name).button_pressed = true
	else:
		var button = Button.new()	
		button.text = theme_name
		button.name = theme_name
		button.set_meta("theme_path", path)
		button.toggle_mode = true	
		button.button_group = %open_themes_hbox.get_meta("button_group")
		button.button_pressed = true
		button.gui_input.connect(change_theme_gui_input.bind(button))
		%open_themes_hbox.add_child(button)
	switch_theme(path)
		
func rename_preset(category, old_name, new_name):		
	presets[category][new_name] = presets[category][old_name]
	presets[category].erase(old_name)	
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
	if details_tree_prop_nodes.has(old_name):
		for prop_item:TreeItem in details_tree_prop_nodes[old_name]:						
			prop_item.set_text(1,",".join(presets[category].keys()).replace("default", " ") )			
			prop_item.set_range(1, presets[category].keys().find(new_name) )	
		details_tree_prop_nodes[new_name] = details_tree_prop_nodes[old_name]
		details_tree_prop_nodes.erase(old_name)
			#detail_edited(prop_item)
			
func show_preset_manager():
	if preset_manager:							
		preset_manager.show()
		preset_manager.load_presets()
	else:
		var preset_manager = preload("preset_manager.tscn").instantiate()
		preset_manager.presets = presets
		preset_manager.special_base_types = special_controls_list
		add_child(preset_manager)					
		preset_manager.preset_changed.connect(apply_variable_to_theme)		
		preset_manager.preset_rename_requested.connect(rename_preset)
	
func change_theme(new_theme:Theme):		
	if new_theme == current_theme: return		
	apply_all_to_theme(new_theme)
	current_theme = new_theme		
	if debug:
		%example.theme = current_theme	
	build_tree()	
	if preset_manager:
		preset_manager.load_presets()
	if Engine.is_editor_hint():
		var node = EditorInterface.get_edited_scene_root()
		if node.scene_file_path and node.scene_file_path.begins_with("res://addons/ThemeEditor/"): return
		if node is Control:
			node.theme = new_theme
	else:
		var node = get_tree().root
		set_theme_for_child_controls(node, new_theme)
			
func set_theme_for_child_controls(parent, theme):
	for child in parent.get_children():
		if child is Control:
			child.theme = theme
		else:
			set_theme_for_child_controls(child, theme)
			
			
func detail_edited(specific_item:TreeItem = null):
	var item: TreeItem = specific_item if specific_item else details_tree.get_edited()
	var col = details_tree.get_edited_column() if not specific_item else 1
	var prop = item.get_metadata(0)		
	var category = ""
	if col == 1:
		var class_item = class_list_tree.get_selected()
		var original_type = class_item.get_metadata(0)
		var i = int(item.get_range(1))
		var list 
		if "color" in prop: 
			category = "colors"
			list = presets.colors.keys()			
			if list[i] == "default":
				item.set_icon(0, null)
			else:		
				item.set_icon(0,get_color_as_image(presets.colors[ list[i] ]))			
		elif "stylebox_" in prop: 
			category = "styleboxes"
			list = presets.styleboxes.keys()
		elif "texture_" in prop: 
			category = "textures"
			list = presets.textures.keys()
			if list[i] == "default":
				item.set_icon(0, null)
			else:		
				item.set_icon(0,load(presets.textures[list[i]]))			
		elif prop == "font":
			category = "fonts"
			list = presets.fonts.keys()
		else: 
			category = "numbers"
			list = presets.numbers.keys()			
			if list[i] == "default":
				item.set_text(0, prop)
			else:		
				item.set_text(0, str(prop, " ", presets.numbers[list[i]] ))		
		item.set_tooltip_text(1, list[i])					
		var sub_type = item.get_parent().get_text(0)
		var is_special = presets.classes[original_type].has(sub_type)
		if is_special:					
			presets.classes[original_type][sub_type][prop] = list[i]			
		else:
			presets.classes[original_type][prop] = list[i]		
			var parent_item = item.get_parent()
			if list[i] != "default":
				parent_item.remove_child(item)
				details_tree_nodes["active"].add_child(item)						
			
		
		if not specific_item: # item needs updating after user changed prop value
			var extra_node_properties = {}		
			var type_list = current_theme.get_type_list()
			current_theme.set_block_signals(true)
			if is_special:				
				var base_type = presets.classes[original_type][sub_type]["base_type"][0]				
				if not sub_type in type_list:
					current_theme.add_type(sub_type)			
				if not current_theme.is_type_variation(sub_type, base_type):
					current_theme.set_type_variation(sub_type,base_type)		
				var preset_name = presets.classes[original_type][sub_type][prop]
				apply_prop_to_theme(current_theme, sub_type, prop, base_type, preset_name, extra_node_properties)				
			else:
				for base_type in presets.classes[original_type]["base_type"]:					
					var type = get_resolved_type(original_type,base_type)				
					if not type in type_list:
						current_theme.add_type(type)			
					if not current_theme.is_type_variation(type, base_type):
						current_theme.set_type_variation(type,base_type)																
					var preset_name = presets.classes[original_type][prop]
					apply_prop_to_theme(current_theme, type, prop, base_type, preset_name, extra_node_properties)									
			update_extra_node_properties(extra_node_properties)	
			current_theme.set_block_signals(false)		
			if Engine.is_editor_hint():
				EditorInterface.get_edited_scene_root().propagate_notification(NOTIFICATION_THEME_CHANGED)
			else:
				get_tree().current_scene.propagate_notification(NOTIFICATION_THEME_CHANGED)				
			save_presets_to_file()
		else: # variable got updated and needs to be reflected in the ui
			var old_preset_name = item.get_metadata(1)
			if old_preset_name == list[i]: return
			if details_tree_prop_nodes.has(old_preset_name) and details_tree_prop_nodes[old_preset_name].has(specific_item):
				details_tree_prop_nodes[old_preset_name].erase(specific_item)
				if len(details_tree_prop_nodes[old_preset_name])==0:
					details_tree_prop_nodes.erase(old_preset_name)
			if not details_tree_prop_nodes.has(list[i]):
				details_tree_prop_nodes[list[i]] = []
			details_tree_prop_nodes[list[i]].push_back(specific_item)

func process_special_type_recursive(root_key: String, current_prefix: String, special_type: String):	
	if not presets.classes.has(root_key):
		presets.classes[root_key] = {}
	# Add the base_type and default props for this component
	if not presets.classes[root_key].has(current_prefix):
		presets.classes[root_key][current_prefix] = {	"base_type": [special_type]		}
		for prop in default_props.get(special_type, []):
			presets.classes[root_key][current_prefix][prop] = "default"
	# Override base_type if special_type declares "" under another base_type
	for alt_base_type in special_controls_info.get(special_type, {}):
		var sub_types = special_controls_info[special_type][alt_base_type]
		if "" in sub_types:
			presets.classes[root_key][current_prefix]["base_type"] = [alt_base_type]
			for prop in default_props.get(alt_base_type, []):
				presets.classes[root_key][current_prefix][prop] = "default"
	# Skip if no subcontrols
	if not special_controls_info.has(special_type):
		return
	# Process children
	for base_type in special_controls_info[special_type]:		
		for sub_type in special_controls_info[special_type][base_type]:
			if sub_type == "":
				continue  # Root already handled
			var new_prefix = current_prefix + "_" + sub_type
			if base_type in special_controls_info:			
				process_special_type_recursive(root_key, new_prefix, base_type)
			else:				
				presets.classes[root_key][new_prefix] = {"base_type": [base_type]}
				for prop in default_props.get(base_type, []):
					presets.classes[root_key][new_prefix][prop] = "default"
								
func build_details_tree():
	details_tree.clear()
	details_tree_prop_nodes.clear()	
	var item = class_list_tree.get_selected()	
	if not item: return	
	var type = item.get_text(0) # class name
	var base_types = presets.classes[type].base_type	
	if len(base_types)==1 and base_types[0] in special_controls_list:
		process_special_type_recursive(type, type, presets.classes[type]["base_type"][0])
		var root := details_tree.create_item()						
		for sub_type_or_prop in presets.classes[type]:
			if sub_type_or_prop == "base_type": continue
			var base_item = root.create_child()			
			if presets.classes[type][sub_type_or_prop] is Dictionary:								
				base_item.set_text(0, sub_type_or_prop)		
				base_item.set_metadata(0, sub_type_or_prop)					
				for prop in default_props[presets.classes[type][sub_type_or_prop]["base_type"][0] ]:				
					var prop_item = base_item.create_child()						
					var preset_name = presets.classes[type][sub_type_or_prop][prop] if presets.classes[type][sub_type_or_prop].has(prop) else "default"				
					update_detail_tree_prop_item_ui(prop_item, prop, preset_name)			
		return		
	var root := details_tree.create_item()				
	var active_root = root.create_child()
	details_tree_nodes["active"] = active_root
	active_root.set_text(0, "Active")
	var available_all_root = root.create_child()
	details_tree_nodes["all"] = available_all_root
	available_all_root.set_text(0, "Available (all)")
	var available_some_root = root.create_child()
	details_tree_nodes["some"] = available_some_root
	available_some_root.set_text(0, "Available (some)")	
	var invalid_root = root.create_child()
	details_tree_nodes["invalid"] = invalid_root
	invalid_root.set_text(0, "Invalid")
	for prop in extra_node_property_names.common:		
		var prop_item := available_all_root.create_child()
		prop_item.set_text(0, prop)
		prop_item.set_metadata(0, prop)
		prop_item.set_cell_mode(1,TreeItem.CELL_MODE_RANGE)
		prop_item.set_editable(1, true)		
		prop_item.set_text(1, ",".join(presets.numbers.keys()).replace("default", " ") )			
		var preset_name = presets.classes[type][prop] if presets.classes[type].has(prop) else "default"		
		prop_item.set_range(1, presets.numbers.keys().find(preset_name.replace(" ", "default")) )				
		prop_item.set_metadata(1, preset_name)
	var available_props = []	
	var not_available_all_props = []
	var all_props = presets.classes[type].keys()		
	for base_type in base_types:			
		for prop in default_props[base_type]:
			if not prop in available_props:
				available_props.push_back(prop)
			if not prop in all_props:
				all_props.push_back(prop)		
							
	for base_type in base_types:		
		for prop in available_props:
			if prop in not_available_all_props: continue
			if base_type in special_controls_list: 
				#THIS SHOULD NEVER HAPPEN.... special types covered earlier... and you can't mix special type and base types
				push_error("Special theme type mixed with base type! this should never happen: ", base_type)
				for base_base_type in special_controls_info[base_type].keys():					
					if not prop in default_props[base_base_type]:
						not_available_all_props.push_back(prop)		
			elif not prop in default_props[base_type]:
				not_available_all_props.push_back(prop)		
	
	for prop in all_props:	
		if prop == "base_type": continue
		var preset_name = presets.classes[type][prop] if presets.classes[type].has(prop) else "default"		
		var prop_item:TreeItem
		if preset_name != "default":
			if prop in available_props:
				prop_item = active_root.create_child()
				available_props.erase(prop)
			else:
				prop_item = invalid_root.create_child()
				available_props.erase(prop)
		else:					
			if prop in available_props:
				if prop in not_available_all_props:
					prop_item = available_some_root.create_child()
				else:
					prop_item = available_all_root.create_child()
			else:
				prop_item = invalid_root.create_child()
		if not details_tree_prop_nodes.has(preset_name):
			details_tree_prop_nodes[preset_name] = []
		if not details_tree_prop_nodes.has(prop_item):
			details_tree_prop_nodes[preset_name].push_back(prop_item)
		update_detail_tree_prop_item_ui(prop_item, prop, preset_name)
	invalid_root.visible = invalid_root.get_child_count() > 0		
	available_some_root.visible = available_some_root.get_child_count() > 0		
	available_all_root.visible = available_all_root.get_child_count() > 0		
	

func update_detail_tree_prop_item_ui(prop_item, prop, preset_name):
	prop_item.set_text(0, prop)
	prop_item.set_metadata(0, prop)
	prop_item.set_cell_mode(1,TreeItem.CELL_MODE_RANGE)
	prop_item.set_editable(1, true)
	prop_item.set_metadata(1, preset_name)
	if "color" in prop:			
		prop_item.set_text(1, ",".join(presets.colors.keys()).replace("default", " "))			
		var value = presets.colors[ preset_name ]			
		if preset_name == "default":
			prop_item.set_icon(0, null)
		else:
			prop_item.set_icon(0,get_color_as_image(value))				
		prop_item.set_range(1, presets.colors.keys().find(preset_name.replace(" ", "default")) )						
	elif prop.begins_with("stylebox_"):			
		prop_item.set_text(1, ",".join(presets.styleboxes.keys()).replace("default", " "))										
		prop_item.set_range(1, presets.styleboxes.keys().find(preset_name.replace(" ", "default")) )
	elif prop == "font":						
		prop_item.set_text(1, ",".join(presets.fonts.keys()).replace("default", " "))			
		prop_item.set_range(1, presets.fonts.keys().find(preset_name.replace(" ", "default")) )			
	elif prop.begins_with("texture_"):			
		prop_item.set_text(1, ",".join(presets.textures.keys()).replace("default", " ") )										
		prop_item.set_range(1, presets.textures.keys().find(preset_name.replace(" ", "default")) )				
	else:			
		prop_item.set_text(1, ",".join(presets.numbers.keys()).replace("default", " ") )			
		prop_item.set_range(1, presets.numbers.keys().find(preset_name.replace(" ", "default")) )				

			
func add_class():
	var type = "new_class"
	if not presets.classes.has(type):
		presets.classes[type] = {"base_type": ["Button"]}		
		for key in default_props["Button"]:
			presets.classes[type][key] = "default"
		if debug:
			add_item_to_example(type, "Button")
		build_tree()

func validate_class_rename(new_class:String)->bool:
	if new_class in presets.classes.keys(): return false
	if " " in new_class: return false		
	return true

func duplicate_class(old_class, new_class, remove_old=false):
	if old_class == new_class or not presets.classes.has(old_class): return
	if not validate_class_rename(new_class): return	
	if new_class in control_list: 
		if not remove_old: return				
		presets.classes[old_class].base_type = []		
	presets.classes[new_class] = presets.classes[old_class]	
	## EXAMPLES
	if debug:
		for base_type in presets.classes[new_class].base_type:
			add_item_to_example(new_class, base_type)
		if remove_old:
			if example_nodes.has(old_class):
				example_nodes[old_class].queue_free()
	presets.classes.erase(old_class)		
	
func class_list_edited():
	var item = class_list_tree.get_edited()
	var col = class_list_tree.get_edited_column()
	if col == 0:	
		var new_class = item.get_text(0)
		var old_class = item.get_metadata(0)
		if not validate_class_rename(new_class):
			item.set_text(0, old_class)
			return		
		else:			
			duplicate_class(old_class, new_class, true)
			item.set_metadata(0, new_class)			
	#elif col == 1:	
		#var base_type = control_list[item.get_range(1)]
		#presets.classes[item.get_text(0)]["base_type"] = [base_type]
		
func class_list_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int):
	if column == 0:
		if id == 0:		
			var new_name = item.get_text(0) + "_copy"			
			duplicate_class(item.get_text(0), new_name)
			build_tree()
		if id == 1:
			presets.classes.erase(item.get_text(0))			
			build_tree()
	elif column == 1: # change base types
		show_change_base_type_dialog(item)

func show_change_base_type_dialog(item):
	var popup := Window.new()		
	var node = preload("base_type_selector.tscn").instantiate()
	node.type_list = control_list
	node.special_type_list = special_controls_list
	var type = item.get_text(0)
	node.initial_selection = presets.classes[type].base_type
	popup.add_child(node)
	add_child(popup)
	popup.popup_centered()
	popup.close_requested.connect(popup.queue_free)		
	node.confirmed.connect(func(list):
		presets.classes[type].base_type = list
		update_ui_type_base_classes(item, presets.classes[type].base_type)				
	)
	popup.wrap_controls = true		
	
func build_tree():
	class_list_tree.clear()
	details_tree.clear()
	var root = class_list_tree.create_item()	
	var list = presets.classes.keys()
	list.sort()	
	control_list = fav_controls_list + container_list + other_controls_list + special_controls_list  #base types
	for type in list:
		var tree_item := root.create_child()
		tree_item.set_text(0, type)
		tree_item.set_metadata(0, type)
		#tree_item.set_editable(0, true)
		if not tweak_only_mode:		
			tree_item.add_button(0,duplicate_icon, 0,false, "Duplicate")
			tree_item.add_button(0,close_icon, 1,false, "Remove")
			tree_item.add_button(1, edit_icon, 0, false, "edit base types")	
		if type in control_list: 
			tree_item.set_tooltip_text(1, "class is a base type, can't inherit")
			continue		
		update_ui_type_base_classes(tree_item, presets.classes[type].base_type)
		

func update_ui_type_base_classes(tree_item, list):
	var text = ", ".join(list) if len(list)>0 else ""
	tree_item.set_text(1, text)	
	tree_item.set_tooltip_text(1, text)

func apply_variable_to_theme(category, preset_name):		
	current_theme.set_block_signals(true)
	var extra_node_properties = {}
	for type in presets.classes.keys():				
		for prop_or_subtype in presets.classes[type].keys():				
			if prop_or_subtype == "base_type": continue
			if len(presets.classes[type].base_type)==1 and presets.classes[type].base_type[0] in special_controls_list:				
				var sub_type = prop_or_subtype				
				for prop in presets.classes[type][sub_type]:														
					if prop == "base_type": continue
					if prop == "is_texture": continue					
					if presets.classes[type][sub_type][prop] == preset_name:					
						var base_type = presets.classes[type][sub_type].base_type[0]						
						apply_prop_to_theme(current_theme, sub_type, prop, base_type, preset_name, extra_node_properties)	
						if not details_tree_prop_nodes.has(preset_name): continue
						for prop_item in details_tree_prop_nodes[preset_name]:
							detail_edited(prop_item)					
			else:							
				var prop = prop_or_subtype
				if prop == "base_type": continue
				if prop == "is_texture": continue				
				if presets.classes[type][prop] == preset_name:					
					for base_type in presets.classes[type].base_type:						
						apply_prop_to_theme(current_theme, get_resolved_type(type, base_type), prop, base_type, preset_name, extra_node_properties)	
						if not details_tree_prop_nodes.has(preset_name): continue
						for prop_item in details_tree_prop_nodes[preset_name]:
							detail_edited(prop_item)								
	var styleboxes_to_update = []
	for stylebox in presets.styleboxes.keys():
		if stylebox == "default": continue
		for prop in presets.styleboxes[stylebox].keys():
			if prop == "is_texture": continue
			if presets.styleboxes[stylebox][prop] == preset_name:
				if not stylebox in styleboxes_to_update:
					styleboxes_to_update.push_back(stylebox)
					break
	for stylebox in styleboxes_to_update:
		update_stylebox(stylebox)
	
	update_extra_node_properties(extra_node_properties)
	save_presets_to_file()			
	current_theme.set_block_signals(false)			
	if Engine.is_editor_hint():
		EditorInterface.get_edited_scene_root().propagate_notification(NOTIFICATION_THEME_CHANGED)
	else:
		get_tree().current_scene.propagate_notification(NOTIFICATION_THEME_CHANGED)
						
func apply_prop_to_theme(the_theme: Theme, type:String, prop:String, base_type:String, preset_name:String, extra_node_properties:Dictionary={}):
	if prop == "base_type":return	
	if prop == "is_texture": return
	if prop in extra_node_property_names.common:					
		if not extra_node_properties.has(type):
			extra_node_properties[type] = []
		if not prop in extra_node_properties[type]: 								
			extra_node_properties[type].push_back(prop)							
		return	
	if extra_node_property_names.has(base_type) and prop in extra_node_property_names[base_type]: 
		if not extra_node_properties.has(type):
			extra_node_properties[type] = []
		if not prop in extra_node_properties[type]: 								
			extra_node_properties[type].push_back(prop)									
		return
	if "color" in prop:										
		if preset_name == "default":				
			if the_theme.has_color(prop,type):
				the_theme.clear_color(prop, type)
		else:
			var value = presets.colors[ preset_name ]			
			the_theme.set_color(prop, type, value)			
	elif "stylebox_" in prop:		
		if preset_name == "default":	
			if the_theme.has_stylebox(prop,type):
				the_theme.clear_stylebox(prop, type)
		else:							
			if presets.styleboxes[preset_name].is_texture:
				if not styleboxes.has(preset_name) or not styleboxes[preset_name] is StyleBoxTexture:				
					styleboxes[preset_name] = StyleBoxTexture.new()									
			else:
				if not styleboxes.has(preset_name) or not styleboxes[preset_name] is StyleBoxFlat:								
					styleboxes[preset_name] = StyleBoxFlat.new()									
			update_stylebox(preset_name)																	
			the_theme.set_stylebox(prop.trim_prefix("stylebox_"), type, styleboxes[preset_name])
		return
	elif prop == "font":		
		if preset_name == "default":
			var df = the_theme.default_font
			the_theme.default_font = null	
			if the_theme.has_font(prop,type):
				the_theme.clear_font(prop, type)					
			the_theme.default_font = df
		else:
			var path = presets.fonts[ preset_name ]				
			if path and FileAccess.file_exists(path):						
				the_theme.set_font(prop, type, load(path))
	elif "texture_" in prop:
		if preset_name == "default":		
			if the_theme.has_icon(prop,type):
				the_theme.clear_icon(prop, type)
		else:
			var value = presets.textures[ preset_name ]	
			the_theme.set_icon(prop, type, load(value))		
	#ELSE NUMBER
	elif "font_size" in prop:									
		if preset_name == "default":
			var df = the_theme.default_font_size
			the_theme.default_font_size = 0		
			if the_theme.has_font_size(prop,type):
				the_theme.clear_font_size(prop, type)					
			the_theme.default_font_size = df
		else:				
			var value = presets.numbers[ preset_name ]		
			the_theme.set_font_size(prop, type, int(value))		
	else:	
		if preset_name == "default":															
			if the_theme.has_constant(prop,type):
					the_theme.clear_constant(prop, type)						
		else:
			var value = presets.numbers[ preset_name ]			
			the_theme.set_constant(prop, type, value)
		

func get_resolved_type(type:String,base_type:String)->String:
	if base_type.is_empty(): return type
	if type.is_empty(): return base_type
	return type +"_"+base_type
	
func apply_all_to_theme(the_theme = current_theme):			
	var type_list = the_theme.get_type_list() 
	var extra_node_properties = {}
	the_theme.set_block_signals(true)
	for original_type in presets.classes.keys():		
		for sub_type in presets.classes[original_type].keys():
			if presets.classes[original_type][sub_type] is Dictionary: 				
				var base_type = presets.classes[original_type][sub_type]["base_type"][0]				
				if not sub_type in type_list:
					the_theme.add_type(sub_type)				
				else:
					type_list.remove_at(type_list.find(sub_type))		
				if not the_theme.is_type_variation(sub_type, base_type):
					the_theme.set_type_variation(sub_type,base_type)
				for prop in presets.classes[original_type][sub_type].keys():		
					if prop == "base_type":continue
					var preset_name = presets.classes[original_type][sub_type][prop]
					apply_prop_to_theme(the_theme, sub_type, prop, base_type, preset_name, {})				
			else:		
				if sub_type == "base_type":continue							
				for base_type in presets.classes[original_type]["base_type"]:									
					var type = get_resolved_type(original_type,base_type)				
					if not type in type_list:
						the_theme.add_type(type)
					else:						
						type_list.remove_at(type_list.find(type))				
					if not the_theme.is_type_variation(type, base_type):
						the_theme.set_type_variation(type,base_type)											
					for prop in presets.classes[original_type].keys():					
						if prop == "base_type": continue					
						var preset_name = presets.classes[original_type][prop]		
						if preset_name is Dictionary:
							print(original_type, prop)									
						apply_prop_to_theme(the_theme, type, prop, base_type, preset_name, extra_node_properties)				
	for type in type_list:
		the_theme.remove_type(type)
	the_theme.set_block_signals(false)		
	if Engine.is_editor_hint():
		#save_presets_to_file()		
		EditorInterface.get_edited_scene_root().propagate_notification(NOTIFICATION_THEME_CHANGED)
	else:	
		get_tree().current_scene.propagate_notification(NOTIFICATION_THEME_CHANGED)
	
	
	update_extra_node_properties(extra_node_properties)
	
func update_extra_node_properties(extra_node_properties):
	var root = EditorInterface.get_edited_scene_root() if Engine.is_editor_hint() else get_tree().root	
	if not root: return
	var types = extra_node_properties.keys()		
	for node:Control in root.find_children("*", "Control"):		
		var type = node.theme_type_variation.trim_suffix("_"+node.get_class())
		if type.is_empty() or not type in types: continue									
		for key in extra_node_properties[type]:									
			if key == "min_size_x":								
				node.custom_minimum_size.x = presets.numbers[presets.classes[type][key]]
			elif key == "min_size_y":
				node.custom_minimum_size.y = presets.numbers[presets.classes[type][key]]
			elif key == "expand_x":
				node.size_flags_horizontal = node.size_flags_horizontal | Control.SIZE_EXPAND if presets.numbers[presets.classes[type][key]] else node.size_flags_horizontal & ~Control.SIZE_EXPAND
			elif key == "expand_y":
				node.size_flags_vertical = node.size_flags_vertical | Control.SIZE_EXPAND if presets.numbers[presets.classes[type][key]] else node.size_flags_vertical & ~Control.SIZE_EXPAND
			elif key == "text_align_x":				
				node.horizontal_alignment = clamp(presets.numbers[presets.classes[type][key]], 0, 3)
			elif key == "text_align_y":
				node.vertical_alignment = clamp(presets.numbers[presets.classes[type][key]], 0, 3)
			elif key == "autowrap":
				node.autowrap_mode = clamp(presets.numbers[presets.classes[type][key]], 0, 3)
			elif key == "uppercase":
				node.uppercase = true if presets.numbers[presets.classes[type][key]] else false						
			elif key in ["align_x","align_y"]:
				node.alignment = presets.numbers[presets.classes[type][key]]
			elif key in ["last_wrap_align_x", "last_wrap_align_y"]:
				node.last_wrap_alignment = presets.numbers[presets.classes[type][key]]
			elif key == "max_columns":
				node.max_columns = presets.numbers[presets.classes[type][key]]
			elif key == "color":
				node.color = presets.colors[presets.classes[type][key]]
			#elif 
			#"TextureProgressBar": ["texture_under", "texture_over", "texture_progress", "tint_under", "tint_over", "tint_progress"],		
			#"TextEdit": ["wrap_mode", "fit_y", "fit_x"],
			#"TextureButton": ["texture_normal","texture_pressed","texture_hover","texture_disabled","texture_focused","texture_click_mask", "stretch_mode" ],
				
func save_presets_to_file(presets_file_path:String = current_theme.resource_path.get_basename() +".theme.json" if current_theme and current_theme.resource_path else ""):		
	if not presets_file_path.is_empty() and FileAccess.file_exists(presets_file_path):		
		var file: = FileAccess.open(presets_file_path,FileAccess.WRITE)
		file.store_string(JSON.stringify(presets))
		file.close()			

func _exit_tree() -> void:
	if current_theme and not Engine.is_editor_hint():		
		save_presets_to_file()
		ResourceSaver.save(current_theme)

func get_color_as_image(color:Color):
	var img = Image.create(16,16,false,Image.FORMAT_RGBA8)
	img.fill(color)	
	return ImageTexture.create_from_image( img )

func update_stylebox(stylebox_preset_name):		
	const default_stylebox_color = Color.DARK_GRAY
	if presets.styleboxes[stylebox_preset_name].is_texture:
		var s:StyleBoxTexture = styleboxes[stylebox_preset_name]
		var data = presets.styleboxes[stylebox_preset_name]
		var path = presets.textures[data.texture_texture]
		s.texture = null if data.texture_texture == "default" else load(path) if FileAccess.file_exists(path) else null
		s.modulate_color = default_stylebox_color if data.texture_modulate == "default" else presets.colors[data.texture_modulate]		
		s.draw_center = true if data.texture_draw_center == "default" else true if presets.numbers[data.texture_draw_center] != 0 else false
		
		s.texture_margin_left = 0 if data.texture_left == "default" else presets.numbers[data.texture_left]
		s.texture_margin_top = 0 if data.texture_top == "default" else presets.numbers[data.texture_top]
		s.texture_margin_right = 0 if data.texture_right == "default" else presets.numbers[data.texture_right]
		s.texture_margin_bottom = 0 if data.texture_bottom == "default" else presets.numbers[data.texture_bottom]
		
		s.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH if data.texture_tile_x == "default" else min(2, presets.numbers[data.texture_tile_x])
		s.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH if data.texture_tile_y == "default" else min(2, presets.numbers[data.texture_tile_x])		

		s.content_margin_left = 0 if data.margins_left == "default" else presets.numbers[data.margins_left]
		s.content_margin_top = 0 if data.margins_top == "default" else presets.numbers[data.margins_top]
		s.content_margin_right = 0 if data.margins_right == "default" else presets.numbers[data.margins_right]
		s.content_margin_bottom = 0 if data.margins_bottom == "default" else presets.numbers[data.margins_bottom]		
	else:
		var s:StyleBoxFlat = styleboxes[stylebox_preset_name]
		var data = presets.styleboxes[stylebox_preset_name]
		s.bg_color = default_stylebox_color if data.background_color == "default" else presets.colors[data.background_color]		
		s.skew.x = 0 if data.background_skew_x == "default" else presets.numbers[data.background_skew_x]	
		s.skew.y = 0 if data.background_skew_y == "default" else presets.numbers[data.background_skew_y]	
		s.draw_center = true if data.background_enabled == "default" else true if presets.numbers[data.background_enabled] != 0 else false
		
		s.border_color = Color() if data.border_color == "default" else presets.colors[data.border_color]
		s.border_width_left = 0 if data.border_left == "default" else presets.numbers[data.border_left]	
		s.border_width_top = 0 if data.border_top == "default" else presets.numbers[data.border_top]	
		s.border_width_right = 0 if data.border_right == "default" else presets.numbers[data.border_top]	
		s.border_width_bottom = 0 if data.border_bottom == "default" else presets.numbers[data.border_top]	
		s.border_blend = false if data.border_bottom == "default" else true if presets.numbers[data.border_blend] != 0 else false
		
		s.corner_radius_top_left = 8 if data.corners_top_left == "default" else presets.numbers[data.corners_top_left]
		s.corner_radius_top_right = 8 if data.corners_top_right == "default" else presets.numbers[data.corners_top_right]
		s.corner_radius_bottom_right = 8 if data.corners_bottom_right == "default" else presets.numbers[data.corners_bottom_right]
		s.corner_radius_bottom_left = 8 if data.corners_bottom_left == "default" else presets.numbers[data.corners_bottom_left]		
		s.corner_detail = 8 if data.corners_detail == "default" else presets.numbers[data.corners_detail]
		
		s.content_margin_left = 0 if data.margins_left == "default" else presets.numbers[data.margins_left]
		s.content_margin_top = 0 if data.margins_top == "default" else presets.numbers[data.margins_top]
		s.content_margin_right = 0 if data.margins_right == "default" else presets.numbers[data.margins_right]
		s.content_margin_bottom = 0 if data.margins_bottom == "default" else presets.numbers[data.margins_bottom]
		
		s.shadow_color = Color(0,0,0,0.5) if data.shadow_color == "default" else presets.colors[data.shadow_color]
		s.shadow_size = 0 if data.shadow_size == "default" else presets.numbers[data.shadow_size]
		s.shadow_offset.x = 0 if data.shadow_offset_x == "default" else presets.numbers[data.shadow_offset_x]
		s.shadow_offset.y = 0 if data.shadow_offset_y == "default" else presets.numbers[data.shadow_offset_y]	
