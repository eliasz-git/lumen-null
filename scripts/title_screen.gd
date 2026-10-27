extends Control
## Title screen: drifting scan dots, menu music, play / level select / settings.

const LevelData := preload("res://scripts/level_data.gd")
const UITheme := preload("res://scripts/ui_theme.gd")
const MUSIC_DB := -9.0

var settings: Node
var game: Node
var main_box: VBoxContainer
var select_box: VBoxContainer
var level_list: VBoxContainer
var settings_box: VBoxContainer
var play_button: Button
var music: AudioStreamPlayer
var dots: Array = []
var time := 0.0
var starting := false
var _remap_callable: Callable
var _pending_level := -1
var _choosing_difficulty := false


func _ready() -> void:
	settings = get_node("/root/GameSettings")
	game = get_node("/root/GameState")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	theme = UITheme.build()

	for i in range(150):
		dots.append({
			"x": randf(), "y": randf(), "speed": randf_range(0.004, 0.02),
			"r": randf_range(1.0, 3.2), "tw": randf_range(0.5, 2.0), "phase": randf() * TAU,
		})

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	center.add_child(column)

	var title := Label.new()
	title.text = "LUMEN NULL"
	title.add_theme_font_size_override("font_size", 84)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var sub := Label.new()
	sub.text = "SEE EVERYTHING  //  BE SEEN"
	sub.add_theme_font_size_override("font_size", 16)
	sub.modulate = Color(1, 1, 1, 0.55)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(sub)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 28)
	column.add_child(gap)

	main_box = _panel(column)
	select_box = _panel(column)
	settings_box = _panel(column)
	_build_main()
	_build_select()
	_build_settings()

	music = AudioStreamPlayer.new()
	music.stream = load("res://sounds/menu_music.wav")
	music.volume_db = -40.0
	add_child(music)
	music.finished.connect(music.play)
	music.play()
	create_tween().tween_property(music, "volume_db", MUSIC_DB, 2.5)

	if game.open_level_select:
		game.open_level_select = false
		_show(select_box)
	else:
		_show(main_box)


func _process(delta: float) -> void:
	time += delta
	queue_redraw()


func _draw() -> void:
	for d in dots:
		var y := fposmod(d["y"] - time * d["speed"], 1.0)
		var a := 0.1 + 0.45 * (0.5 + 0.5 * sin(time * d["tw"] + d["phase"]))
		draw_circle(Vector2(d["x"] * size.x, y * size.y), d["r"], Color(0.92, 0.97, 1.0, a))
	var phase := fposmod(time, 8.0) / 8.0
	var radius := phase * maxf(size.x, size.y) * 0.75
	draw_arc(size * 0.5, radius, 0.0, TAU, 160, Color(0.92, 0.97, 1.0, (1.0 - phase) * 0.12), 2.0, true)


func _panel(parent: Control) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.custom_minimum_size = Vector2(460, 0)
	box.visible = false
	parent.add_child(box)
	return box


func _button(parent: Control, text: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(callback)
	parent.add_child(b)
	return b


func _show(box: Control) -> void:
	for p in [main_box, select_box, settings_box]:
		p.visible = (p == box)
	if box == select_box:
		_refresh_levels()
	elif box == main_box:
		_refresh_play()
		play_button.grab_focus()


func _build_main() -> void:
	play_button = _button(main_box, "PLAY", _on_play)
	_button(main_box, "LEVEL SELECT", func(): _show(select_box))
	_button(main_box, "SETTINGS", func(): _show(settings_box))
	_button(main_box, "QUIT", func(): get_tree().quit())


func _refresh_play() -> void:
	if settings.best_times.is_empty() and settings.unlocked_levels <= 1:
		play_button.text = "PLAY"
	else:
		var next := mini(settings.unlocked_levels, LevelData.COUNT) - 1
		play_button.text = "CONTINUE  //  LEVEL %d" % (next + 1)


func _on_play() -> void:
	var next := 0
	if not (settings.best_times.is_empty() and settings.unlocked_levels <= 1):
		next = mini(settings.unlocked_levels, LevelData.COUNT) - 1
	_select_level(next)


func _build_select() -> void:
	var header := Label.new()
	header.text = "SELECT LEVEL"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	select_box.add_child(header)
	level_list = VBoxContainer.new()
	level_list.add_theme_constant_override("separation", 8)
	select_box.add_child(level_list)
	_button(select_box, "BACK", func(): _show(main_box))


func _refresh_levels() -> void:
	for c in level_list.get_children():
		level_list.remove_child(c)
		c.queue_free()
	var first: Button = null
	for i in range(LevelData.COUNT):
		var def: Dictionary = LevelData.get_level(i)
		var b := Button.new()
		if i < settings.unlocked_levels:
			var best: float = settings.best_time(i)
			var best_text := "BEST  %02d:%02d" % [int(best) / 60, int(best) % 60] if best > 0.0 else "NOT CLEARED"
			var cleared_tag := "  [CLEARED]" if game.is_cleared(i) else ""
			b.text = "%d   //   %s\n%s     %s%s" % [i + 1, def["name"], def["tagline"], best_text, cleared_tag]
			b.pressed.connect(_select_level.bind(i))
			if first == null:
				first = b
		else:
			b.text = "%d   //   LOCKED\nCLEAR LEVEL %d TO UNLOCK" % [i + 1, i]
			b.disabled = true
		level_list.add_child(b)
	var target := first
	for c in level_list.get_children():
		if not (c as Button).disabled:
			target = c
	if target != null:
		target.grab_focus.call_deferred()


func _build_settings() -> void:
	var header := Label.new()
	header.text = "SETTINGS"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	settings_box.add_child(header)

	settings_box.add_child(_label("MOUSE SENSITIVITY"))
	var sens := _slider(0.0005, 0.006, 0.0001, float(settings.get("mouse_sensitivity")))
	sens.value_changed.connect(func(v): settings.call("set_mouse_sensitivity", v))
	settings_box.add_child(sens)

	settings_box.add_child(_label("MASTER VOLUME"))
	var vol := _slider(0.0, 1.0, 0.01, float(settings.get("master_volume")))
	vol.value_changed.connect(func(v): settings.call("set_master_volume", v))
	settings_box.add_child(vol)

	var full := CheckButton.new()
	full.text = "FULLSCREEN"
	full.button_pressed = bool(settings.get("fullscreen"))
	full.toggled.connect(func(v): settings.call("set_fullscreen", v))
	settings_box.add_child(full)

	_button(settings_box, "BACK", func(): _show(main_box))


	var remapping := false
	var scan_btn: Button

	settings_box.add_child(_label("SCAN KEY"))
	scan_btn = _button(settings_box, "SCAN KEY  //  %s" % _key_name(int(settings.get("scan_key"))), func(): _begin_scan_remap(scan_btn))
	scan_btn.pressed.connect(func(): _begin_scan_remap(scan_btn))


func _key_name(key: int) -> String:
	var names := {
		KEY_E: "E",
		KEY_Q: "Q",
		KEY_R: "R",
		KEY_F: "F",
		KEY_SPACE: "SPACE",
		KEY_SHIFT: "SHIFT",
		KEY_CTRL: "CTRL",
		KEY_ALT: "ALT",
	}
	return names[key] if names.has(key) else "KEY %d" % key


func _begin_scan_remap(btn: Button) -> void:
	btn.text = "PRESS A KEY..."
	_remap_callable = Callable(self, "_on_scan_remap_input").bind(btn)
	get_tree().connect("input", _remap_callable)


func _on_scan_remap_input(event: InputEvent, btn: Button) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			get_tree().disconnect("input", _remap_callable)
			btn.text = "SCAN KEY  //  %s" % _key_name(int(settings.get("scan_key")))
			return
		get_tree().disconnect("input", _remap_callable)
		var new_key: int = event.keycode
		settings.call("set_scan_key", new_key)
		btn.text = "SCAN KEY  //  %s" % _key_name(new_key)
	elif event is InputEventJoypadButton and event.pressed:
		get_tree().disconnect("input", _remap_callable)
		btn.text = "SCAN KEY  //  GAMEPAD BTN %d" % event.button_index


func _label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 14)
	l.modulate = Color(1, 1, 1, 0.7)
	return l


func _slider(lo: float, hi: float, step: float, value: float) -> HSlider:
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = step
	s.value = value
	s.custom_minimum_size = Vector2(0, 28)
	return s


var _difficulty_box: VBoxContainer = null


func _select_level(index: int) -> void:
	if not game.is_cleared(index):
		_start_level(index)
		return
	_pending_level = index
	_show_difficulty_selector()


func _show_difficulty_selector() -> void:
	_choosing_difficulty = true
	var center := get_node("Control/Overlay/Center/VBox")
	for c in center.get_children():
		c.queue_free()
	_difficulty_box = VBoxContainer.new()
	_difficulty_box.add_theme_constant_override("separation", 16)
	_difficulty_box.custom_minimum_size = Vector2(460, 0)
	var title := Label.new()
	title.text = "CHOOSE DIFFICULTY"
	title.add_theme_font_size_override("font_size", 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_difficulty_box.add_child(title)
	var normal := Button.new()
	normal.text = "NORMAL  //  minimap + standard hunters"
	normal.pressed.connect(func(): _confirm_difficulty("normal"))
	_difficulty_box.add_child(normal)
	var hardcore := Button.new()
	hardcore.text = "HARDCORE  //  no minimap, tougher hunters"
	hardcore.pressed.connect(func(): _confirm_difficulty("hardcore"))
	_difficulty_box.add_child(hardcore)
	center.add_child(_difficulty_box)
	get_node("Control/Overlay").visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _confirm_difficulty(d: String) -> void:
	game.set_difficulty(d)
	_choosing_difficulty = false
	if _difficulty_box != null:
		_difficulty_box.queue_free()
		_difficulty_box = null
	get_node("Control/Overlay").visible = false
	_start_level(_pending_level)
	_pending_level = -1


func _cancel_difficulty() -> void:
	_choosing_difficulty = false
	if _difficulty_box != null:
		_difficulty_box.queue_free()
		_difficulty_box = null
	get_node("Control/Overlay").visible = false
	_pending_level = -1


func _start_level(index: int) -> void:
	if starting:
		return
	starting = true
	var tween := create_tween()
	tween.tween_property(music, "volume_db", -60.0, 0.4)
	await tween.finished
	game.start_level(index)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if _choosing_difficulty:
			_cancel_difficulty()
			return
		if select_box.visible or settings_box.visible:
			_show(main_box)
