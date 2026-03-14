extends Node3D

# Handles the 3D Alchemist character's reactions to game events
# Positioned in Main.tscn under the SubViewport

@onready var camera = $Camera3D
@onready var light = $DirectionalLight3D

# Placeholder for character model and animations
var alchemist_model # In a real Godot setup, this would be a MeshInstance3D with AnimationPlayer

func _ready():
	# Connect to game signals from Main
	pass

func react_to_damage(is_player: bool):
	if is_player:
		# Alchemist grins/leans in
		print("Alchemist reacts to player damage: Grinning")
		_lean_in()
	else:
		# Alchemist recoils/angry
		print("Alchemist reacts to AI damage: Recoiling")
		_lean_back()

func react_to_heal(is_player: bool):
	if is_player:
		print("Alchemist reacts to player heal: Displeased")
	else:
		print("Alchemist reacts to AI heal: Satisfied")

func react_to_chaos_wheel():
	print("Alchemist reacts to Chaos Wheel: Anticipation")
	_jitter_eyes()

func react_to_hp_swap():
	print("Alchemist reacts to HP Swap: Screaming")
	_camera_shake(1.0)

func _lean_in():
	# Animation logic
	pass

func _lean_back():
	# Animation logic
	pass

func _jitter_eyes():
	# Animation logic
	pass

func _camera_shake(intensity: float):
	# Camera shake logic
	pass
