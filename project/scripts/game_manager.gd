extends Control

var player_health := 10
var ai_health := 10
var turn := 1


func _ready() -> void:
	$PotionA.pressed.connect(_on_potion_a_pressed)
	$PotionB.pressed.connect(_on_potion_b_pressed)
	update_ui()


func update_ui() -> void:
	$PlayerHealth.text = "Player HP: %d" % player_health
	$AIHealth.text = "Bot HP: %d" % ai_health
	$TurnLabel.text = "Turn: %d" % turn


func _on_potion_a_pressed() -> void:
	player_health -= 1
	ai_health -= 2
	turn += 1
	update_ui()


func _on_potion_b_pressed() -> void:
	player_health -= 2
	ai_health -= 1
	turn += 1
	update_ui()
