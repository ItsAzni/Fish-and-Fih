extends Resource
class_name RodType

@export var rod_name: String = "Bamboo Pole"

@export_range(-80.0, 120.0, 1.0) var bar_size_bonus: float = 0.0
@export_range(200.0, 1600.0, 10.0) var bar_accel: float = 1800.0
@export_range(0.0, 1.0, 0.01) var bar_drag: float = 0.10
@export_range(100.0, 800.0, 10.0) var bar_gravity: float = 350.0

@export_range(0.5, 1.5, 0.01) var bite_rate_mult: float = 1.0
@export_range(0.6, 1.4, 0.01) var hook_window_mult: float = 1.0
@export_range(0.7, 1.4, 0.01) var escape_drain_mult: float = 1.0
@export_range(0.8, 1.5, 0.01) var treasure_mult: float = 1.0 

@export_range(0.8, 1.4, 0.01) var hit_freeze_mult: float = 1.0
@export var allow_tackle_slot: bool = false
