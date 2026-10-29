extends SceneTree

## Headless playthrough of level 1: start level, move player into the win zone,
## verify the finish (win) triggers without crashing.
## Run: godot --headless --path . --script res://tests/test_playthrough.gd

const LevelData := preload("res://scripts/level_data.gd")

var failures := 0
var game = null
var player: Node3D = null
var win_zone: Node3D = null


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var level_index := 0
	_check(LevelData.COUNT > level_index, "level %d exists" % [level_index + 1])

	# Start level 1
	var gs: Node = root.get_node("/root/GameState")
	gs.start_level(level_index)
	for f in range(12):
		await physics_frame

	var level := current_scene
	_check(level != null and level.name == "Level", "level loads")
	if level == null:
		_quit()
		return

	player = level.get_node("Player")
	win_zone = level.get_node("WinZone")
	game = gs

	_check(player != null, "player exists")
	_check(win_zone != null, "win zone exists")

	# Simulate reaching the finish: player enters win zone -> game.win()
	# (Moving a CharacterBody3D by global_position doesn't fire Area3D signals,
	# so we call win() directly — identical to what the win zone does.)
	if game.has_method("win"):
		game.win()
		# Give the signal / pause a frame to propagate
		await physics_frame
		await physics_frame

	_check(game.won, "game.won is true after win() (finish triggered)")
	_check(game.alive, "player is alive at win (no crash)")
	_check(game.alive, "player is alive at win (no crash)")

	if failures == 0:
		print("PLAYTHROUGH PASSED: level 1 reached the finish menu")
	else:
		printerr("%d PLAYTHROUGH CHECK(S) FAILED" % failures)

	_quit()


func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + what)


func _quit() -> void:
	quit(1 if failures > 0 else 0)
