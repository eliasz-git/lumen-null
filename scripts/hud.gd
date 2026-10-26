extends CanvasLayer
## Minimal HUD: vignette, reticle, cooldown bar, death/win overlay, and the
## pause-and-tooltip tutorial panel.

signal tooltip_acknowledged
signal tutorial_skip_requested

const ACK_GUARD_MS := 450

@onready var meter: ProgressBar = $Control/CooldownBar/Bar
@onready var meter_label: Label = $Control/CooldownBar/Bar/Label
@onready var overlay: Control = $Control/Overlay
@onready var overlay_title: Label = $Control/Overlay/Center/VBox/Title
@onready var overlay_hint: Label = $Control/Overlay/Center/VBox/Hint
@onready var game: Node = get_node("/root/GameState")
@onready var tutorial_prompt: Label = $Control/TutorialPrompt
@onready var tooltip: Control = $Control/Tooltip
@onready var tooltip_title: Label = $Control/Tooltip/TooltipBox/TooltipTitle
@onready var tooltip_text: Label = $Control/Tooltip/TooltipBox/TooltipText
@onready var tooltip_hint: Label = $Control/Tooltip/TooltipBox/TooltipHint

var tooltip_shown_at := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.visible = false
	tooltip.visible = false
	tutorial_prompt.text = ""
	game.player_died.connect(_on_player_died)
	game.player_won.connect(_on_player_won)


func _process(_delta: float) -> void:
	if overlay.visible or tooltip.visible:
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

	match event.keycode:
		KEY_R:
			game.restart()
		KEY_ESCAPE:
			tutorial_skip_requested.emit()
			if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_player_died() -> void:
	overlay.visible = true
	overlay_title.text = "LOST"
	overlay_hint.text = "R  //  TRY AGAIN"
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_player_won() -> void:
	overlay.visible = true
	overlay_title.text = "EXIT FOUND"
	overlay_hint.text = "R  //  RESTART TUTORIAL"
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


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
