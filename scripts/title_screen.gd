extends Control

## Title screen for LUMEN NULL. Start button transitions to the level.

@onready var start_button: Button = $StartButton


func _ready() -> void:
	start_button.grab_focus()
	start_button.pressed.connect(_on_start_pressed)


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/level.tscn")


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			get_tree().quit()
