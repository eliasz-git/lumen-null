extends Area3D
## Key pickup. Collecting it unlocks the door to the exit.
signal collected

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		collected.emit()
		queue_free()
