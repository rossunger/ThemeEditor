@tool 
extends PanelContainer

signal theme_loaded

@onready var class_list_tree:Tree = %class_list_tree
@onready var details_tree:Tree = %details_tree
var details_tree_nodes = {}
var details_tree_prop_nodes = {}

var control_list = []
var fav_controls_list = "PanelContainer,Label,Button,Panel,CheckBox,CheckButton,TextureRect,ColorRect,NinePatchRect,HSeparator,VSeparator,ItemList,LineEdit,Tree,HSlider,VSlider,SpinBox,OptionButton,HSplitContainer,VSplitContainer".split(',')
var container_list = "HBoxContainer,VBoxContainer,ScrollContainer,HFlowContainer,VFlowContainer,MarginContainer,GridContainer,Container,AspectRatioContainer,TabContainer,BoxContainer,CenterContainer,FlowContainer,SubViewportContainer,SplitContainer".split(',')
var other_controls_list = "Range,ScrollBar,HScrollBar,VScrollBar,Slider,LinkButton,ReferenceRect,TabBar,Separator,HSeparator,VSeparator,ProgressBar,TextureProgressBar,VideoStreamPlayer,TextEdit,CodeEdit,MenuBar,MenuButton,ColorPicker,ColorPickerButton,RichTextLabel,GraphElement,GraphNode,GraphFrame,GraphEdit".split(',')

##TREE BUTTON ICONS
var close_icon = preload("icon_close.svg")
var duplicate_icon = preload("icon_duplicate.svg")
var edit_icon = preload("icon_edit.svg")

var current_theme:Theme
##DEFAULTS
var default_theme_path = "res://addons/ThemeEditor/default_theme.theme"
var default_props = JSON.parse_string( FileAccess.get_file_as_string("res://addons/ThemeEditor/base_type_properties.json"))
var extra_node_property_names = ["min_x", "min_y", "expand_x", "expand_y"]
var example_nodes = {}

var styleboxes = {}
var presets = {"colors":{}, "numbers":{}, "styleboxes":{}, "fonts":{}, "textures":{}, "classes":{}}
var default_presets ={
	"colors":{
		"default": "",
		"primary_color": Color.MEDIUM_PURPLE,
		"secondary_color": Color.DARK_SLATE_GRAY,
		"accent_color": Color.GOLD,
		"bg_color": Color.LIGHT_BLUE,		
		"bg_dark_color": Color(0.1,0.1,0.1,1.0),		
		"font_color": Color.MEDIUM_ORCHID,		
	},
	"numbers":{
		"default": "",
		"corners_rounded": 10,
		"corners_sharp": 10,
		"border_width": 1,
		"shadow_size": 1,
		"shadow_offset": 1,
		"font_max": 100,
		"font_large": 80,
		"font_medium": 50,
		"font_small": 32,
		"font_tiny": 16,
		"separation": 8,		
		"margin": 4,
	},
	"fonts":{
		"default": "",
		"title": null,
		"subtitle": null,
		"paragraph": null,		
	},
	"styleboxes":{
		"default": "",
		"panel_bg_light":{
			"background_color": "bg_color",
			"background_enabled": "ONE",
			"background_skew_x": "ZERO",
			"background_skew_y": "ZERO",
			"border_blend": "default",
			"border_bottom": "default",
			"border_color": "default",
			"border_left": "default",
			"border_right": "default",
			"border_top": "default",
			"corners_bottom_left": "default",
			"corners_bottom_right": "default",
			"corners_detail": "default",
			"corners_top_left": "default",
			"corners_top_right": "default",
			"margins_bottom": "margin",
			"margins_left": "margin",
			"margins_right": "margin",
			"margins_top": "margin",
			"shadow_color": "shadow_color",
			"shadow_offset_x": "ZERO",
			"shadow_offset_y": "shadow_offset_small",
			"shadow_size": "shadow_size_small"
		},
		"panel_bg_dark":{
			"background_color": "bg_dark_color",
			"background_enabled": "ONE",
			"background_skew_x": "ZERO",
			"background_skew_y": "ZERO",
			"border_blend": "default",
			"border_bottom": "default",
			"border_color": "default",
			"border_left": "default",
			"border_right": "default",
			"border_top": "default",
			"corners_bottom_left": "default",
			"corners_bottom_right": "default",
			"corners_detail": "default",
			"corners_top_left": "default",
			"corners_top_right": "default",
			"margins_bottom": "margin",
			"margins_left": "margin",
			"margins_right": "margin",
			"margins_top": "margin",
			"shadow_color": "shadow_color",
			"shadow_offset_x": "ZERO",
			"shadow_offset_y": "shadow_offset_small",
			"shadow_size": "shadow_size_small"
		}
	},
	"textures":{
		"default": "",
	},
	"classes":{
		"h1":{	
			"base_type": ["Label"],
			"font_color": "primary_color",
			"font_size": "font_large",
			"font_outline_color":"default", 
			"font_shadow_color":"default", 
			"line_spacing":"default", 
			"outline_size":"default", 
			"shadow_offset_x":"default",
			"shadow_offset_y":"default", 
			"shadow_outline_size":"default", 			
			"font":"default", 
			"stylebox_normal":"default"
		},
		"h2":{	
			"base_type": ["Label"],
			"font_color": "accent_color",
			"font_size": "font_medium",
			"font_outline_color":"default", 
			"font_shadow_color":"default", 
			"line_spacing":"default", 
			"outline_size":"default", 
			"shadow_offset_x":"default",
			"shadow_offset_y":"default", 
			"shadow_outline_size":"default", 			
			"font":"default", 
			"stylebox_normal":"default"
		},
		"h3":{	
			"base_type": ["Label"],
			"font_color": "secondary_color",
			"font_size": "font_small",
			"font_outline_color":"default", 
			"font_shadow_color":"default", 
			"line_spacing":"default", 
			"outline_size":"default", 
			"shadow_offset_x":"default",
			"shadow_offset_y":"default", 
			"shadow_outline_size":"default", 			
			"font":"default", 
			"stylebox_normal":"default"
		},
		"p":{
			"base_type": ["Label"],
			"font_color": "font_color",
			"font_size": "font_small",
			"font_outline_color":"default", 
			"font_shadow_color":"default", 
			"line_spacing":"default", 
			"outline_size":"default", 
			"shadow_offset_x":"default",
			"shadow_offset_y":"default", 
			"shadow_outline_size":"default", 			
			"font":"paragraph", 
			"stylebox_normal":"default"
		},
		"div":{
			"panel": "panel_bg_light"
		},
		"div2":{
			"panel": "panel_bg_dark"
		}
	}
	
}

var preset_manager = null

var debug = false

func init_presets(presets_file_path):
	styleboxes.clear()
	if FileAccess.file_exists(presets_file_path):		
		presets.clear()
		var new_presets = JSON.parse_string(FileAccess.get_file_as_string(presets_file_path))		
		for key in new_presets.keys():
			presets[key] = new_presets[key]
		for key in presets.colors.keys():			
			var color = presets.colors[key].replace("(","").replace(")","").split(",") if presets.colors[key] else null
			presets.colors[key] = Color(float(color[0]), float(color[1]), float(color[2]), float(color[3])) if color else Color(0,0,0,0)
		for key in presets.numbers.keys():			
			presets.numbers[key] = int(presets.numbers[key])
	else:
		presets = default_presets.duplicate(true)
		save_presets_to_file(presets_file_path)

func init_tree_signals():
	class_list_tree.item_edited.connect(class_list_edited)
	class_list_tree.button_clicked.connect( class_list_button_clicked )
	
	class_list_tree.item_activated.connect(	class_list_tree.edit_selected.bind(true))
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
			save_presets_to_file(current_theme.resource_path.get_basename() +".theme.json")
			switch_theme(who.get_meta("theme_path"))
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if not who.button_pressed:			
				who.queue_free()
			#show_change_theme_dialog(who)

func _ready():			
	init_tree_signals()	
	%add_class_button.pressed.connect(add_class)	
	%open_themes_hbox.set_meta("button_group", ButtonGroup.new())	
	%add_theme_button.pressed.connect(show_add_theme_dialog)	
	%new_theme_button.pressed.connect(show_new_theme_dialog)		
	%edit_presets_button.pressed.connect(show_preset_manager)	
	if debug: load_theme.call_deferred(default_theme_path)

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
	init_examples()
	change_theme(new_theme)
	theme_loaded.emit(path)
	
func load_theme(path:String):		
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
		
	
func show_preset_manager():
	if Engine.is_editor_hint():
		#Editor Plugin will connect the preset_manager.presets_changed signals
		preset_manager.show()
		preset_manager.load_presets()
	else:
		var preset_manager = preload("preset_manager.tscn").instantiate()
		preset_manager.presets = presets
		add_child(preset_manager)					
		preset_manager.presets_changed.connect(apply_variable_to_theme)		
	
func change_theme(new_theme:Theme):		
	current_theme = new_theme		
	apply_all_to_theme()
	%example.theme = current_theme	
	build_tree()	
	if Engine.is_editor_hint():
		var node = EditorInterface.get_edited_scene_root()
		if node is Control:
			node.theme = new_theme
			
func detail_edited(specific_item:TreeItem = null):
	var item = specific_item if specific_item else details_tree.get_edited()
	var col = details_tree.get_edited_column() if not specific_item else 1
	var prop = item.get_metadata(0)		
	var category = ""
	if col == 1:
		var class_item = class_list_tree.get_selected()
		var type = class_item.get_metadata(0)
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
		var parent_item = item.get_parent()
		if list[i] != "default":
			parent_item.remove_child(item)
			details_tree_nodes["active"].add_child(item)
		else:			
			pass #move to all, some, or invalid
		presets.classes[type][prop] = list[i]		
		if not specific_item:
			apply_prop_to_theme(type, prop)
		else:
			var old_preset_name = item.get_metadata(1)	
			if old_preset_name == list[i]: return
			if details_tree_prop_nodes.has(old_preset_name) and details_tree_prop_nodes[old_preset_name].has(prop):
				details_tree_prop_nodes[old_preset_name].erase(prop)
				if len(details_tree_prop_nodes[old_preset_name])==0:
					details_tree_prop_nodes.erase(old_preset_name)
			if not details_tree_prop_nodes.has(list[i]):
				details_tree_prop_nodes[list[i]] = []
			details_tree_prop_nodes[list[i]].push_back(specific_item)

func build_details_tree():
	details_tree.clear()
	details_tree_prop_nodes.clear()	
	var item = class_list_tree.get_selected()	
	if not item: return	
	var type = item.get_text(0) # class name
	var root := details_tree.create_item()	
	var common_root = root.create_child()
	details_tree_nodes["common"] = common_root
	common_root.set_text(0, "Sizing")	
	for prop in extra_node_property_names:		
		var prop_item := common_root.create_child()
		prop_item.set_text(0, prop)
		prop_item.set_metadata(0, prop)
		prop_item.set_cell_mode(1,TreeItem.CELL_MODE_RANGE)
		prop_item.set_editable(1, true)		
		prop_item.set_text(1, ",".join(presets.numbers.keys()).replace("default", " ") )			
		var preset_name = presets.classes[type][prop] if presets.classes[type].has(prop) else "default"		
		prop_item.set_range(1, presets.numbers.keys().find(preset_name.replace(" ", "default")) )				
		prop_item.set_metadata(1, preset_name)
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
		
	var available_props = []	
	var not_available_all_props = []
	var all_props = presets.classes[type].keys()
	for base_type in presets.classes[type].base_type:				
		for prop in default_props[base_type]:
			if not prop in available_props:
				available_props.push_back(prop)
			if not prop in all_props:
				all_props.push_back(prop)				
	for base_type in presets.classes[type].base_type:
		for prop in available_props:
			if not prop in default_props[base_type] and not prop in not_available_all_props:
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
	invalid_root.visible = invalid_root.get_child_count() > 0		
			
func update_class_details(category:="", changed_preset=""):
	var update_all = true #category.is_empty()	
	var item = class_list_tree.get_selected()	
	if not update_all:
		if not details_tree.get_root(): return
		for group in details_tree.get_root().get_children():			
			for prop_item in group.get_children():
				if prop_item.get_metadata(1) == changed_preset:
					detail_edited(prop_item)
			
func add_class():
	var type = "new_class"
	if not presets.classes.has(type):
		presets.classes[type] = {"base_type": ["Button"]}		
		for key in default_props["Button"]:
			presets.classes[type][key] = "default"
		add_item_to_example(type, "Button")
		build_tree()

func validate_class_rename(new_class:String)->bool:
	if new_class in presets.classes.keys(): return false
	if new_class in control_list: return false
	if " " in new_class: return false
	return true

func duplicate_class(old_class, new_class, remove_old=false):
	if old_class == new_class or not presets.classes.has(old_class): return
	if not validate_class_rename(new_class): return	
	presets.classes[new_class] = presets.classes[old_class]	
	for base_type in presets.classes[new_class].base_type:
		add_item_to_example(new_class, base_type)
	if remove_old:
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
	elif col == 1:	
		var base_type = control_list[item.get_range(1)]
		presets.classes[item.get_text(0)]["base_type"] = [base_type]
		
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
		var popup := Window.new()		
		var node = preload("base_type_selector.tscn").instantiate()
		node.type_list = control_list
		var type = item.get_text(0)
		node.initial_selection = presets.classes[type].base_type
		popup.add_child(node)
		add_child(popup)
		popup.popup_centered()
		popup.close_requested.connect(popup.queue_free)		
		node.confirmed.connect(func(list):
			presets.classes[type].base_type = list
			update_ui_type_base_classes(item, presets.classes[type].base_type)
			update_class_details()			
		)
		popup.wrap_controls = true		
		
func build_tree():
	class_list_tree.clear()
	details_tree.clear()
	var root = class_list_tree.create_item()	
	var list = presets.classes.keys()
	list.sort()	
	control_list = fav_controls_list + container_list + other_controls_list  #base types
	for type in list:
		var tree_item := root.create_child()
		tree_item.set_text(0, type)
		tree_item.set_metadata(0, type)
		#tree_item.set_editable(0, true)		
		tree_item.add_button(0,duplicate_icon, 0,false, "Duplicate")
		tree_item.add_button(0,close_icon, 1,false, "Remove")
		if type in control_list: 
			tree_item.set_tooltip_text(1, "class is a base type, can't inherit")
			continue		
		update_ui_type_base_classes(tree_item, presets.classes[type].base_type)
		tree_item.add_button(1, edit_icon, 0, false, "edit base types")				

func update_ui_type_base_classes(tree_item, list):
	tree_item.set_text(1, ", ".join(list))
	tree_item.set_tooltip_text(1, "base type: " + ", ".join(list))

func apply_variable_to_theme(category, preset_name):	
	for type in presets.classes.keys():
		for prop in presets.classes[type].keys():
			if prop == "base_type": continue
			if presets.classes[type][prop] == preset_name:
				apply_prop_to_theme(type, prop)	
				if not details_tree_prop_nodes.has(preset_name): continue
				for prop_item in details_tree_prop_nodes[preset_name]:
					detail_edited(prop_item)
				

func apply_prop_to_theme(type:String, prop:String, extra_node_properties:Dictionary={}):
	if prop == "base_type":return	
	if prop in extra_node_property_names:					
		if not extra_node_properties.has(type):extra_node_properties[type] = []
		if not prop in extra_node_properties[type]: 								
			extra_node_properties[type].push_back(prop)							
	elif "color" in prop:										
		if presets.classes[type][prop] == "default":			
			for base_type in presets.classes[type].base_type:										
				if current_theme.has_color(prop,get_resolved_type(type, base_type)):
					current_theme.clear_color(prop, get_resolved_type(type, base_type))
		else:
			var value = presets.colors[ presets.classes[type][prop] ]	
			for base_type in presets.classes[type].base_type:																			
				current_theme.set_color(prop, get_resolved_type(type,base_type), value)			
	elif "stylebox_" in prop:
		if presets.classes[type][prop] == "default":
			for base_type in presets.classes[type].base_type:										
				if current_theme.has_stylebox(prop,get_resolved_type(type,base_type)):
					current_theme.clear_stylebox(prop, get_resolved_type(type,base_type))
		else:					
			var stylebox_preset_name = presets.classes[type][prop]
			if not styleboxes.has(stylebox_preset_name):
				styleboxes[stylebox_preset_name] = StyleBoxFlat.new()
			update_stylebox(stylebox_preset_name)															
			for base_type in presets.classes[type].base_type:										
				current_theme.set_stylebox(prop.trim_prefix("stylebox_"), get_resolved_type(type,base_type), styleboxes[stylebox_preset_name])
	elif prop == "font":		
		if presets.classes[type][prop] == "default":
			var df = current_theme.default_font
			current_theme.default_font = null
			for base_type in presets.classes[type].base_type:										
				if current_theme.has_font(prop,get_resolved_type(type,base_type)):
					current_theme.clear_font(prop, get_resolved_type(type,base_type))					
			current_theme.default_font = df
		else:
			var path = presets.fonts[ presets.classes[type][prop] ]				
			if path and FileAccess.file_exists(path):				
				for base_type in presets.classes[type].base_type:											
					current_theme.set_font(prop, get_resolved_type(type,base_type), load(path))
	elif "texture_" in prop:
		if presets.classes[type][prop] == "default":
			for base_type in presets.classes[type].base_type:										
				if current_theme.has_icon(prop,get_resolved_type(type,base_type)):
					current_theme.clear_icon(prop, get_resolved_type(type,base_type))
		else:
			var value = presets.textures[ presets.classes[type][prop] ]	
			for base_type in presets.classes[type].base_type:										
				current_theme.set_icon(prop, get_resolved_type(type,base_type), load(value))
	else:				
		if "font_size" in prop:									
			if presets.classes[type][prop] == "default":
				var df = current_theme.default_font_size
				current_theme.default_font_size = 0
				for base_type in presets.classes[type].base_type:											
					if current_theme.has_font_size(prop,get_resolved_type(type,base_type)):
						current_theme.clear_font_size(prop, get_resolved_type(type,base_type))					
				current_theme.default_font_size = df
			else:				
				var value = presets.numbers[ presets.classes[type][prop] ]	
				for base_type in presets.classes[type].base_type:											
					current_theme.set_font_size(prop, get_resolved_type(type,base_type), int(value))
		else:	
			if presets.classes[type][prop] == "default":
				for base_type in presets.classes[type].base_type:											
					if current_theme.has_constant(prop,get_resolved_type(type,base_type)):
						current_theme.clear_constant(prop, get_resolved_type(type,base_type))						
			else:
				var value = presets.numbers[ presets.classes[type][prop] ]	
				for base_type in presets.classes[type].base_type:											
					current_theme.set_constant(prop, get_resolved_type(type,base_type), value)

func get_resolved_type(type,base_type):
	return type +"_"+base_type	
	
func apply_all_to_theme():		
	current_theme.clear()
	var extra_node_properties = {}
	for original_type in presets.classes.keys():
		for base_type in presets.classes[original_type]["base_type"]:			
			var type = original_type+"_"+base_type
			current_theme.add_type(type)
			current_theme.set_type_variation(type,base_type)				
			for prop in presets.classes[original_type].keys():			
				apply_prop_to_theme(original_type, prop, extra_node_properties)				
	if Engine.is_editor_hint():
		var presets_file_path = current_theme.resource_path.get_basename() +".theme.json"
		var file: = FileAccess.open(presets_file_path,FileAccess.WRITE)
		file.store_string(JSON.stringify(presets))
		file.close()			
	update_extra_node_properties(extra_node_properties)

func update_extra_node_properties(extra_node_properties):
	var root = EditorInterface.get_edited_scene_root() if Engine.is_editor_hint() else get_tree().root
	if not root: return
	var types = extra_node_properties.keys()	
	for node:Control in root.find_children("*", "Control"):		
		var type = node.theme_type_variation
		if type.is_empty() or not type in types: continue							
		for key in extra_node_properties[type]:									
			if key == "min_x":								
				node.custom_minimum_size.x = presets.numbers[presets.classes[type][key]]
			elif key == "min_y":
				node.custom_minimum_size.y = presets.numbers[presets.classes[type][key]]
			elif key == "expand_x":
				node.size_flags_horizontal = node.size_flags_horizontal | Control.SIZE_EXPAND if presets.numbers[presets.classes[type][key]] else node.size_flags_horizontal & ~Control.SIZE_EXPAND
			elif key == "expand_y":
				node.size_flags_vertical = node.size_flags_vertical | Control.SIZE_EXPAND if presets.numbers[presets.classes[type][key]] else node.size_flags_vertical & ~Control.SIZE_EXPAND

func save_presets_to_file(presets_file_path):		
	var file: = FileAccess.open(presets_file_path,FileAccess.WRITE)
	file.store_string(JSON.stringify(presets))
	file.close()	

func _exit_tree() -> void:
	if current_theme and not Engine.is_editor_hint():		
		save_presets_to_file(current_theme.resource_path.get_basename() +".theme.json")
		ResourceSaver.save(current_theme)

func get_color_as_image(color:Color):
	var img = Image.create(16,16,false,Image.FORMAT_RGBA8)
	img.fill(color)	
	return ImageTexture.create_from_image( img )

func update_stylebox(stylebox_preset_name):
	const default_stylebox_color = Color.DARK_GRAY
	var s:StyleBoxFlat = styleboxes[stylebox_preset_name]
	var data = presets.styleboxes[stylebox_preset_name]
	s.bg_color = default_stylebox_color if data.background_color == "default" else presets.colors[data.background_color]
	s.skew.x = 0 if data.background_skew_x == "default" else presets.numbers[data.background_skew_x]	
	s.skew.y = 0 if data.background_skew_y == "default" else presets.numbers[data.background_skew_y]	
	s.draw_center = true if data.background_enabled == "default" else presets.numbers[data.background_enabled]	
	
	s.border_color = Color() if data.border_color == "default" else presets.colors[data.border_color]
	s.border_width_left = 0 if data.border_left == "default" else presets.numbers[data.border_left]	
	s.border_width_top = 0 if data.border_top == "default" else presets.numbers[data.border_top]	
	s.border_width_right = 0 if data.border_right == "default" else presets.numbers[data.border_top]	
	s.border_width_bottom = 0 if data.border_bottom == "default" else presets.numbers[data.border_top]	
	s.border_blend = false if data.border_bottom == "default" else bool(presets.numbers[data.border_blend])
	
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
