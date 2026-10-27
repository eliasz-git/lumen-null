extends Area3D
## Noise emitter dropped by the player. Makes a loud noise that lures the
## hunter to the drop position, then fades after noise_seconds.

signal noise_made(position: Vector3)

@export var noise_seconds := 4.0
@export var repeat_interval := 1.0

var repeat_left := 0.0

func _ready() -> void:
	repeat_left = repeat_interval
	_make_noise()


func _make_noise() -> void:
	noise_made.emit(global_position)


func _process(delta: float) -> void:
	repeat_left -= delta
	if repeat_left <= 0.0:
		repeat_left = repeat_interval
		_make_noise()


func _physics_process(delta: float) -> void:
	# Auto-remove after the noise duration.
	noise_seconds -= delta
	if noise_seconds <= 0.0:
		queue_free()
