extends Control
class_name ChaosWheelUI

signal spin_finished(outcome: GameRules.ChaosOutcome)

@onready var wheel_graphic = $WheelContainer/WheelGraphic

var is_spinning: bool = false
var current_speed: float = 0.0
var friction: float = 2.0
var total_rotation: float = 0.0
var final_outcome: GameRules.ChaosOutcome

# Pre-defined angles for the 6 outcomes (60 degrees each)
const OUTCOME_ANGLES = [0, 60, 120, 180, 240, 300]

func _process(delta):
	if is_spinning:
		# Apply friction to slow down the wheel
		current_speed = move_toward(current_speed, 0, friction * delta)
		wheel_graphic.rotation_degrees += current_speed * delta
		
		# Clack sound logic would go here based on passing 60-degree thresholds
		
		if current_speed <= 0:
			_on_spin_stop()

func start_spin(target_outcome: GameRules.ChaosOutcome):
	visible = true
	final_outcome = target_outcome
	
	# Calculate how much to spin to land on the correct angle
	# We want it to spin fast for a few seconds, then land exactly on the index
	var target_angle = OUTCOME_ANGLES[target_outcome]
	
	# Add randomization so it doesn't always land dead center
	var offset = randf_range(-20, 20)
	
	# Give it a lot of initial speed, aiming to stop at target_angle + (360 * multiple)
	current_speed = randf_range(800.0, 1200.0)
	friction = current_speed / randf_range(3.0, 5.0) # Stop in 3-5 seconds
	
	# Wait for physical rotation to line up using tweening for the final snap 
	# (a more robust way than purely physics-based stopping)
	var final_rotation = wheel_graphic.rotation_degrees + (current_speed * (current_speed/friction) / 2.0) # basic kinematics
	var remainder = fmod(final_rotation, 360.0)
	var correction = target_angle - remainder
	
	# Override kinematics with a strict Tween for cinematic control
	is_spinning = false 
	var spin_time = randf_range(4.0, 6.0) # Long, suspenseful spin
	var total_spin = (360.0 * 5) + target_angle + offset # Spin 5 times + land on target
	
	var tween = get_tree().create_tween()
	# Fast start, agonizingly slow finish for tension
	tween.tween_property(wheel_graphic, "rotation_degrees", wheel_graphic.rotation_degrees + total_spin, spin_time) \
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	tween.tween_callback(self._on_spin_stop)
	
	print("[AUDIO] *Wheel spinning rapidly... slowing down*")

func _on_spin_stop():
	is_spinning = false
	
	# Flash effect based on outcome to mirror the UI aesthetic
	var tween = get_tree().create_tween()
	
	if final_outcome == GameRules.ChaosOutcome.HP_SWAP:
		print("[AUDIO] *Dissonant Chord ALCHEMIST SCREAM* - HP SWAP!")
		# Flash screen inverted or red
		modulate = Color(2, 0, 0, 1) # Over-bright red
	else:
		print("[AUDIO] *Heavy Mechanical Slam* - Wheel stopped")
		modulate = Color(2, 2, 2, 1) # Over-bright white flash
		
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.5)
	tween.tween_callback(self._finish_and_hide)

func _finish_and_hide():
	# Allow a moment to read the result before hiding
	await get_tree().create_timer(1.5).timeout
	visible = false
	spin_finished.emit(final_outcome)
