extends Node
## Small persistent comfort-settings service.

var mouse_sensitivity := 0.002
var master_volume := 0.8
var fullscreen := false
var scan_key := KEY_E          # remappable scan key (default E)
var difficulty := "normal"     # "easy" = minimap + compass, "normal" = compass, "hard" = nothing
var ui_scale := 1.0            # UI size multiplier (1.0 default, 1.5 bigger)
var cleared_levels := []       # level indices the player has cleared at least once
var best_times := {}           # "level:difficulty" -> seconds
var unlocked_levels := 1

const SETTINGS_PATH := "user://lumen_null_settings.cfg"
const JOY_SCAN_BUTTON := 2     # gamepad X / square button fires the scan


func _ready() -> void:
	_load()
	_apply()


func set_mouse_sensitivity(value: float) -> void:
	mouse_sensitivity = clampf(value, 0.0005, 0.006)
	_save()


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply_volume()
	_save()


func set_fullscreen(value: bool) -> void:
	fullscreen = value
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	)
	_save()


func set_scan_key(value: int) -> void:
	scan_key = value
	_save()


func set_difficulty(value: String) -> void:
	difficulty = value
	_save()


func set_ui_scale(value: float) -> void:
	ui_scale = clampf(value, 0.75, 2.0)
	_save()


func mark_cleared(level: int) -> void:
	if not cleared_levels.has(level):
		cleared_levels.append(level)
		cleared_levels.sort_custom(func(a, b): return a < b)
	unlocked_levels = maxi(unlocked_levels, level + 2)
	_save()


func _apply() -> void:
	_apply_volume()
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	)


func _apply_volume() -> void:
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		AudioServer.set_bus_volume_db(master_bus, linear_to_db(maxf(master_volume, 0.001)))


func _load() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	mouse_sensitivity = float(config.get_value("comfort", "mouse_sensitivity", mouse_sensitivity))
	master_volume = float(config.get_value("comfort", "master_volume", master_volume))
	fullscreen = bool(config.get_value("comfort", "fullscreen", fullscreen))
	scan_key = int(config.get_value("comfort", "scan_key", scan_key))
	difficulty = config.get_value("comfort", "difficulty", difficulty)
	ui_scale = float(config.get_value("comfort", "ui_scale", ui_scale))
	cleared_levels = config.get_value("records", "cleared_levels", [])
	unlocked_levels = int(config.get_value("records", "unlocked_levels", unlocked_levels))
	if config.has_section("records"):
		for key in config.get_section_keys("records"):
			if key == "best_time":
				# Old format: single best time for level 1, migrate to level 0 normal.
				best_times["0:normal"] = float(config.get_value("records", key))
			elif key.begins_with("best_") and key.trim_prefix("best_").is_valid_int():
				# Old format: best time for a level, migrate to normal difficulty.
				best_times[key.trim_prefix("best_") + ":normal"] = float(config.get_value("records", key))
			elif key.begins_with("best_") and key.trim_prefix("best_").find(":") != -1:
				# New format: best_LEVEL:DIFFICULTY
				best_times[key.trim_prefix("best_")] = float(config.get_value("records", key))
	for k in best_times.keys():
		var parts: Array = k.split(":")
		if parts.size() == 2:
			var li := int(parts[0])
			unlocked_levels = maxi(unlocked_levels, li + 2)


func _save() -> void:
	var config := ConfigFile.new()
	config.set_value("comfort", "mouse_sensitivity", mouse_sensitivity)
	config.set_value("comfort", "master_volume", master_volume)
	config.set_value("comfort", "fullscreen", fullscreen)
	config.set_value("comfort", "scan_key", scan_key)
	config.set_value("comfort", "difficulty", difficulty)
	config.set_value("comfort", "ui_scale", ui_scale)
	config.set_value("records", "cleared_levels", cleared_levels)
	config.set_value("records", "unlocked_levels", unlocked_levels)
	for k in best_times.keys():
		config.set_value("records", "best_%s" % k, best_times[k])
	config.save(SETTINGS_PATH)


## Returns true if this run is a new best for the level. Also unlocks the next level.
func record_time(level: int, t: float) -> bool:
	var new_best: bool = (not best_times.has(level)) or t < float(best_times[level])
	if new_best:
		best_times[level] = t
	unlocked_levels = maxi(unlocked_levels, level + 2)
	_save()
	return new_best


func best_time(level: int) -> float:
	return float(best_times.get(level, 0.0))
