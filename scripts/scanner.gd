extends Camera3D
## LiDAR scanner. Fires rays in a forward cone and leaves a persistent point
## cloud at every hit (Scanner Sombre style). Dots are stored in a ring buffer.
##
## Scan types:
##   STANDARD - balanced cone scan, default behavior
##   FOCUS    - narrow cone, long range, precise hunter fix, longer cooldown
##   PULSE    - omnidirectional burst, short range, strong alert, fast-fading dots
##   WHISPER  - narrow cone, short range, weak hunter alert, short cooldown

enum ScanType { STANDARD, FOCUS, PULSE, WHISPER }

@export var ray_count := 800
@export var cone_degrees := 30.0
@export var max_range := 22.0
@export var max_points := 40000
@export var dot_lifetime := 6.0
@export var size_variation := Vector2(0.45, 2.0)

## Per-scan-type multipliers
@export var focus_cone := 15.0
@export var focus_range_mult := 1.5
@export var focus_cooldown_mult := 1.3
@export var focus_alert_mult := 1.5
@export var focus_lifetime_mult := 1.3
@export var focus_size_mult := 0.8

@export var pulse_cone := 360.0
@export var pulse_range_mult := 0.55
@export var pulse_cooldown_mult := 1.8
@export var pulse_alert_mult := 2.0
@export var pulse_lifetime_mult := 0.5
@export var pulse_size_mult := 1.3

@export var whisper_cone := 20.0
@export var whisper_range_mult := 0.5
@export var whisper_cooldown_mult := 0.5
@export var whisper_alert_mult := 0.3
@export var whisper_lifetime_mult := 0.8
@export var whisper_size_mult := 0.9

var point_cloud: MultiMeshInstance3D
var multimesh: MultiMesh
var write_index := 0
var filled := 0
var rng := RandomNumberGenerator.new()
var elapsed := 0.0
var material: ShaderMaterial
var exclude_rids: Array[RID] = []
var last_kind_hits := [0, 0, 0]   # world, hunter, exit gate (last scan)
var scanned_cells := {}           # grid cell -> true, for the minimap (normal difficulty)
const MAP_HALF := 18              # level is 36x36, centered at 0

## Current scan type. Player cycles between them.
var scan_type: ScanType = ScanType.STANDARD

signal scan_fired(origin: Vector3, forward: Vector3, hit_count: int)
signal strong_pulse_at(position: Vector3, scan_type: int)


func _ready() -> void:
	add_to_group("scanner")
	rng.randomize()
	var body := get_parent()
	while body != null and not (body is CollisionObject3D):
		body = body.get_parent()
	if body != null:
		exclude_rids.append((body as CollisionObject3D).get_rid())

	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_custom_data = true
	var quad := QuadMesh.new()
	quad.size = Vector2(1.0, 1.0)
	multimesh.mesh = quad
	multimesh.instance_count = max_points
	multimesh.visible_instance_count = 0

	point_cloud = MultiMeshInstance3D.new()
	point_cloud.multimesh = multimesh
	material = preload("res://materials/lidar_points.tres")
	material.set_shader_parameter("lifetime", dot_lifetime)
	point_cloud.material_override = material
	point_cloud.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	point_cloud.custom_aabb = AABB(Vector3(-500, -500, -500), Vector3(1000, 1000, 1000))
	point_cloud.top_level = true
	add_child(point_cloud)
	point_cloud.global_transform = Transform3D.IDENTITY


func _process(delta: float) -> void:
	elapsed += delta
	material.set_shader_parameter("now", elapsed)


## Type-specific scan parameters. Returns [cone_deg, range_mult, cooldown_mult, alert_mult, lifetime_mult, size_mult].
func _type_params(st: ScanType) -> Array[float]:
	match st:
		ScanType.STANDARD:
			return [cone_degrees, 1.0, 1.0, 1.0, 1.0, 1.0]
		ScanType.FOCUS:
			return [focus_cone, focus_range_mult, focus_cooldown_mult, focus_alert_mult, focus_lifetime_mult, focus_size_mult]
		ScanType.PULSE:
			return [pulse_cone, pulse_range_mult, pulse_cooldown_mult, pulse_alert_mult, pulse_lifetime_mult, pulse_size_mult]
		ScanType.WHISPER:
			return [whisper_cone, whisper_range_mult, whisper_cooldown_mult, whisper_alert_mult, whisper_lifetime_mult, whisper_size_mult]
		_:
			return [cone_degrees, 1.0, 1.0, 1.0, 1.0, 1.0]


func scan(charge: float = 1.0, scan_type: ScanType = -1) -> int:
	var st: ScanType = scan_type
	if st < 0:
		st = self.scan_type

	var params := _type_params(st)
	var cone_deg := params[0]
	var range_mult := params[1]
	var cooldown_mult := params[2]
	var alert_mult := params[3]
	var lifetime_mult := params[4]
	var size_mult := params[5]

	var origin := global_position
	var forward := -global_transform.basis.z
	var up := Vector3.UP
	if absf(forward.dot(up)) > 0.95:
		up = Vector3.RIGHT
	var right := forward.cross(up).normalized()
	up = right.cross(forward).normalized()

	var is_pulse := st == ScanType.PULSE
	var cos_max := 1.0
	if not is_pulse:
		var cone_rad := deg_to_rad(cone_deg * 0.5)  # half-angle for the cone math
		cos_max = cos(cone_rad)

	var space := get_world_3d().direct_space_state
	var hits := 0
	var strong_hunter_hit := false
	last_kind_hits = [0, 0, 0]
	var effective_range := max_range * range_mult

	for i in ray_count:
		var dir: Vector3
		if is_pulse:
			# Full sphere: omnidirectional burst
			var z := rng.randf_range(-1.0, 1.0)
			var phi := rng.randf() * TAU
			var r := sqrt(maxf(0.0, 1.0 - z * z))
			dir = Vector3(r * cos(phi), r * sin(phi), z)
		else:
			var cos_theta := 1.0 - rng.randf() * (1.0 - cos_max)
			var sin_theta := sqrt(maxf(0.0, 1.0 - cos_theta * cos_theta))
			var phi := rng.randf() * TAU
			dir = (forward * cos_theta + (right * cos(phi) + up * sin(phi)) * sin_theta).normalized()

		var query := PhysicsRayQueryParameters3D.new()
		query.from = origin
		query.to = origin + dir * effective_range
		query.collision_mask = 7  # world (1) + exit gate (2) + hunter parts (4)
		query.exclude = exclude_rids
		var result := space.intersect_ray(query)
		if result.is_empty():
			continue

		var pos: Vector3 = result.position
		var normal: Vector3 = result.normal
		var dist := origin.distance_to(pos)
		var nd := clampf(dist / effective_range, 0.0, 1.0)
		var kind := 0.0
		var collider: Object = result.collider
		var cell_x := floori(pos.x + MAP_HALF)
		var cell_z := floori(pos.z + MAP_HALF)
		if cell_x >= 0 and cell_x < 36 and cell_z >= 0 and cell_z < 36:
			scanned_cells[Vector2i(cell_x, cell_z)] = true
		if collider is Node:
			if (collider as Node).is_in_group("hunter"):
				kind = 1.0
				if charge >= 0.8:
					strong_hunter_hit = true
			elif (collider as Node).is_in_group("beacon"):
				kind = 2.0
			if (collider as Node).has_method("on_scan"):
				(collider as Node).on_scan()

		_add_dot(pos, normal, dist, nd, kind, 2 if kind == 1.0 else 1, size_mult, lifetime_mult)
		last_kind_hits[int(kind)] += 1
		hits += 1

	multimesh.visible_instance_count = filled
	scan_fired.emit(origin, forward, hits)
	if strong_hunter_hit:
		strong_pulse_at.emit(origin, int(st))
	return hits


## The hunter lights itself up: rays from all around, aimed at random points on
## its body, paint it in red dots (360 degrees, independent of the player's cone).
func paint_hunter(hunter_pos: Vector3, count: int = 90) -> void:
	var space := get_world_3d().direct_space_state
	var origin := global_position
	for i in range(count):
		var yaw := rng.randf() * TAU
		var to := hunter_pos + Vector3(0.0, rng.randf_range(0.05, 1.95), 0.0)
		var from := to + Vector3(cos(yaw), 0.0, sin(yaw)) * 2.5
		var q := PhysicsRayQueryParameters3D.new()
		q.from = from
		q.to = to
		q.collision_mask = 4
		var r := space.intersect_ray(q)
		if r.is_empty():
			continue
		var pos: Vector3 = r.position
		_add_dot(pos, r.normal, origin.distance_to(pos), 0.0, 1.0, 1, 1.0, 1.0)
	multimesh.visible_instance_count = filled


func _add_dot(pos: Vector3, normal: Vector3, dist: float, nd: float, kind: float, copies: int = 1, size_mult: float = 1.0, lifetime_mult: float = 1.0) -> void:
	var base_size := 0.018 + dist * 0.0045
	if kind == 1.0:
		base_size *= 0.6
	base_size *= size_mult
	for c in range(copies):
		var size := base_size * rng.randf_range(size_variation.x, size_variation.y)
		var jitter := Vector3.ZERO
		if c > 0:
			jitter = Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * 0.05
		var xform := Transform3D(Basis.IDENTITY.scaled(Vector3(size, size, size)), pos + normal * 0.04 + jitter)
		multimesh.set_instance_transform(write_index, xform)
		# custom_data: x=normalized distance, y=kind, z=elapsed (dot lifetime), w=lifetime multiplier
		multimesh.set_instance_custom_data(write_index, Color(nd, kind, elapsed, lifetime_mult))
		write_index = (write_index + 1) % max_points
		filled = mini(filled + 1, max_points)


func clear_map() -> void:
	scanned_cells.clear()


func get_scanned_cells() -> Dictionary:
	return scanned_cells


func is_cell_scanned(x: int, z: int) -> bool:
	return scanned_cells.has(Vector2i(x, z))
