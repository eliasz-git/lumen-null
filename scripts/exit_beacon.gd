extends Node3D
## The exit gate. It is invisible in the dark and only shows up (cyan) when a
## scan hits it. A faint, directional chime lets you hunt for it by ear.

@onready var game: Node = get_node("/root/GameState")

var chime: AudioStreamPlayer3D
var next_chime := 2.0
var elapsed := 0.0


func _ready() -> void:
	chime = AudioStreamPlayer3D.new()
	chime.stream = load("res://sounds/ping.wav")
	chime.volume_db = -14.0
	chime.pitch_scale = 0.6
	chime.max_distance = 45.0
	chime.unit_size = 7.0
	chime.position = Vector3(0, 1.8, 0)
	add_child(chime)


func _process(delta: float) -> void:
	elapsed += delta
	if elapsed < next_chime:
		return
	var player: Node3D = game._player
	if is_instance_valid(player):
		var d := global_position.distance_to(player.global_position)
		chime.play()
		next_chime = elapsed + clampf(d / 6.0, 1.6, 5.0)
	else:
		next_chime = elapsed + 3.0
