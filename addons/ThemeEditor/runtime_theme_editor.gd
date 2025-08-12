extends Control
@export var tweak_mode_only = true
func _ready():
	var preset_manager = preload("preset_manager.tscn").instantiate()
	var theme_editor =%ThemeEditor
	theme_editor.tweak_mode_only = tweak_mode_only
	theme_editor.preset_manager = preset_manager
	preset_manager.presets = theme_editor.presets			
	preset_manager.special_base_types = theme_editor.special_controls_list
	preset_manager.preset_changed.connect(theme_editor.apply_variable_to_theme)		
	preset_manager.preset_rename_requested.connect(theme_editor.rename_preset)
	preset_manager.tweak_mode_only = tweak_mode_only

	var panel = PanelContainer.new()	
	var stylebox=  StyleBoxFlat.new()
	stylebox.bg_color = Color(0.1,0.1,0.1,1.0)
	panel.add_theme_stylebox_override("panel", stylebox)
	add_child(panel)	
	panel.add_child(preset_manager)		
	preset_manager.custom_minimum_size.x = 300 if tweak_mode_only else 400
	preset_manager.size_flags_horizontal = Control.SIZE_SHRINK_END	
	%vsplit.split_offset = get_viewport_rect().size.y - 300
	
