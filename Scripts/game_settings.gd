extends Node

## GameSettings Autoload - Manages persistent audio and display settings

# Volume settings (0.0 to 1.0)
var master_volume: float = 1.0
var music_volume: float = 1.0
var sfx_volume: float = 1.0

# Display settings
var brightness: float = 1.0

const SETTINGS_PATH = "user://settings.cfg"

func _ready() -> void:
	load_settings()
	apply_audio_settings()

func save_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("display", "brightness", brightness)
	config.save(SETTINGS_PATH)

func load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_PATH)
	if err == OK:
		master_volume = config.get_value("audio", "master_volume", 1.0)
		music_volume = config.get_value("audio", "music_volume", 1.0)
		sfx_volume = config.get_value("audio", "sfx_volume", 1.0)
		brightness = config.get_value("display", "brightness", 1.0)

func apply_audio_settings() -> void:
	# Apply Master volume
	var master_idx = AudioServer.get_bus_index("Master")
	if master_idx >= 0:
		AudioServer.set_bus_volume_db(master_idx, linear_to_db(master_volume))
	
	# Apply Music volume  
	var music_idx = AudioServer.get_bus_index("Music")
	if music_idx >= 0:
		AudioServer.set_bus_volume_db(music_idx, linear_to_db(music_volume))
	
	# Apply SFX volume
	var sfx_idx = AudioServer.get_bus_index("SFX")
	if sfx_idx >= 0:
		AudioServer.set_bus_volume_db(sfx_idx, linear_to_db(sfx_volume))

func set_master_volume(value: float) -> void:
	master_volume = clamp(value, 0.0, 1.0)
	var idx = AudioServer.get_bus_index("Master")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(master_volume))
	save_settings()

func set_music_volume(value: float) -> void:
	music_volume = clamp(value, 0.0, 1.0)
	var idx = AudioServer.get_bus_index("Music")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(music_volume))
	save_settings()

func set_sfx_volume(value: float) -> void:
	sfx_volume = clamp(value, 0.0, 1.0)
	var idx = AudioServer.get_bus_index("SFX")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(sfx_volume))
	save_settings()

func set_brightness(value: float) -> void:
	brightness = clamp(value, 0.2, 1.0)
	save_settings()
