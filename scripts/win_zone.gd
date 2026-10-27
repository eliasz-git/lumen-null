extends Area3D
## Win zone. Stepping inside triggers game.win().

@onready var game: Node = get_node("/root/GameState")


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	# Ignore the goal platform's own collider; only the player wins.
	if game._player and body == game._player:
		if game.key_required and not game.has_key:
			return
		game.win()