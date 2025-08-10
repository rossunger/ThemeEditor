@tool
extends HBoxContainer

signal rename_requested
signal font_changed
signal font_duplicated
signal remove_requested

var preset_name
var initial_font_path
var tweak_mode_only = false

func _ready():	
	%preset_name.text = preset_name	
	if initial_font_path and FileAccess.file_exists(initial_font_path):
		%preset_name.add_theme_font_override("font", load(initial_font_path))
		%load_font_button.tooltip_text = initial_font_path.get_file().get_basename()
	if not tweak_mode_only:
		%preset_name.text_submitted.connect(func(text):
			rename_requested.emit(text)
		)
		%preset_name.focus_exited.connect(func():
			rename_requested.emit(%preset_name.text)		
		)		
		%duplicate_button.pressed.connect(duplicate_font_preset)
		%remove_preset_button.pressed.connect(func(): remove_requested.emit(preset_name))
	else:
		%duplicate_button.queue_free()
		%remove_preset_button.queue_free()
		%preset_name.editable = false
		%preset_name.focus_mode = FOCUS_NONE
		%preset_name.selecting_enabled = false
	%load_font_button.pressed.connect(func():
		var dialog := FileDialog.new()
		dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		dialog.title = "select font"
		dialog.add_filter("*.ttf")
		dialog.add_filter("*.otf")
		dialog.add_filter("*.woff")		
		dialog.file_selected.connect(func(path):
			%preset_name.add_theme_font_override("font", load(path))
			%load_font_button.tooltip_text = path.get_file().get_basename()
			font_changed.emit(preset_name, path)			
		)
		add_child(dialog)
		dialog.popup_centered()
	)	
	
		
func duplicate_font_preset():		
	font_duplicated.emit(preset_name + "_copy", preset_name)

func reset_name():
	%preset_name.text = preset_name
