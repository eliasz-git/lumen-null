extends Area3D
## Noise item the player can pick up. Pressing the drop key releases it as a
## NoiseEmitter that lures the hunter to the player's position.

signal picked_up

@onready var game: Node = get_node("/root/GameState")

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		picked_up.emit()
		queue_free()
