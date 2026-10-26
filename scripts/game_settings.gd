extends Node
## Small persistent comfort-settings service.

var mouse_sensitivity := 0.002
var master_volume := 0.8
var fullscreen := false
var best_times := {}          # level index -> seconds
var unlocked_levels := 1

const SETTINGS_PATH := "user://lumen_null_settings.cfg"


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
	unlocked_levels = int(config.get_value("records", "unlocked_levels", unlocked_levels))
	if config.has_section("records"):
		for key in config.get_section_keys("records"):
			if key == "best_time":
				# Saves from before there were multiple levels: a single best time for level 1.
				best_times[0] = float(config.get_value("records", key))
			elif key.begins_with("best_") and key.trim_prefix("best_").is_valid_int():
				best_times[int(key.trim_prefix("best_"))] = float(config.get_value("records", key))
	for cleared in best_times:
		unlocked_levels = maxi(unlocked_levels, int(cleared) + 2)


func _save() -> void:
	var config := ConfigFile.new()
	config.set_value("comfort", "mouse_sensitivity", mouse_sensitivity)
	config.set_value("comfort", "master_volume", master_volume)
	config.set_value("comfort", "fullscreen", fullscreen)
	config.set_value("records", "unlocked_levels", unlocked_levels)
	for level in best_times:
		config.set_value("records", "best_%d" % level, best_times[level])
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
