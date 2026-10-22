extends Node3D
## Global game state: the lidar pulse, enemy targeting, win/lose + restart.

signal player_died
signal player_won
signal ping_fired(from: Vector3)

var ping_origin := Vector3.ZERO
var ping_time := 0.0            # seconds since the last pulse
var ping_radius := 14.0
var ping_cooldown := 1.6
var reveal_duration := 2.2
var last_ping_pos := Vector3.ZERO   # where the enemy was last drawn toward
var can_ping := true
var alive := true
var won := false

@onready var _player: Node3D


func _process(delta: float) -> void:
	if not can_ping:
		ping_cooldown_left -= delta
		if ping_cooldown_left <= 0.0:
			can_ping = true
	ping_time += delta


var ping_cooldown_left := 0.0
var cooldown_total := 0.0


func fire_pulse(from: Vector3, radial: float, cooldown_mult: float = 1.0) -> void:
	if not can_ping or not alive:
		return
	can_ping = false
	ping_cooldown_left = ping_cooldown * cooldown_mult
	cooldown_total = ping_cooldown * cooldown_mult
	ping_origin = from
	last_ping_pos = from
	ping_radius = radial
	ping_time = 0.0
	ping_fired.emit(from)


func register_player(p: Node3D) -> void:
	_player = p


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
	can_ping = true
	ping_cooldown_left = 0.0
	ping_time = 10.0   # > reveal_duration so nothing stays lit from the previous life
	ping_origin = Vector3.ZERO
	get_tree().paused = false
	get_tree().reload_current_scene()