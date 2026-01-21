extends CanvasLayer

## Fishing HUD - displays session info during gameplay

@onready var coins_label: Label = %CoinsLabel
@onready var rod_label: Label = %RodLabel
@onready var area_label: Label = %AreaLabel
@onready var bucket_label: Label = %BucketLabel

func _ready() -> void:
	_update_all()
	
	# Connect to SessionManager signals
	SessionManager.coins_changed.connect(_on_coins_changed)
	SessionManager.rod_upgraded.connect(_on_rod_upgraded)
	SessionManager.area_changed.connect(_on_area_changed)
	SessionManager.bucket_updated.connect(_on_bucket_updated)


func _update_all() -> void:
	_on_coins_changed(SessionManager.coins)
	_on_rod_upgraded(SessionManager.rod_level)
	_on_area_changed(SessionManager.current_area)
	_on_bucket_updated()


func _on_coins_changed(new_amount: int) -> void:
	if is_instance_valid(coins_label):
		coins_label.text = "%d" % new_amount


func _on_rod_upgraded(new_level: int) -> void:
	if is_instance_valid(rod_label):
		var stats = SessionManager.get_rod_stats()
		rod_label.text = "Rod Lv %d | Max: %.1fkg" % [new_level, stats["max_safe_weight"]]


func _on_area_changed(new_area: String) -> void:
	if is_instance_valid(area_label):
		area_label.text = new_area


func _on_bucket_updated() -> void:
	if is_instance_valid(bucket_label):
		var current = SessionManager.bucket.size()
		var capacity = SessionManager.get_bucket_capacity()
		bucket_label.text = "Fish: %d/%d" % [current, capacity]


func _on_shop_button_pressed() -> void:
	var shop = get_tree().current_scene.get_node_or_null("Shop")
	if shop:
		shop.open()
	else:
		push_warning("Shop node not found!")


func show_hud() -> void:
	visible = true


func hide_hud() -> void:
	visible = false
