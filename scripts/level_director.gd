extends Node
## Pause-and-tooltip tutorial.
## "info" steps pause the game until SPACE is pressed.
## "scan" steps pause for the tooltip, then unpause and wait for the player to
## actually fire a scan (the hunter ignores it) before continuing.

@onready var game: Node = get_node("/root/GameState")
@onready var hud: Node = $"../HUD"

var current := -1
var active := true
var waiting_for_scan := false

var steps := [
	{
		"type": "info",
		"title": "LUMEN NULL",
		"text": "You are in a dark facility.\nYou cannot see anything until you scan.\n\nWASD to move   //   MOUSE to look   //   SHIFT to sprint",
	},
	{
		"type": "info",
		"title": "THE SCANNER",
		"text": "Your lidar fires a cone of rays in front of you.\nEvery ray that hits something leaves a dot behind.\nDots are colored by distance: yellow is close, purple is far.",
	},
	{
		"type": "scan",
		"title": "PRACTICE SCAN",
		"text": "Face a wall, then HOLD E and RELEASE to fire a scan.\nHolding longer fires more rays and reaches farther,\nbut takes longer to recharge.\n\nThe hunter will NOT hear this one.",
		"prompt": "HOLD  E   then   RELEASE   to scan",
	},
	{
		"type": "info",
		"title": "THE HUNTER",
		"text": "From now on, every scan tells the hunter where you were.\nIt lights up RED when you hit it, and it walks to the\nplace you scanned from. Scan, then move.",
	},
	{
		"type": "info",
		"title": "COVER",
		"text": "Use the walls for cover. Scan to find a route,\nthen relocate while the hunter searches the old spot.",
	},
	{
		"type": "info",
		"title": "THE EXIT",
		"text": "Find the CYAN beacon at the far end of the facility.\nReach it to escape.\n\nGood luck.",
	},
]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	game.hunter_suppressed = true
	game.ping_fired.connect(_on_ping_fired)
	hud.tooltip_acknowledged.connect(_on_tooltip_acknowledged)
	hud.tutorial_skip_requested.connect(skip_tutorial)
	_show_step(0)


func _show_step(index: int) -> void:
	if not active:
		return
	if index >= steps.size():
		_finish()
		return
	current = index
	get_tree().paused = true
	hud.show_tooltip(steps[index]["title"], steps[index]["text"])


func _on_tooltip_acknowledged() -> void:
	if not active:
		return
	var step: Dictionary = steps[current]
	get_tree().paused = false
	if step["type"] == "scan":
		hud.show_tutorial_prompt(step["prompt"])
		waiting_for_scan = true
	else:
		_show_step(current + 1)


func _on_ping_fired(_from: Vector3) -> void:
	if not active or not waiting_for_scan:
		return
	waiting_for_scan = false
	hud.show_tutorial_prompt("")
	_next_after_scan.call_deferred()


func _next_after_scan() -> void:
	await get_tree().create_timer(1.6).timeout
	game.hunter_suppressed = false
	_show_step(current + 1)


func skip_tutorial() -> void:
	if not active:
		return
	active = false
	waiting_for_scan = false
	game.hunter_suppressed = false
	hud.show_tutorial_prompt("")
	hud.hide_tooltip()
	get_tree().paused = false


func _finish() -> void:
	active = false
	game.hunter_suppressed = false
	hud.show_tutorial_prompt("")
	hud.hide_tooltip()
	get_tree().paused = false
