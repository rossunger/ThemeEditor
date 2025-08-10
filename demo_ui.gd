extends PanelContainer

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed and not event.echo:
		%RuntimeThemeEditor.visible = !%RuntimeThemeEditor.visible
