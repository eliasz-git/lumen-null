extends CharacterBody3D
## LUMEN NULL first-person-ish player.
## WASD move, Space jump, E = lidar pulse.

@export var move_speed := 5.0
@export var sprint_speed := 8.5
@export var jump_velocity := 5.0
@export var mouse_sensitivity := 0.002
@export var pulse_radius := 14.0
@export var min_pulse_radius := 6.0
@export var max_pulse_radius := 20.0
@export var max_hold_time := 1.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var pulse_light: OmniLight3D = $Head/Camera3D/PulseLight
@onready var game: Node = get_node("/root/GameState")

var gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
var charging := false
var hold_time := 0.0
var ping_sound: AudioStreamPlayer
var death_sound: AudioStreamPlayer


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	game.register_player(self)
	# Audio: ping on pulse, sting on death.
	ping_sound = AudioStreamPlayer.new()
	ping_sound.stream = load("res://sounds/ping.wav")
	add_child(ping_sound)
	death_sound = AudioStreamPlayer.new()
	death_sound.stream = load("res://sounds/death.wav")
	add_child(death_sound)
	get_tree().paused = false


func _auto_scan() -> void:
	if game.can_ping:
		fire_pulse()


func _process(delta: float) -> void:
	if charging:
		hold_time += delta


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clampf(head.rotation.x, -1.5, 1.5)
		event.accept()

	if event is InputEventKey and not event.echo:
		match event.keycode:
			KEY_E:
				if event.pressed:
					charging = true
					hold_time = 0.0
				else:
					_release_pulse()
					charging = false


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * (sprint_speed if Input.is_action_pressed("sprint") else move_speed)
		velocity.z = direction.z * (sprint_speed if Input.is_action_pressed("sprint") else move_speed)
	else:
		velocity.x = move_toward(velocity.x, 0, 6.0)
		velocity.z = move_toward(velocity.z, 0, 6.0)

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Faint camera light so the player can see themselves in the dark (very dim).
	if pulse_light:
		pulse_light.light_energy -= delta * 2.0
		pulse_light.light_energy = maxf(pulse_light.light_energy, 0.0)

	move_and_slide()


func _release_pulse() -> void:
	if not charging:
		return
	var t: float = clampf(hold_time / max_hold_time, 0.0, 1.0)
	var radius: float = lerpf(min_pulse_radius, max_pulse_radius, t)
	var cooldown_mult: float = lerpf(1.0, 2.0, t)
	game.fire_pulse(global_position, radius, cooldown_mult)
	if pulse_light:
		pulse_light.light_energy = 2.0
	charging = false
	hold_time = 0.0


func fire_pulse() -> void:
	game.fire_pulse(global_position, pulse_radius)
	if pulse_light:
		pulse_light.light_energy = 2.0
	if ping_sound:
		ping_sound.play()


func play_death_sound() -> void:
	if death_sound:
		death_sound.play()


func visible_ping_cooldown() -> float:
	return game.ping_cooldown_left