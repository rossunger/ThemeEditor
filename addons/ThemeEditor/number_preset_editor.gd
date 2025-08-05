@tool 
extends HBoxContainer

signal rename_requested
signal value_changed
signal remove_requested

var preset_name: String
var preset_value: int

func _ready():
	%preset_name.text = preset_name
	%preset_name.text_submitted.connect(func(text):
		rename_requested.emit(text)
	)
	%preset_name.focus_exited.connect(func():
		rename_requested.emit(%preset_name.text)
	)	
	update_value(str(preset_value))
	%value.text_submitted.connect(update_value)
	%value.focus_exited.connect(update_value)
	%value.set_meta("value",preset_value)
	%remove_preset_button.pressed.connect(func():
		remove_requested.emit(preset_name)		
	)
func reset_name():
	%preset_name.text = preset_name

func update_value(_text:=""):
	var text:String
	if not _text.is_empty():
		text = _text
	else:
		text = %preset_name.text
	if text.is_valid_int():
		%value.text = text
		%value.tooltip_text = text
		%value.set_meta("value",int(text))
		value_changed.emit(int(text))
	else:
		%value.text = str( %value.get_meta("value"))
