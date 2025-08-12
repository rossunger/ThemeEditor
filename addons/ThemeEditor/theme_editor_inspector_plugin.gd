@tool 
extends EditorInspectorPlugin

var targets: Array
var possible_types = []
var special_base_types = []
var presets
var current_theme_path = ""
var object_type

func theme_loaded(path):
	current_theme_path = path
	
func get_theme():
	var parent = targets[0]
	while true:
		if parent.theme: return parent.theme
		if parent == EditorInterface.get_edited_scene_root(): break
		parent = parent.get_parent()		
	return null
	
func _can_handle(object: Object) -> bool:				
	possible_types = []
	targets = []	
	object_type = object.get_class()
	if object_type == "MultiNodeEdit":
		targets = EditorInterface.get_selection().get_selected_nodes()		
		var first_type
		for obj in targets:			
			if obj is Node and obj.scene_file_path:
				var special_base_name = object.scene_file_path.get_file().get_basename().to_pascal_case()
				if special_base_name in special_base_types and not first_type:
					first_type = special_base_name
				elif first_type != special_base_name:
					print("special type, mix")
					return false					
			elif first_type and first_type != obj.get_class(): 
				print("base type, mix", first_type, obj.get_class())
				return false
			else:
				first_type = targets[0].get_class()
			object_type = first_type #targets[0].get_class()
			
	elif object is Node and object.scene_file_path:
		var special_base_name = object.scene_file_path.get_file().get_basename().to_pascal_case()
		if special_base_name in special_base_types:
			object_type = special_base_name	
	for type in presets.classes.keys():
		if object_type in presets.classes[type].base_type:
			possible_types.push_back(type)				
	if len(possible_types)>0:
		if not object.get_class() == "MultiNodeEdit":		
			targets.push_back(object)
		return true
	return false
	
func _parse_begin(object):	
	var label = Label.new()
	label.text = "Theme class"
	var option := OptionButton.new()
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	option.add_item("", 0)
	var i = 1
	for c in possible_types:
		option.add_item(c, i)
		if targets[0].theme_type_variation == c + "_"+ targets[0].get_class():
			option.select(i)
		i+=1	
	option.item_selected.connect(func(idx):
		var type = option.get_item_text(idx)
		for target in targets:
			target.theme_type_variation = type +"_"+ target.get_class() if not object_type in special_base_types else type
	)	
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(label)
	hbox.add_child(option)
	var t = get_theme()	
	if not t or t.resource_path != current_theme_path:		
		label.text += " (!)"
		label.tooltip_text = "This control is not currently using the active theme! class will be added, but may have no effect"
		option.tooltip_text = "This control is not currently using the active theme! class will be added, but may have no effect"
	add_custom_control(hbox)
	
	
