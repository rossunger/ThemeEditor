@tool
extends HBoxContainer

signal color_changed
signal rename_requested
signal remove_requested

var preset_name:String
var preset_color:Color
var tweak_mode_only = false

func _ready():	
	%preset_name.text = preset_name	
	%picker.color = preset_color
	%picker.color_changed.connect(func(color):		
		color_changed.emit(color)
	)
	if not tweak_mode_only:		
		%preset_name.text_submitted.connect(func(text):
			rename_requested.emit(text)
		)
		%remove_preset_button.pressed.connect(func():
			remove_requested.emit(preset_name)
		)
	else:
		%remove_preset_button.queue_free()
		%preset_name.editable = false
		%preset_name.focus_mode = FOCUS_NONE
		%preset_name.selecting_enabled = false

func reset_name():
	%preset_name.text = preset_name

func disable():
	%preset_name.editable = false
	%picker.disabled = true
