extends CharacterBody3D
## LUMEN NULL first-person-ish player.
## WASD move, Space jump, E = lidar pulse (cone scan forward).

@export var move_speed := 5.0
@export var sprint_speed := 8.5
@export var jump_velocity := 5.0
@export var mouse_sensitivity := 0.002
@export var min_ray_count := 600
@export var max_ray_count := 1800
@export var max_hold_time := 1.0
@export var scan_cooldown := 1.6

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var pulse_light: OmniLight3D = $Head/Camera3D/PulseLight
@onready var scanner: Node3D = $Head/Camera3D
@onready var game: Node = get_node("/root/GameState")
@onready var settings: Node = get_node("/root/GameSettings")

const NOISE_ITEM := preload("res://scenes/noise_item.tscn")
const NOISE_EMITTER := preload("res://scenes/noise_emitter.tscn")

var gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
var charging := false
var hold_time := 0.0
var cooldown_left := 0.0
var current_cooldown := 1.6
var scan_key: int = KEY_E
var joy_scan_button: int = 2
var has_noise_item := false
var ping_sound: AudioStreamPlayer
var death_sound: AudioStreamPlayer
var pulse_charge_sound: AudioStreamPlayer
var was_ping_ready := true
var step_sound: AudioStreamPlayer
var step_left := 0.0


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	game.register_player(self)
	mouse_sensitivity = float(settings.get("mouse_sensitivity"))
	scan_key = int(settings.get("scan_key"))
	joy_scan_button = 2
	scanner.strong_pulse_at.connect(func(pos): game.stun_hunter_at(pos))
	# Audio: ping on pulse, sting on death.
	ping_sound = AudioStreamPlayer.new()
	ping_sound.stream = load("res://sounds/ping.wav")
	add_child(ping_sound)
	death_sound = AudioStreamPlayer.new()
	death_sound.stream = load("res://sounds/death.wav")
	# Death pauses the tree; a pausable player would be silenced immediately.
	death_sound.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(death_sound)
	pulse_charge_sound = AudioStreamPlayer.new()
	pulse_charge_sound.stream = load("res://sounds/ping.wav")
	pulse_charge_sound.volume_db = -18.0
	add_child(pulse_charge_sound)
	step_sound = AudioStreamPlayer.new()
	step_sound.stream = load("res://sounds/footstep.wav")
	add_child(step_sound)
	get_tree().paused = false


func _process(delta: float) -> void:
	mouse_sensitivity = float(settings.get("mouse_sensitivity"))
	# E released while paused (pause menu, tooltip) never reaches _input: cancel the charge.
	if charging and not Input.is_key_pressed(KEY_E):
		charging = false
		hold_time = 0.0
	if cooldown_left > 0.0:
		cooldown_left -= delta
		game.set_cooldown(cooldown_left, current_cooldown)
	if not was_ping_ready and cooldown_left <= 0.0 and ping_sound and not charging:
		ping_sound.volume_db = -16.0
		ping_sound.pitch_scale = 1.55
		ping_sound.play()
	was_ping_ready = cooldown_left <= 0.0
	game.charge = clampf(hold_time / max_hold_time, 0.0, 1.0) if charging else -1.0
	if charging:
		hold_time += delta
		if pulse_charge_sound and not pulse_charge_sound.playing:
			pulse_charge_sound.play()
		if pulse_charge_sound:
			pulse_charge_sound.pitch_scale = lerpf(0.8, 1.35, clampf(hold_time / max_hold_time, 0.0, 1.0))
	else:
		if pulse_charge_sound and pulse_charge_sound.playing:
			pulse_charge_sound.stop()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clampf(head.rotation.x, -1.5, 1.5)

	if event is InputEventKey and not event.echo:
		if event.keycode == scan_key:
			_handle_scan_input(event.pressed)
	if event is InputEventJoypadButton and event.device == 0:
		if event.button_index == joy_scan_button:
			_handle_scan_input(event.pressed)
	if event is InputEventKey and not event.echo and event.pressed:
		if event.keycode == KEY_V and has_noise_item:
			_drop_noise_item()


func _drop_noise_item() -> void:
	if not has_noise_item:
		return
	var emitter: Node3D = NOISE_EMITTER.instantiate()
	emitter.global_position = global_position
	get_tree().get_first_node_in_group("level").add_child(emitter)
	emitter.connect("noise_made", Callable(game, "hear_noise"))
	has_noise_item = false
	game.set_has_noise_item(false)


func _handle_scan_input(pressed: bool) -> void:
	if pressed:
		if cooldown_left <= 0.0:
			charging = true
			hold_time = 0.0
	else:
		_release_pulse()
		charging = false


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	# Gamepad left stick (joy 0).
	input_dir.x += clampf(Input.get_joy_axis(0, 0), -1.0, 1.0)
	input_dir.y -= clampf(Input.get_joy_axis(0, 1), -1.0, 1.0)
	input_dir = input_dir.clamp(Vector2(-1, -1), Vector2(1, 1))
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
	_footsteps(delta)


func is_noisy() -> bool:
	return is_on_floor() and Vector2(velocity.x, velocity.z).length() > move_speed + 0.5


func _footsteps(delta: float) -> void:
	var speed := Vector2(velocity.x, velocity.z).length()
	if not is_on_floor() or speed < 1.0:
		step_left = 0.0
		return
	step_left -= delta
	if step_left <= 0.0:
		var sprinting := speed > move_speed + 0.5
		step_sound.volume_db = -15.0 if sprinting else -27.0
		step_sound.pitch_scale = randf_range(0.9, 1.1)
		step_sound.play()
		step_left = 0.33 if sprinting else 0.52


func _release_pulse() -> void:
	if not charging or cooldown_left > 0.0:
		return
	var t: float = clampf(hold_time / max_hold_time, 0.0, 1.0)
	scanner.ray_count = int(lerpf(min_ray_count, max_ray_count, t))
	scanner.max_range = lerpf(12.0, 24.0, t)
	scanner.scan(t)
	if ping_sound:
		ping_sound.volume_db = 0.0
		ping_sound.pitch_scale = 1.0
		ping_sound.play()
	# A quick tap recharges faster; a full charge takes the level's whole scan_cooldown.
	current_cooldown = scan_cooldown * lerpf(0.6, 1.0, t)
	cooldown_left = current_cooldown
	game.set_cooldown(cooldown_left, current_cooldown)
	charging = false
	hold_time = 0.0
	# Tell the hunter the player pinged (unless suppressed during tutorial).
	game.ping_fired.emit(camera.global_position)


func play_death_sound() -> void:
	if death_sound:
		death_sound.play()


func visible_cooldown_left() -> float:
	return cooldown_left
