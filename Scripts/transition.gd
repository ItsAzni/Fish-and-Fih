extends CanvasLayer

@onready var fade_rect: ColorRect = $FadeRect


func _ready() -> void:
	layer = 100
	fade_rect.modulate.a = 1.0
	
	await get_tree().create_timer(0.15).timeout
	fade_in()
	
	print("✅ Transition system ready")


func fade_in(duration: float = 0.5) -> void:
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, duration)
	await tween.finished


func fade_out(duration: float = 0.5) -> void:
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, duration)
	await tween.finished


func change_scene(scene_path: String) -> void:
	print("🎬 Changing scene to: " + scene_path)
	
	await fade_out(0.5)
	
	var result = get_tree().change_scene_to_file(scene_path)
	if result != OK:
		push_error("❌ Failed to load scene: " + scene_path)
		await fade_in(0.5)
		return
	
	await get_tree().process_frame
	await get_tree().process_frame
	await fade_in(0.5)
	
	print("✅ Scene loaded successfully")
