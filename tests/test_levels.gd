extends SceneTree
## Headless checks for the level data and the level builder.
## Run: godot --headless --path . --script res://tests/test_levels.gd
## Exits with code 1 if any check fails.

const LevelData := preload("res://scripts/level_data.gd")
const SIZE := 36

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_check(LevelData.COUNT == LevelData.LEVELS.size(), "COUNT matches LEVELS.size()")
	for i in range(LevelData.LEVELS.size()):
		_check_data(i, LevelData.LEVELS[i])
	for i in range(LevelData.COUNT):
		await _check_built(i)
	if failures == 0:
		print("ALL LEVEL CHECKS PASSED")
	else:
		printerr("%d LEVEL CHECK(S) FAILED" % failures)
	quit(1 if failures > 0 else 0)


func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + what)


func _check_data(i: int, def: Dictionary) -> void:
	var tag := "level %d" % (i + 1)
	for key in ["name", "tagline", "map", "scan_cooldown", "dot_lifetime", "hunter_speed", "chase_radius", "noise_radius", "hunters"]:
		_check(def.has(key), "%s has key %s" % [tag, key])
	var map: Array = def["map"]
	_check(map.size() == SIZE, "%s has %d rows (got %d)" % [tag, SIZE, map.size()])

	var marks := {}
	for row in range(map.size()):
		var line: String = map[row]
		_check(line.length() == SIZE, "%s row %d is %d chars (got %d)" % [tag, row, SIZE, line.length()])
		for col in range(line.length()):
			var ch := line[col]
			if ch == "#" or ch == ".":
				continue
			_check(not marks.has(ch), "%s marker %s appears once" % [tag, ch])
			marks[ch] = Vector2i(col, row)
			if row == 0 or col == 0 or row == map.size() - 1 or col == line.length() - 1:
				_check(false, "%s marker %s is on the border" % [tag, ch])

	_check(marks.has("P"), "%s has a player start" % tag)
	_check(marks.has("E"), "%s has an exit" % tag)
	if not (marks.has("P") and marks.has("E")):
		return
	var reach := _flood(map, marks["P"])
	_check(reach.has(marks["E"]), "%s exit is reachable from the start" % tag)

	for h in def["hunters"]:
		var spawn: String = h["spawn"]
		_check(marks.has(spawn), "%s hunter spawn %s exists" % [tag, spawn])
		if marks.has(spawn):
			var d := Vector2(marks[spawn] - marks["P"]).length()
			_check(d >= 10.0, "%s hunter %s spawns at least 10 m from the start (%.1f)" % [tag, spawn, d])
		var patrol: String = h["patrol"]
		_check(patrol.length() >= 2, "%s hunter %s has a patrol route" % [tag, spawn])
		for ch in patrol:
			_check(marks.has(ch), "%s waypoint %s exists" % [tag, ch])
			if marks.has(ch):
				_check(reach.has(marks[ch]), "%s waypoint %s is reachable" % [tag, ch])


func _flood(map: Array, start: Vector2i) -> Dictionary:
	var seen := {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var c: Vector2i = queue.pop_front()
		for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var n: Vector2i = c + d
			if n.y < 0 or n.y >= map.size() or n.x < 0 or n.x >= String(map[n.y]).length():
				continue
			if String(map[n.y])[n.x] == "#" or seen.has(n):
				continue
			seen[n] = true
			queue.append(n)
	return seen


func _check_built(i: int) -> void:
	var tag := "built level %d" % (i + 1)
	var game: Node = root.get_node("/root/GameState")
	game.start_level(i)
	for f in range(10):
		await physics_frame
	var level := current_scene
	_check(level != null and level.name == "Level", "%s loads" % tag)
	if level == null:
		return
	var def: Dictionary = LevelData.get_level(i)
	_check(level.get_node("Enemies").get_child_count() == def["hunters"].size(), "%s spawns %d hunter(s)" % [tag, def["hunters"].size()])
	_check(level.get_node("Walls").get_child_count() > 0, "%s builds walls" % tag)
	var nav: Node = level.get_node("NavGrid")
	_check(nav.ready_ok, "%s nav grid is ready" % tag)
	var player: Node3D = level.get_node("Player")
	var exit: Node3D = level.get_node("ExitBeacon")
	var path: PackedVector3Array = nav.find_path(player.global_position, exit.global_position)
	_check(path.size() > 1, "%s hunter pathing finds a route from start to exit" % tag)
	if path.size() > 0:
		var end := path[path.size() - 1]
		_check(Vector2(end.x - exit.position.x, end.z - exit.position.z).length() < 1.0, "%s route ends at the exit" % tag)
	_check(game.alive, "%s player is alive after load" % tag)
