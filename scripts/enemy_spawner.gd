extends Node3D
## Makes every hunter under this node hear every lidar scan.

@onready var game: Node = get_node("/root/GameState")


func _ready() -> void:
	game.ping_fired.connect(_on_ping_fired)


func _on_ping_fired(from: Vector3) -> void:
	if game.hunter_suppressed:
		return
	for h in get_children():
		if is_instance_valid(h) and h.has_method("hear_ping"):
			h.hear_ping(from)
