extends Node3D
## A faintly visible destination signal that becomes stronger as the player nears it.

@onready var game: Node = get_node("/root/GameState")
@onready var light: OmniLight3D = $GuidanceLight

var elapsed := 0.0
var beacon_sound: AudioStreamPlayer3D
var next_chime := 0.0


func _ready() -> void:
	beacon_sound = AudioStreamPlayer3D.new()
	beacon_sound.stream = load("res://sounds/ping.wav")
	beacon_sound.volume_db = -24.0
	beacon_sound.pitch_scale = 0.72
	beacon_sound.max_distance = 20.0
	add_child(beacon_sound)


func _process(delta: float) -> void:
	elapsed += delta
	var pulse := (sin(elapsed * 2.4) + 1.0) * 0.5
	var energy := lerpf(0.24, 0.82, pulse)
	var player: Node3D = game._player
	if is_instance_valid(player):
		var distance := global_position.distance_to(player.global_position)
		energy *= clampf(1.35 - distance / 26.0, 0.28, 1.0)
		if elapsed >= next_chime and distance < 16.0:
			beacon_sound.play()
			next_chime = elapsed + 4.0
	light.light_energy = energy
