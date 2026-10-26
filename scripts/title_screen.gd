extends Control

@onready var tutorial_button: Button = $TutorialButton
@onready var levels_button: Button = $LevelsButton
@onready var settings_button: Button = $SettingsButton
@onready var title_label: Label = $TitleLabel
@onready var tutorial_label: Label = $TutorialLabel
@onready var level_select: Control = $LevelSelect
@onready var settings_panel: Control = $SettingsPanel
@onready var sensitivity: HSlider = $SettingsPanel/Sensitivity
@onready var volume: HSlider = $SettingsPanel/Volume
@onready var fullscreen: CheckButton = $SettingsPanel/Fullscreen
@onready var settings: Node = get_node("/root/GameSettings")


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	tutorial_button.grab_focus()
	tutorial_button.pressed.connect(_start_tutorial)
	levels_button.pressed.connect(_open_levels)
	settings_button.pressed.connect(_open_settings)
	$LevelSelect/Tutorial.pressed.connect(_start_tutorial)
	$LevelSelect/Back.pressed.connect(_close_panels)
	$SettingsPanel/Back.pressed.connect(_close_panels)
	sensitivity.value_changed.connect(_set_sensitivity)
	volume.value_changed.connect(_set_volume)
	fullscreen.toggled.connect(_set_fullscreen)
	sensitivity.value = float(settings.get("mouse_sensitivity"))
	volume.value = float(settings.get("master_volume"))
	fullscreen.button_pressed = bool(settings.get("fullscreen"))


func _start_tutorial() -> void:
	get_tree().change_scene_to_file("res://scenes/level.tscn")


func _open_levels() -> void:
	_set_main_visible(false)
	level_select.visible = true
	$LevelSelect/Tutorial.grab_focus()


func _open_settings() -> void:
	_set_main_visible(false)
	settings_panel.visible = true
	sensitivity.grab_focus()


func _close_panels() -> void:
	level_select.visible = false
	settings_panel.visible = false
	_set_main_visible(true)
	tutorial_button.grab_focus()


func _set_main_visible(value: bool) -> void:
	title_label.visible = value
	tutorial_label.visible = value
	tutorial_button.visible = value
	levels_button.visible = value
	settings_button.visible = value


func _set_sensitivity(value: float) -> void:
	settings.call("set_mouse_sensitivity", value)


func _set_volume(value: float) -> void:
	settings.call("set_master_volume", value)


func _set_fullscreen(value: bool) -> void:
	settings.call("set_fullscreen", value)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if level_select.visible or settings_panel.visible:
			_close_panels()
		else:
			get_tree().quit()
