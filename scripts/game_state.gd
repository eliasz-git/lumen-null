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

@onready var _player: Node3D


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
	get_tree().paused = true


func _reset_run() -> void:
	alive = true
	won = false
	hunter_suppressed = false
	cooldown_left = 0.0
	cooldown_total = 1.6
	charge = -1.0
	elapsed = 0.0
	tutorial_active = false
	get_tree().paused = false


func restart() -> void:
	_reset_run()
	get_tree().reload_current_scene()


func start_level(index: int) -> void:
	current_level = index
	_reset_run()
	get_tree().change_scene_to_file("res://scenes/level.tscn")


func go_to_menu(open_select: bool = false) -> void:
	open_level_select = open_select
	_reset_run()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
