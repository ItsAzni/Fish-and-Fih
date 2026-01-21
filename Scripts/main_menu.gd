extends CanvasLayer

@onready var settings_panel: Panel = $SettingsPanel
@onready var button_manager: Control = $ButtonManager

func _ready() -> void:
	settings_panel.visible = false
	# Initialize sliders with saved values
	$SettingsPanel/CenterContainer/VBoxContainer/MasterSlider.value = GameSettings.master_volume
	$SettingsPanel/CenterContainer/VBoxContainer/MusicSlider.value = GameSettings.music_volume
	$SettingsPanel/CenterContainer/VBoxContainer/SFXSlider.value = GameSettings.sfx_volume
	$SettingsPanel/CenterContainer/VBoxContainer/BrightnessSlider.value = GameSettings.brightness

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/world.tscn")
	
func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_settings_pressed() -> void:
	button_manager.visible = false
	settings_panel.visible = true

func _on_back_pressed() -> void:
	settings_panel.visible = false
	button_manager.visible = true

func _on_master_slider_value_changed(value: float) -> void:
	GameSettings.set_master_volume(value)

func _on_music_slider_value_changed(value: float) -> void:
	GameSettings.set_music_volume(value)

func _on_sfx_slider_value_changed(value: float) -> void:
	GameSettings.set_sfx_volume(value)

func _on_brightness_slider_value_changed(value: float) -> void:
	GameSettings.set_brightness(value)


func _on_reset_data_pressed() -> void:
	SessionManager.reset_player_data()
	print("Player data has been reset!")

