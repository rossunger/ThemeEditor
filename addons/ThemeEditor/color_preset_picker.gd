@tool
extends HBoxContainer

signal color_changed
signal rename_requested
signal remove_requested

var preset_name:String
var preset_color:Color

func _ready():	
	%label.text = preset_name	
	%picker.color = preset_color
	%picker.color_changed.connect(func(color):
		color_changed.emit(color)
	)
	%label.text_submitted.connect(func(text):
		rename_requested.emit(text)
	)
	%remove_preset_button.pressed.connect(func():
		remove_requested.emit(preset_name)
	)
	

func reset_name():
	%label.text = preset_name

func disable():
	%label.editable = false
	%picker.disabled = true
