extends Node

# VFX Manager handles global visual effects like screen shake and damage numbers

@onready var main_camera: Camera3D # For 3D screen shake
@onready var ui_camera: Camera2D   # For 2D screen shake (if applicable)

var shake_intensity: float = 0.0
var shake_decay: float = 5.0

func _process(delta):
	# Handle Screen Shake Decay
	if shake_intensity > 0:
		shake_intensity = max(0.0, shake_intensity - shake_decay * delta)
		if main_camera:
			var offset = Vector3(
				randf_range(-1, 1),
				randf_range(-1, 1),
				0
			) * shake_intensity * 0.1
			# Reset camera position roughly (assumes base is 0,0,0)
			main_camera.h_offset = offset.x
			main_camera.v_offset = offset.y

func add_screen_shake(intensity: float):
	shake_intensity = max(shake_intensity, intensity)

func spawn_damage_number(target_control: Control, amount: int, is_heal: bool = false):
	# Create a floating number using a Label
	var label = Label.new()
	label.text = str(amount)
	
	# Massive text settings
	var settings = LabelSettings.new()
	settings.font_size = 96
	settings.outline_size = 4
	settings.outline_color = Color(0,0,0,1)
	
	if is_heal:
		settings.font_color = Color(0.2, 0.8, 0.8, 1) # Cyan
		label.text = "+" + str(amount)
	else:
		settings.font_color = Color(0.8, 0.0, 0.0, 1) # Blood Red
		
	label.label_settings = settings
	
	# Center it on the target element
	label.position = target_control.global_position + (target_control.size / 2.0) - Vector2(50, 50)
	
	# Add to the active scene tree (ideally an overlay CanvasLayer, but root works for now)
	get_tree().root.add_child(label)
	
	# Animate it using Tweens
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	
	var rng_x = randf_range(-50, 50)
	var target_pos = label.position + Vector2(rng_x, -100)
	
	# Move up
	tween.tween_property(label, "position", target_pos, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Fade out
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.2)
	# Setup cleanup after animation ends
	tween.chain().tween_callback(label.queue_free)
