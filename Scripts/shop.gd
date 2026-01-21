extends CanvasLayer

## Shop UI - Sell fish and upgrade rod

signal shop_closed()

@onready var shop_panel: PanelContainer = %ShopPanel
@onready var tab_container: TabContainer = %TabContainer
@onready var coins_label: Label = %ShopCoinsLabel

# Sell tab
@onready var fish_list: ItemList = %FishList
@onready var sell_all_btn: Button = %SellAllButton
@onready var sell_selected_btn: Button = %SellSelectedButton
@onready var total_value_label: Label = %TotalValueLabel

# Upgrade tab
@onready var rod_info_label: Label = %RodInfoLabel
@onready var upgrade_btn: Button = %UpgradeButton
@onready var upgrade_cost_label: Label = %UpgradeCostLabel

var _selected_indices: Array[int] = []


func _ready() -> void:
	visible = false
	SessionManager.coins_changed.connect(_update_coins)
	SessionManager.bucket_updated.connect(_refresh_fish_list)
	SessionManager.rod_upgraded.connect(_refresh_upgrade_tab)


func open() -> void:
	visible = true
	_update_coins(SessionManager.coins)
	_refresh_fish_list()
	_refresh_upgrade_tab(SessionManager.rod_level)
	get_tree().paused = true


func close() -> void:
	visible = false
	get_tree().paused = false
	shop_closed.emit()


func _update_coins(amount: int) -> void:
	if is_instance_valid(coins_label):
		coins_label.text = "Coins: %d" % amount


# ========== SELL TAB ==========

func _refresh_fish_list() -> void:
	if not is_instance_valid(fish_list):
		return
	
	fish_list.clear()
	_selected_indices.clear()
	
	for fish_instance in SessionManager.bucket:
		var text = "%s [%s] | %.2fkg | %d" % [
			fish_instance.get_display_name(),
			fish_instance.get_rarity_name(),
			fish_instance.weight,
			fish_instance.price
		]
		fish_list.add_item(text)
		
		# Set item color based on rarity
		var idx = fish_list.item_count - 1
		fish_list.set_item_custom_fg_color(idx, fish_instance.get_rarity_color())
	
	_update_total_value()
	_update_sell_buttons()


func _update_total_value() -> void:
	if is_instance_valid(total_value_label):
		var total = SessionManager.get_bucket_total_value()
		total_value_label.text = "Total Value: %d" % total


func _update_sell_buttons() -> void:
	if is_instance_valid(sell_all_btn):
		sell_all_btn.disabled = SessionManager.bucket.is_empty()
	
	if is_instance_valid(sell_selected_btn):
		sell_selected_btn.disabled = _selected_indices.is_empty()


func _on_fish_list_multi_selected(index: int, selected: bool) -> void:
	if selected:
		if index not in _selected_indices:
			_selected_indices.append(index)
	else:
		_selected_indices.erase(index)
	
	_update_sell_buttons()


func _on_sell_all_button_pressed() -> void:
	var total = SessionManager.sell_all()
	print("💰 Shop: Sold all for %d" % total)


func _on_sell_selected_button_pressed() -> void:
	# Sort indices descending to avoid index shifting issues
	_selected_indices.sort()
	_selected_indices.reverse()
	
	var total_sold = 0
	for idx in _selected_indices:
		if idx < SessionManager.bucket.size():
			var fish = SessionManager.bucket[idx]
			total_sold += SessionManager.sell_fish(fish)
	
	print("💰 Shop: Sold selected for %d" % total_sold)
	_selected_indices.clear()


# ========== UPGRADE TAB ==========

func _refresh_upgrade_tab(rod_level: int) -> void:
	if is_instance_valid(rod_info_label):
		var stats = SessionManager.get_rod_stats()
		rod_info_label.text = """Rod Level: %d
Max Safe Weight: %.1f kg
Luck Bonus: +%.0f%%
Reel Speed: %.2fx
Bucket Bonus: +%d slots""" % [
			rod_level,
			stats["max_safe_weight"],
			stats["luck_bonus"] * 100,
			stats["reel_speed"],
			stats["bucket_bonus"]
		]
	
	var next_cost = SessionManager.get_upgrade_cost()
	
	if is_instance_valid(upgrade_cost_label):
		if next_cost < 0:
			upgrade_cost_label.text = "[MAX LEVEL]"
		else:
			upgrade_cost_label.text = "Upgrade Cost: %d" % next_cost
	
	if is_instance_valid(upgrade_btn):
		upgrade_btn.disabled = not SessionManager.can_upgrade_rod()
		if next_cost < 0:
			upgrade_btn.text = "[MAX]"
		else:
			upgrade_btn.text = "Upgrade Rod"


func _on_upgrade_button_pressed() -> void:
	if SessionManager.upgrade_rod():
		print("⬆️ Shop: Rod upgraded!")


# ========== CLOSE ==========

func _on_close_button_pressed() -> void:
	close()


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()
