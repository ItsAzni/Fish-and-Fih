extends Resource
class_name AreaData

## Area definition resource for fishing spots

@export var area_name: String = "Pond"
@export_multiline var description: String = "A calm pond with common fish"
@export var fish_pool: FishPoolData
@export var required_rod_level: int = 1
@export var background_texture: Texture2D

# Drop rate modifiers per rarity (from PRD)
# These are used to adjust the weighted spawn in the fish pool
@export_group("Drop Rate Modifiers")
@export_range(0.0, 1.0) var common_rate: float = 0.70
@export_range(0.0, 1.0) var uncommon_rate: float = 0.25
@export_range(0.0, 1.0) var rare_rate: float = 0.05
@export_range(0.0, 1.0) var epic_rate: float = 0.0
@export_range(0.0, 1.0) var legendary_rate: float = 0.0


func is_unlocked() -> bool:
	return SessionManager.rod_level >= required_rod_level


func get_unlock_message() -> String:
	if is_unlocked():
		return "Unlocked"
	return "Requires Rod Lv %d" % required_rod_level


func get_random_fish() -> FishType:
	if fish_pool:
		return fish_pool.get_random_fish()
	return null


func get_info_string() -> String:
	var status = "✅" if is_unlocked() else "🔒"
	return "%s %s (Rod Lv %d)" % [status, area_name, required_rod_level]
