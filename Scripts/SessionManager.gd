extends Node

## SessionManager Autoload - Manages game progress with persistent save

# Signals
signal coins_changed(new_amount: int)
signal bucket_updated()
signal rod_upgraded(new_level: int)
signal area_changed(new_area: String)

# Save file path
const SAVE_PATH = "user://player_data.cfg"

# Runtime data
var coins: int = 0
var rod_level: int = 1
var current_area: String = "Pond"
var bucket: Array[FishInstance] = []

# Constants
const BASE_BUCKET_CAPACITY = 10

# Rod upgrade costs (from PRD)
const ROD_UPGRADE_COSTS = {
	2: 200,
	3: 600,
	4: 1400,
	5: 3000,
	6: 6000
}

# Rod stats per level (from PRD)
const ROD_STATS = {
	1: {"max_safe_weight": 1.5, "luck_bonus": 0.0, "reel_speed": 1.00, "bucket_bonus": 0},
	2: {"max_safe_weight": 2.5, "luck_bonus": 0.01, "reel_speed": 0.95, "bucket_bonus": 2},
	3: {"max_safe_weight": 4.0, "luck_bonus": 0.02, "reel_speed": 0.92, "bucket_bonus": 4},
	4: {"max_safe_weight": 6.5, "luck_bonus": 0.03, "reel_speed": 0.88, "bucket_bonus": 6},
	5: {"max_safe_weight": 9.0, "luck_bonus": 0.04, "reel_speed": 0.85, "bucket_bonus": 8},
	6: {"max_safe_weight": 12.0, "luck_bonus": 0.05, "reel_speed": 0.82, "bucket_bonus": 10}
}

# Area unlock requirements (rod level)
const AREA_REQUIREMENTS = {
	"Pond": 1,
	"River": 3,
	"Sea": 5
}


func _ready() -> void:
	load_data()
	print("SessionManager loaded - Coins: %d, Rod Lv: %d, Area: %s" % [coins, rod_level, current_area])


# ========== SAVE/LOAD ==========

func save_data() -> void:
	var config = ConfigFile.new()
	
	config.set_value("player", "coins", coins)
	config.set_value("player", "rod_level", rod_level)
	config.set_value("player", "current_area", current_area)
	
	# Serialize bucket (fish array)
	var bucket_data: Array = []
	for fish in bucket:
		bucket_data.append(fish.to_dict())
	config.set_value("player", "bucket", bucket_data)
	
	var err = config.save(SAVE_PATH)
	if err == OK:
		print("Player data saved! (Bucket: %d fish)" % bucket.size())
	else:
		push_error("Failed to save player data: %d" % err)


func load_data() -> void:
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)
	
	if err == OK:
		coins = config.get_value("player", "coins", 0)
		rod_level = config.get_value("player", "rod_level", 1)
		current_area = config.get_value("player", "current_area", "Pond")
		
		# Load bucket
		bucket.clear()
		var bucket_data = config.get_value("player", "bucket", [])
		for fish_data in bucket_data:
			var fish = FishInstance.from_dict(fish_data)
			if fish.fish_type != null:
				bucket.append(fish)
		
		print("Player data loaded! (Bucket: %d fish)" % bucket.size())
	else:
		# First time - use defaults
		coins = 0
		rod_level = 1
		current_area = "Pond"
		bucket.clear()
		print("No save file found, starting fresh!")
	
	# Emit signals to update UI
	coins_changed.emit(coins)
	rod_upgraded.emit(rod_level)
	area_changed.emit(current_area)
	bucket_updated.emit()


# ========== BUCKET MANAGEMENT ==========

func get_bucket_capacity() -> int:
	var stats = ROD_STATS.get(rod_level, ROD_STATS[1])
	return BASE_BUCKET_CAPACITY + stats["bucket_bonus"]


func can_add_fish() -> bool:
	return bucket.size() < get_bucket_capacity()


func add_fish(fish_instance: FishInstance) -> bool:
	if not can_add_fish():
		print("Bucket full! Cannot add fish.")
		return false
	
	bucket.append(fish_instance)
	print("Added to bucket: %s ($%d) | Bucket: %d/%d" % [
		fish_instance.get_display_name(), 
		fish_instance.price,
		bucket.size(),
		get_bucket_capacity()
	])
	bucket_updated.emit()
	save_data()
	return true


func remove_fish(fish_instance: FishInstance) -> void:
	var idx = bucket.find(fish_instance)
	if idx >= 0:
		bucket.remove_at(idx)
		bucket_updated.emit()


# ========== SELLING ==========

func sell_fish(fish_instance: FishInstance) -> int:
	var idx = bucket.find(fish_instance)
	if idx < 0:
		return 0
	
	var price = fish_instance.price
	bucket.remove_at(idx)
	add_coins(price)
	
	print("💰 Sold %s for $%d | Total: $%d" % [fish_instance.get_display_name(), price, coins])
	bucket_updated.emit()
	return price


func sell_all() -> int:
	if bucket.is_empty():
		return 0
	
	var total = 0
	for fish in bucket:
		total += fish.price
	
	bucket.clear()
	add_coins(total)
	
	print("💰 Sold all fish for $%d | Total: $%d" % [total, coins])
	bucket_updated.emit()
	return total


func get_bucket_total_value() -> int:
	var total = 0
	for fish in bucket:
		total += fish.price
	return total


# ========== COINS ==========

func add_coins(amount: int) -> void:
	coins += amount
	coins_changed.emit(coins)
	save_data()


func spend_coins(amount: int) -> bool:
	if coins < amount:
		return false
	coins -= amount
	coins_changed.emit(coins)
	save_data()
	return true


# ========== ROD UPGRADE ==========

func get_upgrade_cost() -> int:
	var next_level = rod_level + 1
	return ROD_UPGRADE_COSTS.get(next_level, -1)


func can_upgrade_rod() -> bool:
	var cost = get_upgrade_cost()
	if cost < 0:
		return false  # Max level reached
	return coins >= cost


func upgrade_rod() -> bool:
	if not can_upgrade_rod():
		return false
	
	var cost = get_upgrade_cost()
	spend_coins(cost)
	rod_level += 1
	
	print("Rod upgraded to Lv %d! Cost: $%d" % [rod_level, cost])
	rod_upgraded.emit(rod_level)
	save_data()
	return true


func get_rod_stats() -> Dictionary:
	return ROD_STATS.get(rod_level, ROD_STATS[1])


func get_max_safe_weight() -> float:
	return get_rod_stats()["max_safe_weight"]


func get_luck_bonus() -> float:
	return get_rod_stats()["luck_bonus"]


func get_reel_speed() -> float:
	return get_rod_stats()["reel_speed"]


# ========== AREA ==========

func can_unlock_area(area_name: String) -> bool:
	var required = AREA_REQUIREMENTS.get(area_name, 999)
	return rod_level >= required


func get_unlocked_areas() -> Array[String]:
	var areas: Array[String] = []
	for area in AREA_REQUIREMENTS.keys():
		if can_unlock_area(area):
			areas.append(area)
	return areas


func change_area(area_name: String) -> bool:
	if not can_unlock_area(area_name):
		print("❌ Cannot access %s - Need Rod Lv %d" % [area_name, AREA_REQUIREMENTS[area_name]])
		return false
	
	current_area = area_name
	print("🗺️ Changed area to: %s" % area_name)
	area_changed.emit(current_area)
	return true


# ========== ESCAPE CHANCE (PRD mechanic) ==========

func calculate_escape_chance(fish_weight: float) -> float:
	var max_safe = get_max_safe_weight()
	if fish_weight <= max_safe:
		return 0.0
	
	var over = fish_weight - max_safe
	var escape_chance = clampf(0.05 + over * 0.08, 0.05, 0.55)
	return escape_chance


# ========== DATA RESET ==========

func reset_session() -> void:
	coins = 0
	rod_level = 1
	current_area = "Pond"
	bucket.clear()
	
	print("Session reset!")
	coins_changed.emit(coins)
	rod_upgraded.emit(rod_level)
	area_changed.emit(current_area)
	bucket_updated.emit()


func reset_player_data() -> void:
	# Reset all player data and save
	coins = 0
	rod_level = 1
	current_area = "Pond"
	bucket.clear()
	
	# Delete save file
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	
	# Save fresh data
	save_data()
	
	print("Player data reset!")
	coins_changed.emit(coins)
	rod_upgraded.emit(rod_level)
	area_changed.emit(current_area)
	bucket_updated.emit()
