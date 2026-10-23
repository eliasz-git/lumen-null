extends CharacterBody3D
## Hunter enemy. Invisible until pinged. Moves toward your last pulse location.
## If it touches you, you die. It is lidar-reflective so pings do reveal it (red).

@export var move_speed := 2.6
@export var kill_radius := 1.4

@onready var game: Node = get_node("/root/GameState")
var target := Vector3.ZERO
var has_target := false
var idle := true   # true when the hunter is waiting, it cannot move to idle pose set at spawn/settle
var heartbeat: AudioStreamPlayer


func _ready() -> void:
	target = global_position
	_set_busy(true)
	# Heartbeat drone that gets louder as the hunter closes in.
	heartbeat = AudioStreamPlayer.new()
	heartbeat.stream = load("res://sounds/heartbeat.wav")
	heartbeat.autoplay = true
	heartbeat.stream.set_loop(true)
	add_child(heartbeat)
	heartbeat.playing = true


# Called by spawner when a pulse is heard. Move toward the last ping location.
func hear_ping(at: Vector3) -> void:
	target = at
	has_target = true
	_set_busy(false)


func _physics_process(delta: float) -> void:
	if idle or not has_target:
		return
	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta

	var to_target: Vector3 = target - global_position
	to_target.y = 0.0
	if to_target.length() > 0.35:
		var dir := to_target.normalized()
		velocity.x = dir.x * move_speed
		velocity.z = dir.z * move_speed
		move_and_slide()
	else:
		# Reached the last ping. Sit still until the next pulse.
		velocity.x = 0.0
		velocity.z = 0.0
		_set_busy(true)

	# Kill check against the player.
	var p: Node3D = game._player
	if is_instance_valid(p) and p:
		var dist: float = global_position.distance_to(p.global_position)
		if heartbeat:
			heartbeat.volume_db = linear_to_db(clampf(1.0 - dist / 12.0, 0.05, 1.0))
		if dist < kill_radius:
			game.kill()


func _set_busy(b: bool) -> void:
	idle = b
	$Body.visible = true  # always rendered via reveal shader; visibility here only guards emit