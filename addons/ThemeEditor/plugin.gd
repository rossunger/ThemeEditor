@tool
extends EditorPlugin

var inspector_plugin
var theme_editor
var preset_editor

func _enter_tree():
	inspector_plugin = preload("theme_editor_inspector_plugin.gd").new()
	theme_editor = preload("theme_editor.tscn").instantiate()
	preset_editor = preload("preset_manager.tscn").instantiate()
	preset_editor.presets = theme_editor.presets		
	preset_editor.special_base_types = theme_editor.special_controls_list
	preset_editor.preset_changed.connect(theme_editor.apply_variable_to_theme)
	preset_editor.preset_rename_requested.connect(func(a,b,c):		
		theme_editor.rename_preset(a,b,c)
	)
	theme_editor.preset_manager = preset_editor
	inspector_plugin.presets = theme_editor.presets
	inspector_plugin.special_base_types = theme_editor.special_controls_list
	theme_editor.theme_loaded.connect(inspector_plugin.theme_loaded)	
	theme_editor.theme_loaded.connect(preset_editor.load_presets)
	add_inspector_plugin(inspector_plugin)
	add_control_to_bottom_panel(theme_editor, "ThemeEditor")
	add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_UL, preset_editor)

func _exit_tree():
	remove_inspector_plugin(inspector_plugin)
	remove_control_from_bottom_panel(theme_editor)
	remove_control_from_docks(preset_editor)
	
