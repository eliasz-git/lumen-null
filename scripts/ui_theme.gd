extends RefCounted
## Shared flat black-and-white UI theme (title screen, pause/finish menus).

static func build() -> Theme:
	var t := Theme.new()
	t.set_stylebox("normal", "Button", _box(Color(0, 0, 0, 0.55), Color(1, 1, 1, 0.3)))
	t.set_stylebox("hover", "Button", _box(Color(1, 1, 1, 0.1), Color(1, 1, 1, 0.8)))
	t.set_stylebox("pressed", "Button", _box(Color(1, 1, 1, 0.22), Color(1, 1, 1, 1.0)))
	t.set_stylebox("focus", "Button", _box(Color(1, 1, 1, 0.08), Color(1, 1, 1, 0.95), 2))
	t.set_stylebox("disabled", "Button", _box(Color(0, 0, 0, 0.35), Color(1, 1, 1, 0.12)))
	t.set_color("font_color", "Button", Color(0.88, 0.93, 1.0))
	t.set_color("font_hover_color", "Button", Color(1, 1, 1))
	t.set_color("font_focus_color", "Button", Color(1, 1, 1))
	t.set_color("font_disabled_color", "Button", Color(1, 1, 1, 0.3))
	t.set_font_size("font_size", "Button", 18)
	t.set_color("font_color", "Label", Color(0.9, 0.95, 1.0))
	t.set_font_size("font_size", "Label", 18)
	return t


static func _box(fill: Color, border: Color, width: int = 1) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = fill
	b.border_color = border
	b.set_border_width_all(width)
	b.content_margin_left = 18
	b.content_margin_right = 18
	b.content_margin_top = 10
	b.content_margin_bottom = 10
	return b
