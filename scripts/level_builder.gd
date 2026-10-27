extends Node3D
## Builds the current level from its ASCII map (see level_data.gd): walls,
## player start, exit gate, hunters (with patrol routes), and difficulty.

const LevelData := preload("res://scripts/level_data.gd")
const WALL := preload("res://scenes/wall.tscn")
const HUNTER := preload("res://scenes/enemy.tscn")
const HALF := 18

@onready var game: Node = get_node("/root/GameState")


func _ready() -> void:
	var def: Dictionary = LevelData.get_level(game.current_level)
	game.level_def = def
	var map: Array = def["map"]

	var walls := Node3D.new()
	walls.name = "Walls"
	add_child(walls)
	_build_walls(walls, map)

	var marks := _find_markers(map)
	var player: Node3D = $Player
	player.position = _cell_pos(marks["P"]) + Vector3(0, 0.1, 0)
	$ExitBeacon.position = _cell_pos(marks["E"])
	$WinZone.position = _cell_pos(marks["E"]) + Vector3(0, 1.7, 0)

	var scan_cooldown: float = def["scan_cooldown"]
	player.scan_cooldown = scan_cooldown
	game.cooldown_total = scan_cooldown
	var cam: Camera3D = player.get_node("Head/Camera3D")
	cam.dot_lifetime = def["dot_lifetime"]
	cam.material.set_shader_parameter("lifetime", float(def["dot_lifetime"]))

	for h in def["hunters"]:
		var hunter: CharacterBody3D = HUNTER.instantiate()
		hunter.position = _cell_pos(marks[h["spawn"]]) + Vector3(0, 0.2, 0)
		var pts: Array[Vector3] = []
		for ch in String(h["patrol"]):
			pts.append(_cell_pos(marks[ch]))
		hunter.patrol_points = pts
		hunter.speed_scale = def["hunter_speed"]
		hunter.chase_radius = def["chase_radius"]
		hunter.noise_radius = def["noise_radius"]
		$Enemies.add_child(hunter)


func _cell_pos(cell: Vector2i) -> Vector3:
	return Vector3(cell.x - HALF + 0.5, 0.0, cell.y - HALF + 0.5)


func _find_markers(map: Array) -> Dictionary:
	var marks := {}
	for row in range(map.size()):
		var line: String = map[row]
		for col in range(line.length()):
			var ch := line[col]
			if ch != "#" and ch != ".":
				marks[ch] = Vector2i(col, row)
	return marks


func _build_walls(parent: Node3D, map: Array) -> void:
	# Merge horizontal runs, then stack identical runs vertically.
	var rects: Array = []
	var active := {}
	for row in range(map.size()):
		var line: String = map[row]
		var next_active := {}
		var col := 0
		while col < line.length():
			if line[col] != "#":
				col += 1
				continue
			var start := col
			while col < line.length() and line[col] == "#":
				col += 1
			var key := start * 100 + col
			var rect: Array
			if active.has(key) and active[key][1] == row:
				rect = active[key]
				rect[1] = row + 1
			else:
				rect = [row, row + 1, start, col]
				rects.append(rect)
			next_active[key] = rect
		active = next_active

	for r in rects:
		var wall: Node3D = WALL.instantiate()
		var width: float = r[3] - r[2]
		var depth: float = r[1] - r[0]
		wall.position = Vector3((r[2] + r[3]) * 0.5 - HALF, 0.0, (r[0] + r[1]) * 0.5 - HALF)

		# Scale the shape instead of the node (Godot recommendation; avoids
		# scaling the collision/mesh transforms unevenly).
		var mesh_instance: MeshInstance3D = wall.get_node("Mesh")
		var mesh: BoxMesh = mesh_instance.mesh.duplicate() as BoxMesh
		mesh.size = Vector3(width, 4.0, depth)
		mesh_instance.mesh = mesh

		var collision: CollisionShape3D = wall.get_node("CollisionShape3D")
		var shape: BoxShape3D = collision.shape.duplicate() as BoxShape3D
		shape.size = Vector3(width, 4.0, depth)
		collision.shape = shape

		parent.add_child(wall)
