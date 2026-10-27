extends StaticBody3D
## Scan-reactive door: solid until hit by a lidar scan, then opens (disappears)
## so the player can pass.

func on_scan() -> void:
	queue_free()
