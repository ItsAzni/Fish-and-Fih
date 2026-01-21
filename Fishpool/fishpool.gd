# FishPool.gd
extends Resource
class_name FishPoolData

## Resource untuk mengelola kumpulan ikan dengan spawn system sederhana

@export var pool_name: String = "Lake Fish Pool"
@export var pool_description: String = "Ikan-ikan yang hidup di danau tenang"

# Daftar ikan yang tersedia
@export var fish_list: Array[FishType] = []

# Bobot spawn untuk setiap ikan (higher = lebih sering muncul)
@export var spawn_weights: Array[float] = []


## Get random fish berdasarkan weight
func get_random_fish() -> FishType:
	if fish_list.is_empty():
		push_error("FishPool '%s' kosong!" % pool_name)
		return null
	
	# Jika tidak ada weights, gunakan equal chance
	if spawn_weights.is_empty():
		return fish_list[randi() % fish_list.size()]
	
	# Weighted random selection
	var total_weight = 0.0
	for w in spawn_weights:
		total_weight += w
	
	if total_weight <= 0.0:
		return fish_list[randi() % fish_list.size()]
	
	var rand_val = randf() * total_weight
	var cumulative = 0.0
	
	for i in range(fish_list.size()):
		var weight = spawn_weights[i] if i < spawn_weights.size() else 1.0
		cumulative += weight
		if rand_val <= cumulative:
			var selected_fish = fish_list[i]
			print("🎣 Spawned: %s (%.1f%% chance)" % [selected_fish.fish_name, (weight / total_weight) * 100])
			return selected_fish
	
	# Fallback
	return fish_list[0]


## Get info pool untuk debugging
func get_pool_info() -> String:
	var info = "╔═══════════════════════════════════╗\n"
	info += "  %s\n" % pool_name
	info += "  %s\n" % pool_description
	info += "╠═══════════════════════════════════╣\n"
	
	var total_weight = get_total_weight()
	
	for i in range(fish_list.size()):
		if not fish_list[i]:
			continue
			
		var fish = fish_list[i]
		var weight = spawn_weights[i] if i < spawn_weights.size() else 1.0
		var chance = (weight / total_weight) * 100.0 if total_weight > 0 else 0.0
		
		var legendary_mark = " ⭐" if fish.is_legendary else ""
		var rarity = get_fish_rarity(fish)
		
		info += "  %s%s [%s]\n" % [fish.fish_name, legendary_mark, rarity]
		info += "    └─ Chance: %.1f%%\n" % chance
		info += "    └─ Price: $%d\n" % fish.base_price
		info += "    └─ Size: %.1fcm avg\n" % fish.length_avg_cm
		info += "    └─ Difficulty: %.0f%%\n" % (fish.difficulty * 100)
		info += "\n"
	
	info += "╚═══════════════════════════════════╝"
	return info


## Get total weight
func get_total_weight() -> float:
	if spawn_weights.is_empty():
		return float(fish_list.size())
	
	var total = 0.0
	for w in spawn_weights:
		total += w
	return total


## Get rarity tier berdasarkan spawn weight
func get_fish_rarity(fish_type: FishType) -> String:
	var index = fish_list.find(fish_type)
	if index == -1:
		return "Unknown"
	
	if fish_type.is_legendary:
		return "Legendary"
	
	var weight = spawn_weights[index] if index < spawn_weights.size() else 1.0
	var total = get_total_weight()
	var chance = (weight / total) * 100.0
	
	if chance >= 40.0:
		return "Common"
	elif chance >= 20.0:
		return "Uncommon"
	elif chance >= 10.0:
		return "Rare"
	elif chance >= 5.0:
		return "Epic"
	else:
		return "Mythic"


## Get semua ikan dengan rarity tertentu
func get_fish_by_rarity(rarity: String) -> Array[FishType]:
	var result: Array[FishType] = []
	for fish in fish_list:
		if get_fish_rarity(fish) == rarity:
			result.append(fish)
	return result


## Get fish dengan chance tertinggi
func get_most_common_fish() -> FishType:
	if fish_list.is_empty():
		return null
	
	if spawn_weights.is_empty():
		return fish_list[0]
	
	var max_weight = 0.0
	var max_index = 0
	
	for i in range(min(fish_list.size(), spawn_weights.size())):
		if spawn_weights[i] > max_weight:
			max_weight = spawn_weights[i]
			max_index = i
	
	return fish_list[max_index]


## Get fish dengan chance terendah
func get_rarest_fish() -> FishType:
	if fish_list.is_empty():
		return null
	
	if spawn_weights.is_empty():
		return fish_list[fish_list.size() - 1]
	
	var min_weight = INF
	var min_index = 0
	
	for i in range(min(fish_list.size(), spawn_weights.size())):
		if spawn_weights[i] < min_weight:
			min_weight = spawn_weights[i]
			min_index = i
	
	return fish_list[min_index]
