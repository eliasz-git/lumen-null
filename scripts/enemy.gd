extends CharacterBody3D
## Hunter enemy. Invisible until pinged. Moves toward your last pulse location.
## If it touches you, you die. It is lidar-reflective so pings do reveal it (red).

@export var move_speed := 2.25
@export var kill_radius := 1.15
@export var reaction_delay := 0.55
@export var search_duration := 2.1

@onready var game: Node = get_node("/root/GameState")
var target := Vector3.ZERO
var has_target := false
var idle := true   # true when the hunter is waiting, it cannot move to idle pose set at spawn/settle
var heartbeat: AudioStreamPlayer
var search_signal: AudioStreamPlayer3D
var reaction_left := 0.0
var search_left := 0.0


func _ready() -> void:
	add_to_group("hunter")
	target = global_position
	_set_busy(true)
	# Heartbeat drone that gets louder as the hunter closes in.
	heartbeat = AudioStreamPlayer.new()
	heartbeat.stream = load("res://sounds/heartbeat.wav")
	heartbeat.autoplay = true
	add_child(heartbeat)
	heartbeat.playing = true
	heartbeat.finished.connect(_loop_heartbeat)
	search_signal = AudioStreamPlayer3D.new()
	search_signal.stream = load("res://sounds/ping.wav")
	search_signal.volume_db = -18.0
	search_signal.pitch_scale = 0.58
	search_signal.max_distance = 18.0
	add_child(search_signal)


func _loop_heartbeat() -> void:
	if heartbeat:
		heartbeat.play()


# Called by spawner when a pulse is heard. Move toward the last ping location.
func hear_ping(at: Vector3) -> void:
	target = at
	has_target = true
	reaction_left = reaction_delay
	search_left = search_duration
	_set_busy(true)
	$PulseLight.light_energy = 2.5
	if search_signal:
		search_signal.play()


func _physics_process(delta: float) -> void:
	$PulseLight.light_energy = move_toward($PulseLight.light_energy, 0.0, delta * 5.0)
	if reaction_left > 0.0:
		reaction_left -= delta
		if reaction_left <= 0.0 and has_target:
			_set_busy(false)
		return
	if idle or not has_target:
		return
	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta

	var to_target: Vector3 = target - global_position
	to_target.y = 0.0
	if to_target.length() > 0.35:
		var dir := to_target.normalized()
		velocity.x = move_toward(velocity.x, dir.x * move_speed, delta * 7.5)
		velocity.z = move_toward(velocity.z, dir.z * move_speed, delta * 7.5)
		move_and_slide()
	else:
		# Reached the last ping. Sit still until the next pulse.
		velocity.x = 0.0
		velocity.z = 0.0
		search_left -= delta
		if search_left <= 0.0:
			has_target = false
			_set_busy(true)

	# Kill check against the player.
	var p: Node3D = game._player
	if is_instance_valid(p) and p:
		var dist: float = global_position.distance_to(p.global_position)
		if heartbeat:
			heartbeat.volume_db = linear_to_db(clampf(1.0 - dist / 12.0, 0.05, 1.0))
			heartbeat.pitch_scale = lerpf(0.82, 1.18, clampf(1.0 - dist / 12.0, 0.0, 1.0))
		if dist < kill_radius:
			game.kill()


func _set_busy(b: bool) -> void:
	idle = b
	$Body.visible = true  # always rendered via reveal shader; visibility here only guards emit
