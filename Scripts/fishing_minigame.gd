extends CanvasLayer

signal fishing_finished(success, fish, value)
signal bucket_full(fish_instance)
signal play_end_animation() # ⭐ New: trigger player end_fih animation early

@export var fish: FishType
@export var rod: RodType

@onready var root_ui: Control = %background
@onready var catch_area: Control = %fishminigame
@onready var bar_track: TextureRect = %fishbar
@onready var catch_bar: PanelContainer = %inbox
@onready var fish_icon: TextureRect = %fish
@onready var progress: Control = %ProgressBar
@onready var result_panel: PanelContainer = %ResultPanel

# ⭐ AUDIO PLAYERS
@onready var minigame_sound: AudioStreamPlayer = $MinigameSound
@onready var reeling_sound: AudioStreamPlayer = $ReelingSound
@onready var dereel_sound: AudioStreamPlayer = $DereelSound
@onready var reward_sound: AudioStreamPlayer = $RewardSound
@onready var line_break_sound: AudioStreamPlayer = $LineBreakSound

const BASE_BAR_HEIGHT := 20.0
const BASE_ESCAPE_DRAIN := 30.0
const PROGRESS_GAIN := 1000.0
const TREASURE_FILL_RATE := 55.0
const TREASURE_NEED := 50
const FISH_FLIP_THRESHOLD := 0.03

enum STATE {HIDDEN, READY, PLAYING, END}

var _state: STATE = STATE.HIDDEN
var _elapsed: float = 0.0
var _duration: float = 0.0
var _ready_timer: float = 0.0
var _bar_h: float
var _bar_pos: float = 0.0
var _bar_vel: float = 0.0
var _fish_pos: float = 0.5
var _fish_vel: float = 0.0
var _progress_val: float = 0.0
var _treasure_active: bool = false
var _treasure_val: float = 0.0
var _fish_seed: float
var _fish_size: float = 0.0
var _fish_weight: float = 0.0
var _is_reeling: bool = false # ⭐ Track reeling state untuk sound


func _ready():
	root_ui.visible = false
	set_process(false)
	set_physics_process(false)

	print("DEBUG: bar_track =", bar_track, " catch_bar =", catch_bar)
	
	if not fish or not rod:
		push_warning("FishingMinigame requires fish & rod resources.")
		return


func _update_fish_visual():
	if not is_instance_valid(fish_icon) or not is_instance_valid(bar_track):
		return
		
	var min_x := 0.0
	var max_x := bar_track.size.x - fish_icon.size.x

	var x: float = lerp(min_x, max_x, _fish_pos)
	fish_icon.position.x = x
	_fish_pos = clamp(_fish_pos, 0.0, 1.0)


func _reset_game():
	_elapsed = 0
	_duration = 0
	_progress_val = 20.0
	_bar_pos = 0.5
	_bar_vel = 0
	_fish_pos = 0.5
	_fish_vel = 0
	_fish_seed = randf() * 1000
	
	print("🔄 RESET GAME - Fish vel:", _fish_vel, " Fish pos:", _fish_pos)
	
	if is_instance_valid(progress):
		progress.value = _progress_val

	_set_defaults()


func start_minigame():
	if not fish or not rod:
		push_error("Cannot start minigame without fish and rod!")
		return
	
	# Hide HUD during minigame
	var hud = get_tree().current_scene.get_node_or_null("HUD")
	if hud and hud.has_method("hide_hud"):
		hud.hide_hud()
	
	root_ui.visible = true
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	_reset_game()
	_state = STATE.READY
	_ready_timer = 1.0
	set_process(true)
	set_physics_process(true)
	
	if is_instance_valid(minigame_sound):
		minigame_sound.play()
	
	print("Minigame started!")


func _update_input_bar(delta: float):
	# ⭐ ORIGINAL MECHANIC: Press untuk gerak ke kanan, lepas untuk stop/drift
	var right := Input.is_action_pressed("ui_accept") or Input.is_action_pressed("attack")

	var dir := 1.0 if right else -1.0
	
	_bar_vel += dir * rod.bar_accel * delta
	_bar_vel -= _bar_vel * rod.bar_drag * delta
	_bar_vel -= rod.bar_gravity * delta

	var tw := _track_width()
	if tw <= 0.0:
		tw = 1.0

	_bar_pos += _bar_vel * delta / tw
	_bar_pos = clamp(_bar_pos, 0.0, 1.0)
	
	# Bounce di tepi
	if _bar_pos <= 0.0 and _bar_vel < 0.0:
		_bar_vel *= -0.5
	if _bar_pos >= 1.0 and _bar_vel > 0.0:
		_bar_vel *= -0.5
	
	_set_catch_bar_visual()


func _update_fish_direction():
	if not is_instance_valid(fish_icon):
		return
	if abs(_fish_vel) < FISH_FLIP_THRESHOLD:
		return
	fish_icon.flip_h = _fish_vel > 0


func _update_fish_motion(delta: float):
	if not fish:
		return
		
	var d := fish.difficulty
	match fish.pattern:
		fish.MovePattern.SMOOTH:
			var t = _elapsed + _fish_seed
			var target = 0.5 + 0.45 * sin(t * 1.8) + 0.25 * sin(t * 3.5 + 1.3)
			_fish_vel += (target - _fish_pos) * (3.5 + 3.0 * d)
			_fish_vel *= 0.78 - 0.25 * d
		fish.MovePattern.DARTY:
			if randi() % 8 == 0:
				_fish_vel = randf_range(-3.5 - 3.5 * d, 3.5 + 3.5 * d)
			_fish_vel *= 0.82 - 0.28 * d
		fish.MovePattern.SINK_RISE:
			var t2 = _elapsed * (1.2 + d * 1.5)
			var target2 = 0.5 + 0.55 * sin(t2)
			_fish_vel += (target2 - _fish_pos) * (2.5 + 2.0 * d)
			_fish_vel += 1.2 * sin(t2 * 3.5) * d
			_fish_vel *= 0.85
		fish.MovePattern.CHAOTIC:
			var t3 = _elapsed * 2.5
			_fish_vel += randf_range(-1.5, 1.5) * (2.0 + 3.5 * d)
			_fish_vel += 1.5 * sin(t3 * 4.0) * d
			_fish_vel *= 0.75 - 0.15 * d
	
	_fish_pos += _fish_vel * delta
	_fish_pos = clamp(_fish_pos, 0.0, 1.0)

	_set_fish_visual()
	_update_fish_direction()


func _physics_process(delta: float):
	_elapsed += delta
	_duration += delta

	match _state:
		STATE.READY:
			# ⭐ Delay 1 detik - BAR dan IKAN sama-sama freeze
			_ready_timer -= delta
			
			# ⭐ TIDAK update input bar selama READY
			# Bar dan ikan keduanya diam
			
			if _ready_timer <= 0.0:
				_state = STATE.PLAYING
				print("🚀 GO! Start fishing!")
				_shake(3.0, 0.1)
				_punch_ui(fish_icon, 1.2, 0.15)

		STATE.PLAYING:
			_update_input_bar(delta)
			_update_fish_motion(delta) # ⭐ Ikan bergerak di PLAYING
			_handle_collisions(delta)
			_update_progress_ui()

			if _progress_val >= 100.0:
				_success()
			elif _progress_val <= 0.0:
				_fail("Escaped")

		STATE.END:
			pass


func _fail(_why: String):
	if _state == STATE.END:
		return
		
	_state = STATE.END
	print("❌ Fail: " + _why)
	
	# ⭐ Stop all sounds dan play line break
	_stop_all_sounds()
	if is_instance_valid(line_break_sound):
		line_break_sound.play()

	await get_tree().create_timer(1.5).timeout

	if is_instance_valid(line_break_sound):
		line_break_sound.stop()
	
	_shake(5.0, 0.20)
	
	set_process(false)
	set_physics_process(false)
	
	await get_tree().create_timer(0.3).timeout
	
	# Show HUD after minigame ends
	var hud = get_tree().current_scene.get_node_or_null("HUD")
	if hud and hud.has_method("show_hud"):
		hud.show_hud()
	
	emit_signal("fishing_finished", false, fish, 0)


func _success():
	if _state == STATE.END:
		return
		
	_state = STATE.END
	print("✅ Success!")
	
	# ⭐ Stop all sounds dan play reward
	_stop_all_sounds()
	if is_instance_valid(reward_sound):
		reward_sound.play()
	
	set_process(false)
	set_physics_process(false)
	
	_fish_size = _generate_fish_size()
	_fish_weight = _generate_fish_weight()
	
	var fish_value = _calculate_fish_value()
	var rarity_str = _get_rarity_string()
	print("🐟 Caught: %s [%s] | %.1fcm | %.2fkg | $%d" % [fish.fish_name, rarity_str, _fish_size, _fish_weight, fish_value])
	
	# Create FishInstance and add to SessionManager bucket
	var fish_instance = FishInstance.create(fish, _fish_weight, _fish_size, rarity_str)
	if SessionManager.can_add_fish():
		SessionManager.add_fish(fish_instance)
	else:
		bucket_full.emit(fish_instance)
		print("⚠️ Bucket full! Fish not added.")
	
	# ⭐ STEP 1: Hide minigame UI elements with fade
	var ui_elements = [bar_track, catch_bar, fish_icon, progress]
	for element in ui_elements:
		if is_instance_valid(element):
			var tween_hide = create_tween()
			tween_hide.tween_property(element, "modulate:a", 0.0, 0.3)
	
	await get_tree().create_timer(0.3).timeout
	
	# ⭐ STEP 2: Emit signal for player to play end_fih animation
	print("🎬 Signaling player to play end_fih animation...")
	play_end_animation.emit()
	
	# ⭐ STEP 3: Wait for end_fih animation to complete (6 frames at 5fps = 1.2s + buffer)
	print("🎬 Waiting for end_fih animation...")
	await get_tree().create_timer(1.5).timeout
	
	# ⭐ STEP 4: NOW show result panel with bounce
	if is_instance_valid(result_panel):
		result_panel.modulate.a = 0.0
		result_panel.scale = Vector2(0.5, 0.5)
		result_panel.show()
		
		var tween_panel = create_tween().set_parallel(true)
		tween_panel.tween_property(result_panel, "modulate:a", 1.0, 0.4)
		tween_panel.tween_property(result_panel, "scale", Vector2(1.1, 1.1), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween_panel.tween_property(result_panel, "scale", Vector2.ONE, 0.15).set_delay(0.3)
	
	_shake(8.0, 0.2)
	
	await get_tree().create_timer(0.2).timeout
	
	# ⭐ Get new Pixel Worlds-style UI elements
	var fish_name_label = result_panel.get_node_or_null("MainVBox/ContentMargin/ContentVBox/FishNameBadge/FishNameLabel")
	var caught_fish_img = result_panel.get_node_or_null("MainVBox/ContentMargin/ContentVBox/FishImageContainer/CenterContainer/CaughtFishImage")
	var weight_label = result_panel.get_node_or_null("MainVBox/ContentMargin/ContentVBox/StatsRow/WeightLabel")
	var value_label = result_panel.get_node_or_null("MainVBox/ContentMargin/ContentVBox/StatsRow/ValueLabel")
	var take_fish_btn = result_panel.get_node_or_null("MainVBox/ContentMargin/ContentVBox/TakeFishButton")
	
	# ⭐ Get rarity string for fish name display
	var rarity_display = ""
	match rarity_str:
		"C":
			rarity_display = "Common"
		"U":
			rarity_display = "Uncommon"
		"R":
			rarity_display = "Rare"
		"E":
			rarity_display = "Epic"
		"L":
			rarity_display = "Legendary"
	
	# ⭐ Update fish name (without rarity)
	if is_instance_valid(fish_name_label):
		fish_name_label.text = fish.fish_name
	
	# ⭐ Setup fish image with bounce animation
	if is_instance_valid(caught_fish_img):
		var fish_texture: Texture2D = null
		if fish:
			var sprite = fish.get("fish_sprite")
			if sprite != null and sprite is Texture2D:
				fish_texture = sprite
		if fish_texture == null and is_instance_valid(fish_icon):
			fish_texture = fish_icon.texture
		
		if fish_texture:
			caught_fish_img.texture = fish_texture
			caught_fish_img.modulate.a = 0.0
			caught_fish_img.scale = Vector2(0.3, 0.3)
			
			var tween_fish = create_tween().set_parallel(true)
			tween_fish.tween_property(caught_fish_img, "modulate:a", 1.0, 0.4)
			tween_fish.tween_property(caught_fish_img, "scale", Vector2(1.2, 1.2), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween_fish.tween_property(caught_fish_img, "scale", Vector2.ONE, 0.1).set_delay(0.35)
	
	await get_tree().create_timer(0.15).timeout
	
	# ⭐ Update weight
	if is_instance_valid(weight_label):
		weight_label.text = "%.2f kg" % _fish_weight
	
	# ⭐ Animate value with counter effect (using C for coins)
	if is_instance_valid(value_label):
		value_label.text = "+0 C"
		var target_value = fish_value
		var tween_value = create_tween()
		tween_value.tween_method(func(val): value_label.text = "+%d C" % int(val), 0.0, float(target_value), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# ⭐ WAIT FOR "Take Fish" BUTTON CLICK
	print("📋 Waiting for Take Fish button click...")
	await _wait_for_tap()
	print("👆 Tap received! Closing result...")
	
	# ⭐ Fade out with scale down
	var tween_out = create_tween().set_parallel(true)
	
	if is_instance_valid(result_panel):
		tween_out.tween_property(result_panel, "modulate:a", 0.0, 0.3)
		tween_out.tween_property(result_panel, "scale", Vector2(0.8, 0.8), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	
	await tween_out.finished
	
	# Hide result panel
	if is_instance_valid(result_panel):
		result_panel.hide()
	
	# Hide root UI
	if is_instance_valid(root_ui):
		var tween_root = create_tween()
		tween_root.tween_property(root_ui, "modulate:a", 0.0, 0.2)
		await tween_root.finished
		root_ui.visible = false
		root_ui.modulate.a = 1.0
	
	# Show HUD after minigame ends
	var hud = get_tree().current_scene.get_node_or_null("HUD")
	if hud and hud.has_method("show_hud"):
		hud.show_hud()
	
	emit_signal("fishing_finished", true, fish, fish_value)


func _wait_for_tap() -> void:
	# Wait for any tap/click/key press
	while true:
		await get_tree().process_frame
		if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("attack") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			break


func _start_tap_hint_pulse(hint_label: Label) -> void:
	if not is_instance_valid(hint_label):
		return
	var tween = create_tween().set_loops()
	tween.tween_property(hint_label, "modulate:a", 0.4, 0.6)
	tween.tween_property(hint_label, "modulate:a", 1.0, 0.6)


func _generate_fish_size() -> float:
	if not fish:
		return 0.0
	
	var avg = fish.length_avg_cm
	var min_val = fish.length_min_cm
	var max_val = fish.length_max_cm
	
	var rand1 = randf_range(min_val, max_val)
	var rand2 = randf_range(min_val, max_val)
	var result = (rand1 + rand2 + avg) / 3.0
	
	return clamp(result, min_val, max_val)


func _generate_fish_weight() -> float:
	if not fish:
		return 0.0
	
	var size_ratio = _fish_size / fish.length_avg_cm
	var base_weight = fish.weight_avg_kg * size_ratio
	var variation = randf_range(0.8, 1.2)
	var result = base_weight * variation
	
	return clamp(result, fish.weight_min_kg, fish.weight_max_kg)


func _calculate_fish_value() -> int:
	if not fish:
		return 0
		
	if _fish_size <= 0 or _fish_weight <= 0:
		return 20 # Default minimum
	
	# Use same formula as FishInstance.calculate_price() for consistency
	# Base price per kg by rarity (from PRD)
	var rarity_price_per_kg = {
		"C": 20,
		"U": 45,
		"R": 90,
		"E": 180,
		"L": 400
	}
	
	var rarity_str = _get_rarity_string()
	var base_per_kg = rarity_price_per_kg.get(rarity_str, 20)
	
	# Calculate size ratio (0..1) based on weight range
	var min_w = fish.weight_min_kg
	var max_w = fish.weight_max_kg
	var size_ratio = 0.5
	if max_w > min_w:
		size_ratio = clampf((_fish_weight - min_w) / (max_w - min_w), 0.0, 1.0)
	
	# Size multiplier: 0.85x to 1.30x based on size
	var size_mult = 0.85 + (size_ratio * 0.45)
	
	# Final price = weight * base_per_kg * size_mult
	var final_price = _fish_weight * base_per_kg * size_mult
	
	return int(round(final_price))


func _get_rarity_string() -> String:
	# Convert FishType.Rarity enum to string code for FishInstance
	if not fish:
		return "C"
	
	match fish.rarity:
		FishType.Rarity.COMMON:
			return "C"
		FishType.Rarity.UNCOMMON:
			return "U"
		FishType.Rarity.RARE:
			return "R"
		FishType.Rarity.EPIC:
			return "E"
		FishType.Rarity.LEGENDARY:
			return "L"
		_:
			return "C"


func _track_width() -> float:
	if not is_instance_valid(bar_track) or not is_instance_valid(catch_bar):
		return 100.0
	var w := bar_track.size.x - catch_bar.size.x
	return max(1.0, w)


func _bar_px_left() -> float:
	if not is_instance_valid(bar_track):
		return 0.0
	var track_left := bar_track.global_position.x
	var x: float = track_left + _bar_pos * _track_width()
	return x


func _set_catch_bar_visual():
	if not is_instance_valid(catch_bar) or not is_instance_valid(bar_track):
		return
		
	var desired_height: float = max(8.0, bar_track.size.y * 0.9)
	catch_bar.size = Vector2(catch_bar.size.x, desired_height)

	var x_left := _bar_px_left()
	catch_bar.global_position = Vector2(
		x_left,
		bar_track.global_position.y + (bar_track.size.y - catch_bar.size.y) * 0.5
	)


func _set_defaults():
	if not fish or not rod:
		return
	
	_fish_seed = randf() * 1000.0
	_bar_pos = 0.5
	_bar_vel = 0.0

	if is_instance_valid(catch_bar) and is_instance_valid(bar_track):
		if catch_bar.size.x <= 0:
			catch_bar.size.x = max(70.0, bar_track.size.x * 0.18)
		_set_catch_bar_visual()
	
	_set_fish_visual()
	
	if is_instance_valid(progress):
		progress.value = 20.0
		
	_treasure_active = randf() < fish.treasure_chance * rod.treasure_mult
	_treasure_val = 0.0

	_punch_ui(root_ui, 1.03, 0.12)


func _set_fish_visual():
	if not is_instance_valid(fish_icon) or not is_instance_valid(bar_track):
		return
		
	var left := bar_track.global_position.x + 12.0
	var right := bar_track.global_position.x + bar_track.size.x - fish_icon.size.x - 12.0

	var x: float = lerp(left, right, clamp(_fish_pos, 0.0, 1.0))

	fish_icon.global_position = Vector2(x, fish_icon.global_position.y)
	
	if fish:
		fish_icon.modulate = fish.tint


func _handle_collisions(delta: float):
	if _state != STATE.PLAYING:
		return
	var on_fish := _is_bar_over_fish()
	
	# ⭐ Handle reeling/dereel sounds
	if on_fish:
		_progress_val += PROGRESS_GAIN * delta
		
		# ⭐ Start reeling sound jika belum playing
	if not _is_reeling:
		_is_reeling = true
		if is_instance_valid(dereel_sound):
			dereel_sound.stop()
		if is_instance_valid(reeling_sound) and not reeling_sound.playing:
			reeling_sound.play()

	else:
		_progress_val -= BASE_ESCAPE_DRAIN * rod.escape_drain_mult * delta
		
		# ⭐ Start dereel sound jika belum playing
		if _is_reeling:
			_is_reeling = false
			if is_instance_valid(reeling_sound):
				reeling_sound.stop()
			if is_instance_valid(dereel_sound) and not dereel_sound.playing:
				dereel_sound.play()

	
	_progress_val = clamp(_progress_val, 0.0, 100.0)


func _update_progress_ui():
	if is_instance_valid(progress):
		progress.value = clamp(_progress_val, 0.0, 100.0)


func _is_bar_over_fish() -> bool:
	if not is_instance_valid(fish_icon) or not is_instance_valid(catch_bar):
		return false
		
	var fish_rect := Rect2(fish_icon.global_position, fish_icon.size)
	var bar_rect := Rect2(catch_bar.global_position, catch_bar.size)
	return bar_rect.intersects(fish_rect)


func _punch_ui(node: Node, scale_to: float, time: float):
	if not is_instance_valid(node):
		return
	var t := create_tween()
	t.tween_property(node, "scale", Vector2.ONE * scale_to, time * 0.5)
	t.tween_property(node, "scale", Vector2.ONE, time * 0.5)


func flash_node(node: CanvasItem, duration: float):
	if not is_instance_valid(node):
		return
	var t := create_tween()
	t.tween_property(node, "modulate", Color(1, 1, 1, 0.4), duration * 0.5)
	t.tween_property(node, "modulate", Color(1, 1, 1, 1), duration * 0.5)


func _shake(intensity: float, duration: float):
	if not is_instance_valid(root_ui):
		return
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for i in range(8):
		var off := Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tween.tween_property(root_ui, "position", off, duration / 8.0)
	tween.tween_property(root_ui, "position", Vector2.ZERO, 0.06)


func _time_freeze(seconds: float):
	Engine.time_scale = 0.0
	await get_tree().create_timer(seconds, true, true, true).timeout
	Engine.time_scale = 1.0


func _stop_all_sounds():
	_is_reeling = false
	
	if is_instance_valid(minigame_sound):
		minigame_sound.stop()
	if is_instance_valid(reeling_sound):
		reeling_sound.stop()
	if is_instance_valid(dereel_sound):
		dereel_sound.stop()
