extends CanvasLayer
## HUD: vignette, reticle, charge/cooldown meter, tutorial tooltips, and the
## end-of-level / death / pause menus.

signal tooltip_acknowledged
signal tutorial_skip_requested

const LevelData := preload("res://scripts/level_data.gd")
const UITheme := preload("res://scripts/ui_theme.gd")
const ACK_GUARD_MS := 450

@onready var meter: ProgressBar = $Control/CooldownBar/Bar
@onready var meter_label: Label = $Control/CooldownBar/Bar/Label
@onready var overlay: Control = $Control/Overlay
@onready var overlay_title: Label = $Control/Overlay/Center/VBox/Title
@onready var overlay_hint: Label = $Control/Overlay/Center/VBox/Hint
@onready var game: Node = get_node("/root/GameState")
@onready var settings: Node = get_node("/root/GameSettings")
@onready var tutorial_prompt: Label = $Control/TutorialPrompt
@onready var tooltip: Control = $Control/Tooltip
@onready var tooltip_title: Label = $Control/Tooltip/TooltipBox/TooltipTitle
@onready var tooltip_text: Label = $Control/Tooltip/TooltipBox/TooltipText
@onready var tooltip_hint: Label = $Control/Tooltip/TooltipBox/TooltipHint

var tooltip_shown_at := 0
var menu: VBoxContainer
var pause_open := false
var can_go_next := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.visible = false
	overlay.theme = UITheme.build()
	tooltip.visible = false
	tutorial_prompt.text = ""
	tutorial_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu = VBoxContainer.new()
	menu.add_theme_constant_override("separation", 8)
	menu.custom_minimum_size = Vector2(360, 0)
	overlay_hint.get_parent().add_child(menu)
	game.player_died.connect(_on_player_died)
	game.player_won.connect(_on_player_won)


func _process(_delta: float) -> void:
	if overlay.visible or tooltip.visible:
		return
	if game.charge >= 0.0:
		meter.max_value = 1.0
		meter.value = game.charge
		meter_label.text = "CHARGING"
		return
	var total: float = maxf(game.cooldown_total, 0.01)
	var left: float = game.cooldown_left
	meter.max_value = total
	meter.value = total - left
	meter_label.text = "SCAN READY" if left <= 0.0 else "RECHARGING"


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return

	if tooltip.visible:
		get_viewport().set_input_as_handled()
		if Time.get_ticks_msec() - tooltip_shown_at < ACK_GUARD_MS:
			return
		match event.keycode:
			KEY_SPACE:
				tooltip.visible = false
				tooltip_acknowledged.emit()
			KEY_ESCAPE:
				tutorial_skip_requested.emit()
		return

	if overlay.visible:
		match event.keycode:
			KEY_R:
				game.restart()
			KEY_M:
				game.go_to_menu()
			KEY_N:
				if can_go_next:
					game.start_level(game.current_level + 1)
			KEY_ESCAPE:
				if pause_open:
					_resume()
		return

	match event.keycode:
		KEY_R:
			game.restart()
		KEY_ESCAPE:
			if game.tutorial_active:
				tutorial_skip_requested.emit()
			else:
				_open_pause()


func _show_menu(title: String, hint: String, items: Array) -> void:
	overlay.visible = true
	overlay_title.text = title
	overlay_hint.text = hint
	for c in menu.get_children():
		menu.remove_child(c)
		c.queue_free()
	for item in items:
		var b := Button.new()
		b.text = item[0]
		b.pressed.connect(item[1])
		menu.add_child(b)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	(menu.get_child(0) as Button).grab_focus.call_deferred()


func _open_pause() -> void:
	if not game.alive or game.won:
		return
	pause_open = true
	can_go_next = false
	get_tree().paused = true
	_show_menu("PAUSED", "", [
		["RESUME  (ESC)", _resume],
		["RESTART  (R)", game.restart],
		["LEVEL SELECT", func(): game.go_to_menu(true)],
		["MAIN MENU  (M)", func(): game.go_to_menu()],
	])


func _resume() -> void:
	pause_open = false
	overlay.visible = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _on_player_died() -> void:
	can_go_next = false
	_show_menu("LOST", "THE HUNTER FOUND YOU", [
		["RETRY  (R)", game.restart],
		["LEVEL SELECT", func(): game.go_to_menu(true)],
		["MAIN MENU  (M)", func(): game.go_to_menu()],
	])


func _on_player_won() -> void:
	var level: int = game.current_level
	var new_best: bool = settings.record_time(level, game.elapsed)
	var def: Dictionary = LevelData.get_level(level)
	var has_next := level + 1 < LevelData.COUNT
	can_go_next = has_next
	var title := "NEW BEST" if new_best else "LEVEL COMPLETE"
	if not has_next:
		title = "YOU ESCAPED" if not new_best else "NEW BEST"
	var hint := "LEVEL %d  //  %s\nTIME  %s     BEST  %s" % [level + 1, def["name"], _fmt(game.elapsed), _fmt(settings.best_time(level))]
	var items: Array = []
	if has_next:
		items.append(["NEXT LEVEL  (N)", func(): game.start_level(level + 1)])
	items.append(["REPLAY  (R)", game.restart])
	items.append(["LEVEL SELECT", func(): game.go_to_menu(true)])
	items.append(["MAIN MENU  (M)", func(): game.go_to_menu()])
	_show_menu(title, hint, items)


func show_tutorial_prompt(message: String) -> void:
	tutorial_prompt.text = message


func show_tooltip(title: String, text: String) -> void:
	tooltip_title.text = title
	tooltip_text.text = text
	tooltip_hint.text = "SPACE  continue        ESC  skip tutorial"
	tooltip_shown_at = Time.get_ticks_msec()
	tooltip.visible = true


func hide_tooltip() -> void:
	tooltip.visible = false


func _fmt(t: float) -> String:
	if t <= 0.0:
		return "--:--"
	return "%02d:%02d" % [int(t) / 60, int(t) % 60]
