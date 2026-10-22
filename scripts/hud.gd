extends CanvasLayer
## HUD: instructions, lidar cooldown meter, death/win overlays.

@onready var meter: ProgressBar = $Control/CooldownBar/Bar
@onready var meter_label: Label = $Control/CooldownBar/Bar/Label
@onready var overlay: Control = $Control/Overlay
@onready var overlay_title: Label = $Control/Overlay/Center/VBox/Title
@onready var overlay_hint: Label = $Control/Overlay/Center/VBox/Hint
@onready var game: Node = get_node("/root/GameState")


func _ready() -> void:
	# Run input.process while the tree is paused (death/win overlay) so R can restart.
	process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.visible = false
	game.player_died.connect(_on_player_died)
	game.player_won.connect(_on_player_won)


func _process(_delta: float) -> void:
	if overlay.visible:
		return
	var cd: float = game.ping_cooldown_left
	var total: float = game.cooldown_total
	if total <= 0.0:
		total = game.ping_cooldown
	meter.max_value = total
	meter.value = total - cd
	meter_label.text = "LIDAR READY" if game.can_ping else "RECHARGING " + str(ceilf(cd))


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_R:
				game.restart()
			KEY_ESCAPE:
				if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
					Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_player_died() -> void:
	overlay.visible = true
	overlay_title.text = "IT FOUND YOU"
	overlay_title.modulate = Color(0.95, 0.2, 0.12)
	overlay_hint.text = "Press R to try again"
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_player_won() -> void:
	overlay.visible = true
	overlay_title.text = "YOU ESCAPED"
	overlay_title.modulate = Color(0.35, 1.0, 0.6)
	overlay_hint.text = "Press R to play again"