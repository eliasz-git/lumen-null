extends CharacterBody3D
## LUMEN NULL first-person-ish player.
## WASD move, Space jump, E = lidar pulse.

@export var move_speed := 5.0
@export var sprint_speed := 8.5
@export var jump_velocity := 5.0
@export var mouse_sensitivity := 0.002
@export var pulse_radius := 14.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var pulse_light: OmniLight3D = $Head/Camera3D/PulseLight
@onready var game: Node = get_node("/root/GameState")

var gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	game.register_player(self)
	# Orient the player with an opening pulse shortly after spawn.
	get_tree().create_timer(0.5).timeout.connect(_auto_scan)


func _auto_scan() -> void:
	if game.can_ping:
		fire_pulse()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clampf(head.rotation.x, -1.5, 1.5)

	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_E:
				fire_pulse()


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


func fire_pulse() -> void:
	game.fire_pulse(global_position, pulse_radius)
	if pulse_light:
		pulse_light.light_energy = 2.0


func visible_ping_cooldown() -> float:
	return game.ping_cooldown_left