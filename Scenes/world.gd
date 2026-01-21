extends Node2D

@onready var fade_anim: AnimationPlayer = $CanvasLayer/FadeRect/AnimationPlayer
@onready var fade_rect: ColorRect = $CanvasLayer/FadeRect
@onready var canvas_modulate: CanvasModulate = $CanvasModulate

func _ready():
	fade_rect.visible = true
	fade_anim.play("fade_in")
	
	# Apply saved brightness
	var brightness = GameSettings.brightness
	canvas_modulate.color = Color(brightness, brightness, brightness, 1.0)
