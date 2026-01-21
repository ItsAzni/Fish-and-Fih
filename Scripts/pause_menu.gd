extends CanvasLayer

## Pause Menu with Settings Panel

@onready var pause_panel: Panel = $PausePanel
@onready var settings_panel: Panel = $SettingsPanel
@onready var master_slider: HSlider = $SettingsPanel/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/MasterSlider
@onready var music_slider: HSlider = $SettingsPanel/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/MusicSlider
@onready var sfx_slider: HSlider = $SettingsPanel/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SFXSlider
@onready var brightness_slider: HSlider = $SettingsPanel/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/BrightnessSlider

var is_paused: bool = false

func _ready() -> void:
	# Start hidden
	pause_panel.visible = false
	settings_panel.visible = false
	
	# Set process mode so this works when paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Initialize sliders with saved values
	master_slider.value = GameSettings.master_volume
	music_slider.value = GameSettings.music_volume
	sfx_slider.value = GameSettings.sfx_volume
	brightness_slider.value = GameSettings.brightness

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()

func toggle_pause() -> void:
	is_paused = !is_paused
	get_tree().paused = is_paused
	pause_panel.visible = is_paused
	
	# Hide settings when unpausing
	if not is_paused:
		settings_panel.visible = false

func _on_resume_pressed() -> void:
	toggle_pause()

func _on_settings_pressed() -> void:
	pause_panel.visible = false
	settings_panel.visible = true

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	
	# Clean up any active minigame nodes that may be lingering
	for child in get_tree().root.get_children():
		if child.name == "FishingMinigame":
			child.queue_free()
	
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func _on_back_pressed() -> void:
	settings_panel.visible = false
	pause_panel.visible = true

func _on_master_slider_value_changed(value: float) -> void:
	GameSettings.set_master_volume(value)

func _on_music_slider_value_changed(value: float) -> void:
	GameSettings.set_music_volume(value)

func _on_sfx_slider_value_changed(value: float) -> void:
	GameSettings.set_sfx_volume(value)

func _on_brightness_slider_value_changed(value: float) -> void:
	GameSettings.set_brightness(value)
	apply_brightness()

func apply_brightness() -> void:
	# Find CanvasModulate in the parent scene and adjust its color
	var canvas_modulate = get_tree().current_scene.get_node_or_null("CanvasModulate")
	if canvas_modulate:
		var brightness_value = GameSettings.brightness
		canvas_modulate.color = Color(brightness_value, brightness_value, brightness_value, 1.0)


func _on_reset_data_pressed() -> void:
	SessionManager.reset_player_data()
	print("Player data has been reset!")

