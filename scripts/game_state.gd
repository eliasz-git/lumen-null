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
var cooldown_left := 0.0
var cooldown_total := 1.6

@onready var _player: Node3D


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


func restart() -> void:
	alive = true
	won = false
	hunter_suppressed = false
	cooldown_left = 0.0
	cooldown_total = 1.6
	get_tree().paused = false
	get_tree().reload_current_scene()
