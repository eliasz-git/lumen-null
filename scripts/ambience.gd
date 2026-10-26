extends Node
## Looping low drone under the whole level. Keeps playing while paused.

var player: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	player = AudioStreamPlayer.new()
	player.stream = load("res://sounds/drone.wav")
	player.volume_db = -17.0
	add_child(player)
	player.finished.connect(player.play)
	player.play()
