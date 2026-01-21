class_name FishInstance
extends RefCounted

## Represents a caught fish instance with calculated stats

var fish_type: FishType
var weight: float  # kg
var size: float    # cm
var rarity: String # C/U/R/E/L
var price: int     # calculated based on PRD formula

# Rarity display names
const RARITY_NAMES = {
	"C": "Common",
	"U": "Uncommon", 
	"R": "Rare",
	"E": "Epic",
	"L": "Legendary"
}

# Base price per kg by rarity (from PRD)
const RARITY_PRICE_PER_KG = {
	"C": 20,
	"U": 45,
	"R": 90,
	"E": 180,
	"L": 400
}

# Rarity colors for UI
const RARITY_COLORS = {
	"C": Color(0.7, 0.7, 0.7),      # Gray
	"U": Color(0.3, 0.8, 0.3),      # Green
	"R": Color(0.3, 0.5, 1.0),      # Blue
	"E": Color(0.8, 0.3, 0.9),      # Purple
	"L": Color(1.0, 0.8, 0.2)       # Gold
}


static func create(fish: FishType, w: float, s: float, r: String) -> FishInstance:
	var instance = FishInstance.new()
	instance.fish_type = fish
	instance.weight = w
	instance.size = s
	instance.rarity = r
	instance.price = instance.calculate_price()
	return instance


func calculate_price() -> int:
	if not fish_type:
		return 0
	
	# Get base price per kg from rarity
	var base_per_kg = RARITY_PRICE_PER_KG.get(rarity, 20)
	
	# Calculate size ratio (0..1)
	var min_w = fish_type.weight_min_kg
	var max_w = fish_type.weight_max_kg
	var size_ratio = 0.5
	if max_w > min_w:
		size_ratio = clampf((weight - min_w) / (max_w - min_w), 0.0, 1.0)
	
	# Size multiplier: 0.85x to 1.30x based on size
	var size_mult = 0.85 + (size_ratio * 0.45)
	
	# Final price = weight * base_per_kg * size_mult
	var final_price = weight * base_per_kg * size_mult
	
	return int(round(final_price))


func get_rarity_name() -> String:
	return RARITY_NAMES.get(rarity, "Unknown")


func get_rarity_color() -> Color:
	return RARITY_COLORS.get(rarity, Color.WHITE)


func get_display_name() -> String:
	if fish_type:
		return fish_type.fish_name
	return "Unknown Fish"


func get_info_string() -> String:
	return "%s | %s | %.2fkg | $%d" % [get_display_name(), get_rarity_name(), weight, price]


# ========== SERIALIZATION ==========

func to_dict() -> Dictionary:
	var fish_path = ""
	if fish_type:
		fish_path = fish_type.resource_path
	
	return {
		"fish_type_path": fish_path,
		"weight": weight,
		"size": size,
		"rarity": rarity,
		"price": price
	}


static func from_dict(data: Dictionary) -> FishInstance:
	var instance = FishInstance.new()
	
	# Load fish type resource
	var fish_path = data.get("fish_type_path", "")
	if fish_path != "" and ResourceLoader.exists(fish_path):
		instance.fish_type = load(fish_path) as FishType
	
	instance.weight = data.get("weight", 0.0)
	instance.size = data.get("size", 0.0)
	instance.rarity = data.get("rarity", "C")
	instance.price = data.get("price", 0)
	
	return instance
