@tool
extends HBoxContainer

signal rename_requested
signal texture_changed
signal texture_duplicated
signal remove_requested

var preset_name
var initial_texture_path

func _ready():	
	%preset_name.text = preset_name	
	if initial_texture_path and FileAccess.file_exists(initial_texture_path):
		%texture_preview.texture = load(initial_texture_path)
		%texture_preview.tooltip_text = initial_texture_path.get_file().get_basename()
		%load_texture_button.tooltip_text = initial_texture_path.get_file().get_basename()
	
	%preset_name.text_submitted.connect(func(text):
		rename_requested.emit.bind(text)
	)
	%preset_name.focus_exited.connect(func():
		rename_requested.emit.bind(%preset_name.text)		
	)		
	%load_texture_button.pressed.connect(func():
		var dialog := FileDialog.new()
		dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		dialog.title = "select texture"
		dialog.add_filter("*.png,*.jpg,*.webp,*.svg,*.tiff,*.bmp,*.gif ", "images")		
		dialog.file_selected.connect(func(path):
			%texture_preview.texture = load(path)
			%texture_preview.tooltip_text = path.get_file().get_basename()
			%load_texture_button.tooltip_text = path.get_file().get_basename()
			texture_changed.emit(preset_name, path)			
		)
		add_child(dialog)
		dialog.popup_centered()
	)
	%duplicate_button.pressed.connect(duplicate_texture_preset)
	%remove_preset_button.pressed.connect(func(): remove_requested.emit(preset_name))
		
func duplicate_texture_preset():		
	texture_duplicated.emit(preset_name + "_copy", preset_name)

func reset_name():
	%preset_name.text = preset_name
