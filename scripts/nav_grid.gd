extends Node3D
## Walkability grid built from the level's collision on the first physics
## frames. The hunter asks it for paths so it routes around walls instead of
## pushing into them.

const HALF := 18

var astar := AStarGrid2D.new()
var ready_ok := false


func _ready() -> void:
	add_to_group("nav")
	_build.call_deferred()


func _build() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame

	astar.region = Rect2i(-HALF, -HALF, HALF * 2, HALF * 2)
	astar.cell_size = Vector2.ONE
	astar.offset = Vector2(0.5, 0.5)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()

	var shape := SphereShape3D.new()
	shape.radius = 0.35
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 1
	var game := get_node("/root/GameState")
	if game._player != null:
		query.exclude = [(game._player as CollisionObject3D).get_rid()]

	var space := get_world_3d().direct_space_state
	for x in range(-HALF, HALF):
		for z in range(-HALF, HALF):
			query.transform = Transform3D(Basis.IDENTITY, Vector3(x + 0.5, 1.0, z + 0.5))
			if not space.intersect_shape(query, 1).is_empty():
				astar.set_point_solid(Vector2i(x, z), true)
	ready_ok = true


func _cell(v: Vector3) -> Vector2i:
	return Vector2i(clampi(floori(v.x), -HALF, HALF - 1), clampi(floori(v.z), -HALF, HALF - 1))


func _nearest_free(c: Vector2i) -> Vector2i:
	if not astar.is_point_solid(c):
		return c
	for r in range(1, 6):
		for dx in range(-r, r + 1):
			for dz in range(-r, r + 1):
				var n := Vector2i(clampi(c.x + dx, -HALF, HALF - 1), clampi(c.y + dz, -HALF, HALF - 1))
				if not astar.is_point_solid(n):
					return n
	return c


func find_path(from: Vector3, to: Vector3) -> PackedVector3Array:
	if not ready_ok:
		return PackedVector3Array([to])
	var a := _nearest_free(_cell(from))
	var b := _nearest_free(_cell(to))
	var pts := astar.get_point_path(a, b, true)
	var out := PackedVector3Array()
	for i in range(pts.size()):
		out.append(Vector3(pts[i].x, from.y, pts[i].y))
	if out.size() > 0 and not astar.is_point_solid(_cell(to)):
		out[out.size() - 1] = Vector3(to.x, from.y, to.z)
	if out.is_empty():
		out.append(to)
	return out
