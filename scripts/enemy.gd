extends CharacterBody3D
## The hunter. Patrols the facility, reacts to every scan, investigates where
## it came from (pathfinding around walls), searches, and chases if you get
## close. Sprinting nearby is also audible to it.

enum State { PATROL, REACT, INVESTIGATE, SEARCH, CHASE }

@export var patrol_speed := 1.5
@export var investigate_speed := 3.2
@export var chase_speed := 4.4
@export var kill_radius := 1.1
@export var reaction_delay := 0.6
@export var search_duration := 3.5
@export var chase_radius := 3.4
@export var lose_radius := 9.0
@export var noise_radius := 8.0
@export var noise_cooldown := 2.5
@export var speed_scale := 1.0

var patrol_points: Array[Vector3] = [
	Vector3(-12, 0, 2.5), Vector3(12, 0, 2.5), Vector3(14, 0, -3), Vector3(-12, 0, -3),
]

@onready var game: Node = get_node("/root/GameState")
@onready var model: Node3D = $Model

var state := State.PATROL
var state_time := 0.0
var target := Vector3.ZERO
var path := PackedVector3Array()
var path_i := 0
var path_target := Vector3.ZERO
var path_pending := false   # planned before the nav grid existed; re-plan once ready
var patrol_i := 0
var wait_left := 0.0
var repath_left := 0.0
var noise_left := 0.0
var step_left := 0.0
var glow_pulse := 0.0
var glow_left := 0.0   # while > 0, keep painting itself in dots
var gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))

var heartbeat: AudioStreamPlayer
var step_sound: AudioStreamPlayer3D
var alert_sound: AudioStreamPlayer3D


func _ready() -> void:
	add_to_group("hunter")
	heartbeat = AudioStreamPlayer.new()
	heartbeat.stream = load("res://sounds/heartbeat.wav")
	heartbeat.volume_db = -40.0
	add_child(heartbeat)
	heartbeat.finished.connect(heartbeat.play)
	heartbeat.play()

	step_sound = AudioStreamPlayer3D.new()
	step_sound.stream = load("res://sounds/footstep_hunter.wav")
	step_sound.volume_db = 7.0
	step_sound.max_distance = 30.0
	step_sound.unit_size = 5.0
	add_child(step_sound)

	alert_sound = AudioStreamPlayer3D.new()
	alert_sound.stream = load("res://sounds/alert.wav")
	alert_sound.volume_db = -2.0
	alert_sound.max_distance = 40.0
	alert_sound.unit_size = 8.0
	add_child(alert_sound)

	patrol_speed *= speed_scale
	investigate_speed *= speed_scale
	chase_speed *= speed_scale
	patrol_i = _nearest_patrol()


func hear_ping(at: Vector3) -> void:
	if state == State.CHASE:
		return
	target = at
	state = State.REACT
	state_time = reaction_delay
	_light_up(1.4)
	alert_sound.play()


func _light_up(seconds: float) -> void:
	glow_left = maxf(glow_left, seconds)
	var scanner := get_tree().get_first_node_in_group("scanner")
	if scanner != null:
		scanner.paint_hunter(global_position, 150)


func _physics_process(delta: float) -> void:
	if glow_left > 0.0:
		glow_left -= delta
		glow_pulse -= delta
		if glow_pulse <= 0.0:
			glow_pulse = 0.22
			var scanner := get_tree().get_first_node_in_group("scanner")
			if scanner != null:
				scanner.paint_hunter(global_position, 45)
	if path_pending:
		_set_path(path_target)
	if not is_on_floor():
		velocity.y -= gravity * delta

	var player: Node3D = game._player
	var has_player := is_instance_valid(player)
	var dist := 999.0
	if has_player:
		dist = global_position.distance_to(player.global_position)
		heartbeat.volume_db = linear_to_db(clampf(1.0 - dist / 14.0, 0.02, 1.0)) - 6.0
		heartbeat.pitch_scale = lerpf(0.85, 1.25, clampf(1.0 - dist / 14.0, 0.0, 1.0))

	if game.hunter_suppressed or not game.alive:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		model.animate(0.0, delta)
		return

	noise_left -= delta
	if has_player:
		_sense_player(player, dist)

	var speed := 0.0
	match state:
		State.PATROL:
			speed = patrol_speed
			if _follow_path(speed, delta):
				wait_left -= delta
				if wait_left <= 0.0:
					patrol_i = (patrol_i + 1) % patrol_points.size()
					_set_path(patrol_points[patrol_i])
					wait_left = 1.6
		State.REACT:
			_stop(delta)
			state_time -= delta
			if state_time <= 0.0:
				state = State.INVESTIGATE
				_set_path(target)
		State.INVESTIGATE:
			speed = investigate_speed
			if _follow_path(speed, delta):
				state = State.SEARCH
				state_time = search_duration
		State.SEARCH:
			_stop(delta)
			state_time -= delta
			rotation.y += sin(state_time * 2.2) * delta * 1.6
			if state_time <= 0.0:
				state = State.PATROL
				patrol_i = _nearest_patrol()
				_set_path(patrol_points[patrol_i])
		State.CHASE:
			speed = chase_speed
			repath_left -= delta
			if has_player and repath_left <= 0.0:
				target = player.global_position
				_set_path(target)
				repath_left = 0.3
			_follow_path(speed, delta)
			if dist > lose_radius:
				state = State.INVESTIGATE
				_set_path(target)

	move_and_slide()

	var horizontal := Vector2(velocity.x, velocity.z)
	if horizontal.length() > 0.2:
		var yaw := atan2(-velocity.x, -velocity.z)
		rotation.y = lerp_angle(rotation.y, yaw, clampf(delta * 8.0, 0.0, 1.0))
	model.animate(horizontal.length(), delta)
	_footsteps(horizontal.length(), delta)

	if has_player and dist < kill_radius:
		game.kill()


func _sense_player(player: Node3D, dist: float) -> void:
	if state != State.CHASE and dist < chase_radius and _has_line_of_sight(player):
		state = State.CHASE
		repath_left = 0.0
		alert_sound.play()
		_light_up(3.0)
		return
	if noise_left <= 0.0 and dist < noise_radius and player.has_method("is_noisy") and player.is_noisy():
		if state == State.PATROL or state == State.SEARCH:
			noise_left = noise_cooldown
			hear_ping(player.global_position)


func _has_line_of_sight(player: Node3D) -> bool:
	var q := PhysicsRayQueryParameters3D.new()
	q.from = global_position + Vector3(0, 1.5, 0)
	q.to = player.global_position + Vector3(0, 1.2, 0)
	q.collision_mask = 1
	q.exclude = [(player as CollisionObject3D).get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()


func _set_path(to: Vector3) -> void:
	path_target = to
	var nav := get_tree().get_first_node_in_group("nav")
	if nav != null and nav.ready_ok:
		path = nav.find_path(global_position, to)
		path_pending = false
	else:
		path = PackedVector3Array([to])
		path_pending = true
	path_i = 0


func _follow_path(speed: float, delta: float) -> bool:
	while path_i < path.size() and Vector2(global_position.x - path[path_i].x, global_position.z - path[path_i].z).length() < 0.45:
		path_i += 1
	if path_i >= path.size():
		_stop(delta)
		return true
	var to := path[path_i] - global_position
	to.y = 0.0
	var dir := to.normalized()
	velocity.x = move_toward(velocity.x, dir.x * speed, delta * 14.0)
	velocity.z = move_toward(velocity.z, dir.z * speed, delta * 14.0)
	return false


func _stop(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, delta * 20.0)
	velocity.z = move_toward(velocity.z, 0.0, delta * 20.0)


func _nearest_patrol() -> int:
	var best := 0
	var best_d := INF
	for i in range(patrol_points.size()):
		var d := global_position.distance_to(patrol_points[i])
		if d < best_d:
			best_d = d
			best = i
	return best


func _footsteps(speed: float, delta: float) -> void:
	if speed < 0.6 or not is_on_floor():
		step_left = 0.0
		return
	step_left -= delta
	if step_left <= 0.0:
		step_sound.pitch_scale = randf_range(0.85, 1.1)
		step_sound.play()
		step_left = clampf(1.5 / maxf(speed, 0.1) * 0.55, 0.28, 0.9)
