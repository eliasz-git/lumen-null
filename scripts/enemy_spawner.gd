extends Node3D
## Spawns hunter enemies and makes each one hear every lidar pulse.
## Place enemies as children (of type CharacterBody3D with enemy.gd).

@onready var game: Node = get_node("/root/GameState")
var hunters: Array = []


func _ready() -> void:
	for child in get_children():
		if child is CharacterBody3D and child.has_method("hear_ping"):
			hunters.append(child)
	game.ping_fired.connect(_on_ping_fired)


func _on_ping_fired(from: Vector3) -> void:
	for h in hunters:
		if is_instance_valid(h):
			h.hear_ping(from)