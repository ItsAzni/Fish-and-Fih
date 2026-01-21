extends Resource
class_name FishType

# Rarity system from PRD
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }
@export var rarity: Rarity = Rarity.COMMON

@export var fish_name: String = "Carp"
@export_range(0, 10000, 1) var base_price: int = 50
@export var fish_sprite: Texture2D

# SIZE & WEIGHT RANGE (TAMBAHKAN INI) ⭐
@export_range(5.0, 200.0, 0.1) var length_min_cm: float = 25.0
@export_range(5.0, 200.0, 0.1) var length_max_cm: float = 55.0
@export_range(1.0, 200.0, 0.1) var length_avg_cm: float = 40.0

@export_range(0.1, 50.0, 0.1) var weight_min_kg: float = 0.8
@export_range(0.1, 50.0, 0.1) var weight_max_kg: float = 3.5
@export_range(0.1, 50.0, 0.1) var weight_avg_kg: float = 2.0

@export_range(0.2, 3.0, 0.05) var bite_time_avg: float = 1.3
@export_range(0.1, 2.0, 0.05) var bite_time_variance: float = 0.5
@export_range(0.0, 1.0, 0.01) var treasure_chance: float = 0.15
@export_range(0.0, 1.0, 0.01) var difficulty: float = 0.45

enum MovePattern { SMOOTH, DARTY, SINK_RISE, CHAOTIC }
@export var pattern: MovePattern = MovePattern.SMOOTH
@export var tint: Color = Color.WHITE  # TAMBAHKAN INI jika belum ada ⭐
@export var is_legendary: bool = false
