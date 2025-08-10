@tool
extends Control

signal confirmed

var type_list = []
var special_type_list = []
var initial_selection = []
@onready var tree:Tree = %base_type_tree
func _ready():
	%confirm_button.pressed.connect(confirm)
	var root = tree.create_item()
	for type in type_list:
		var item := root.create_child()
		item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
		item.set_text(0, type)
		item.set_editable(0, true)
		item.set_checked(0, type in initial_selection)
		
func confirm():
	var result = []
	for item:TreeItem in tree.get_root().get_children():
		if item.is_checked(0):
			var txt = item.get_text(0)
			if txt in special_type_list:
				result = [txt]
				break
			else:
				result.push_back(item.get_text(0))
	confirmed.emit(result)
	if get_parent() is Window:
		get_parent().queue_free()
	else:
		queue_free()
