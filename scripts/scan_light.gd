extends OmniLight3D
## Scan-reactive light: dark until hit by a lidar scan, then brightens and
## fades back out after fade_seconds.

@export var fade_seconds := 5.0
@export var brightness := 2.0

var fade_left := 0.0


func on_scan() -> void:
	light_energy = brightness
	fade_left = fade_seconds


func _process(delta: float) -> void:
	if fade_left > 0.0:
		fade_left -= delta
		light_energy = lerpf(0.0, brightness, fade_left / fade_seconds)
