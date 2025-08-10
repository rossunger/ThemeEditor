@tool 
extends PanelContainer

signal stylebox_changed
signal rename_requested
signal stylebox_duplicated
signal remove_requested

@onready var tree:Tree = %Tree
var preset_name
var is_texture = false
var tweak_mode_only = false

var flat_props = {
	"background":["color", "enabled", "skew_x", "skew_y"], 
	"border": ["color", "left", "top","right", "bottom", "blend"],
	"corners": ["top_left", "top_right","bottom_left","bottom_right", "detail"], 
	"margins": ["left", "top","right", "bottom"], 
	"shadow": ["color", "size", "offset_x", "offset_y"]
}
var texture_props = {
	"texture":[ "texture", "modulate", "draw_center", "left", "top","right", "bottom", "tile_x", "tile_y"],
	"margins": ["left", "top","right", "bottom"], 	
}
var presets

func _ready():	
	%preset_name.text = preset_name
	if not tweak_mode_only:
		%preset_name.text_submitted.connect(func(text):rename_requested.emit(text))
		%preset_name.focus_exited.connect(func(): rename_requested.emit(preset_name))
		%duplicate_stylebox_button.pressed.connect(duplicate_stylebox)
		%remove_preset_button.pressed.connect(func():
			remove_requested.emit(preset_name)
		)
	else:
		%preset_name.editable = false
		%preset_name.focus_mode = FOCUS_NONE
		%preset_name.selecting_enabled = false
		%duplicate_stylebox_button.queue_free()
		%remove_preset_button.queue_free()
		
	%show_preset_details_button.toggled.connect(func(toggle_on):
		%show_preset_details_button.text = "<" if not toggle_on else "v"
		%is_texture_button.visible = toggle_on		
		tree.visible = toggle_on
		
	)	
	%is_texture_button.toggled.connect(func(toggle_on):
		%is_texture_button.text = "texture stylebox" if toggle_on else "flat stylebox"	
		if not presets.styleboxes[preset_name].has("is_texture"): print(preset_name)
		if presets.styleboxes[preset_name].is_texture != toggle_on:
			presets.styleboxes[preset_name].is_texture = toggle_on
			is_texture = toggle_on
			if is_texture:
				for category in texture_props.keys():
					for prop in texture_props[category]:
						if not presets.styleboxes[preset_name].has(category + "_" + prop):
							presets.styleboxes[preset_name][category + "_" + prop] = "default"
			else:
				for category in flat_props.keys():
					for prop in flat_props[category]:
						if not presets.styleboxes[preset_name].has(category + "_" + prop):
							presets.styleboxes[preset_name][category + "_" + prop] = "default"
			stylebox_changed.emit()
			build_tree()
	)
	%is_texture_button.button_pressed = is_texture
	build_tree()
	tree.item_edited.connect(item_edited)	
		
func duplicate_stylebox():	
	presets.styleboxes[preset_name + "_copy"] = presets.styleboxes[preset_name].duplicate(true)
	stylebox_duplicated.emit(preset_name + "_copy")
	
func item_edited():
	var item = tree.get_edited()
	var prop = item.get_metadata(0)	
	var preset_list = item.get_metadata(1)
	var value = preset_list[int(item.get_range(1))]		
	presets.styleboxes[preset_name][prop] = value
	stylebox_changed.emit()
	

func build_tree():
	tree.clear()
	var root := tree.create_item()
	if not is_texture:
		for category in flat_props.keys():
			var cat = root.create_child()
			cat.set_text(0, category)
			var i = 0
			for prop in flat_props[category]:								
				var item = cat.create_child()
				item.set_text(0,prop)						
				item.set_metadata(0, category+"_"+prop)				
				item.set_editable(1,true)
				item.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)				
				if "color" in prop:									
					item.set_metadata(1, presets.colors.keys())				
					item.set_text(1, ",".join(presets.colors.keys()))					
					var value = presets.styleboxes[preset_name][category+"_"+prop]
					
					if presets.colors[value] is Color:
						item.set_icon(0, get_color_as_image(presets.colors[value]))						
					item.set_range(1, presets.colors.keys().find(value))					
				else:					
					item.set_metadata(1, presets.numbers.keys())				
					item.set_text(1, ",".join(presets.numbers.keys()))
					var value = presets.styleboxes[preset_name][category+"_"+prop]
					item.set_range(1, presets.numbers.keys().find(value))
	else:
		for category in texture_props.keys():
			var cat = root.create_child()
			cat.set_text(0, category)
			var i = 0
			for prop in texture_props[category]:								
				var item = cat.create_child()
				item.set_text(0,prop)						
				item.set_metadata(0, category+"_"+prop)				
				item.set_editable(1,true)
				item.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)				
				if prop == "modulate":									
					item.set_metadata(1, presets.colors.keys())				
					item.set_text(1, ",".join(presets.colors.keys()))					
					var value = presets.styleboxes[preset_name][category+"_"+prop]					
					if presets.colors[value] is Color:
						item.set_icon(0, get_color_as_image(presets.colors[value]))
					item.set_range(1, presets.colors.keys().find(value))
				elif prop == "texture":
					item.set_metadata(1, presets.textures.keys())				
					item.set_text(1, ",".join(presets.textures.keys()))					
					var value = presets.styleboxes[preset_name][category+"_"+prop]					
					if FileAccess.file_exists( presets.textures[value]):
						item.set_icon(0, load(presets.textures[value]))
						item.set_icon_max_width(0, 32)
					else:
						print(value)
					item.set_range(1, presets.textures.keys().find(value))
				else:					
					item.set_metadata(1, presets.numbers.keys())				
					item.set_text(1, ",".join(presets.numbers.keys()))
					var value = presets.styleboxes[preset_name][category+"_"+prop]
					item.set_range(1, presets.numbers.keys().find(value))
				
					
func get_color_as_image(color:Color):
	var img = Image.create(16,16,false,Image.FORMAT_RGBA8)
	img.fill(color)	
	return ImageTexture.create_from_image( img )

func reset_name():
	%preset_name.text = preset_name
