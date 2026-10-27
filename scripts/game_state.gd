extends Node3D
## Global game state: enemy targeting, win/lose + restart.
## The lidar pulse itself lives on the player/scanner now.

signal player_died
signal player_won
signal ping_fired(from: Vector3)

var last_ping_pos := Vector3.ZERO   # where the enemy was last drawn toward
var hunter_suppressed := false   # true during the practice-scan tutorial step
var alive := true
var won := false

# Cooldown state synced from the player for HUD display.
var current_level := 0
var level_def: Dictionary = {}
var open_level_select := false   # title screen opens on level select
var tutorial_active := false     # level director is running the tutorial
var cooldown_left := 0.0
var cooldown_total := 1.6
var charge := -1.0          # 0..1 while charging, -1 otherwise
var elapsed := 0.0          # run time, excludes paused time
var has_key := false        # player has collected the key (key/door levels)
var has_noise_item := false # player is carrying a noise distraction item
var key_required := false   # level requires the key before the exit opens
var doors: Array = []       # door instances awaiting the key
var difficulty := "normal"  # "normal" = minimap + standard, "hardcore" = no help
var cleared_levels := []    # level indices cleared at least once (unlocks difficulty selector)

@onready var _player: Node3D
@onready var settings: Node = get_node("/root/GameSettings")


func _process(delta: float) -> void:
	if alive and not won:
		elapsed += delta


func register_player(p: Node3D) -> void:
	_player = p


func set_cooldown(left: float, total: float) -> void:
	cooldown_left = left
	cooldown_total = total


func kill() -> void:
	if not alive:
		return
	alive = false
	player_died.emit()
	if _player and _player.has_method("play_death_sound"):
		_player.play_death_sound()
	get_tree().paused = true


func win() -> void:
	if won:
		return
	won = true
	player_won.emit()
	mark_cleared(current_level)
	get_tree().paused = true


func register_door(door: Node3D) -> void:
	doors.append(door)


func collect_key() -> void:
	if has_key:
		return
	has_key = true
	for door in doors:
		door.queue_free()
	doors.clear()


func set_has_noise_item(value: bool) -> void:
	has_noise_item = value


func hear_noise(position: Vector3) -> void:
	for h in get_tree().get_group("hunter"):
		if h.has_method("hear_ping"):
			h.hear_ping(position)


func stun_hunter_at(position: Vector3) -> void:
	for h in get_tree().get_group("hunter"):
		if h.has_method("get_stunned") and h.global_position.distance_to(position) < 14.0:
			h.get_stunned()


func set_difficulty(d: String) -> void:
	difficulty = d
	settings.call("set_difficulty", d)


func mark_cleared(level: int) -> void:
	if not cleared_levels.has(level):
		cleared_levels.append(level)
		cleared_levels.sort_custom(func(a, b): return a < b)
	settings.call("mark_cleared", level)


func is_cleared(level: int) -> bool:
	return cleared_levels.has(level)


func _reset_run() -> void:
	alive = true
	won = false
	has_key = false
	has_noise_item = false
	key_required = false
	hunter_suppressed = false
	cooldown_left = 0.0
	cooldown_total = 1.6
	charge = -1.0
	elapsed = 0.0
	tutorial_active = false
	doors.clear()
	get_tree().paused = false


func restart() -> void:
	_reset_run()
	get_tree().reload_current_scene()


func start_level(index: int) -> void:
	current_level = index
	difficulty = "normal"
	if settings.get("difficulty") != null:
		difficulty = String(settings.get("difficulty"))
	_reset_run()
	get_tree().change_scene_to_file("res://scenes/level.tscn")


func go_to_menu(open_select: bool = false) -> void:
	open_level_select = open_select
	_reset_run()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
