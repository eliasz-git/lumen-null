extends Node
## Small persistent comfort-settings service.

var mouse_sensitivity := 0.002
var master_volume := 0.8
var fullscreen := false

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


func _save() -> void:
	var config := ConfigFile.new()
	config.set_value("comfort", "mouse_sensitivity", mouse_sensitivity)
	config.set_value("comfort", "master_volume", master_volume)
	config.set_value("comfort", "fullscreen", fullscreen)
	config.save(SETTINGS_PATH)
