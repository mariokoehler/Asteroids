extends CanvasLayer

# Use unique names to get references easily
@onready var score_label: Label = %ScoreLabel
@onready var restart_button: Button = %Button

func _ready() -> void:
	# Set the final score from the Global state
	score_label.text = "FINAL SCORE: %06d" % Global.score
	restart_button.pressed.connect(on_restart_pressed)

func on_restart_pressed() -> void:
	# 1. Reset the Global state
	Global.reset_game_state()
	
	# 2. Reload the main World scene
	get_tree().change_scene_to_file("res://scenes/world.tscn")

	# 3. Free the Game Over screen
	queue_free()
