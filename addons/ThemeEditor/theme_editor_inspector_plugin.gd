@tool 
extends EditorInspectorPlugin

var target:Control
var possible_types = []
var presets
var current_theme_path = ""
func theme_loaded(path):
	current_theme_path = path
	
func get_theme():
	var parent = target	
	while true:
		if parent.theme: return parent.theme
		if parent == EditorInterface.get_edited_scene_root(): break
		parent = parent.get_parent()		
	return null
	
func _can_handle(object: Object) -> bool:			
	possible_types = []
	for type in presets.classes.keys():
		if object.get_class() in presets.classes[type].base_type:
			possible_types.push_back(type)				
	if len(possible_types)>0:
		target = object
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
		if target.theme_type_variation == c:
			option.select(i)
		i+=1	
	option.item_selected.connect(func(idx):
		target.theme_type_variation = option.get_item_text(idx)
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
	
	
