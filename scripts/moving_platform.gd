extends AnimatableBody3D

## Moving platform that slides back and forth. Player can stand on it and be carried.

@export var move_distance := 4.0
@export var move_speed := 2.0

var start_pos: Vector3
var end_pos: Vector3


func _ready() -> void:
	start_pos = global_position
	end_pos = start_pos + Vector3(0, 0, move_distance)
	var duration: float = move_distance / move_speed
	var tween = create_tween()
	tween.tween_property(self, "global_position:z", end_pos.z, duration)
	tween.tween_property(self, "global_position:z", start_pos.z, duration)
	tween.set_loops(-1)
	tween.play()
