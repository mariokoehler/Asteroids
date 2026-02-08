extends Node
class_name GameManager

# Define the signals at the top
signal score_updated(new_score)
signal lives_updated(new_lives)
signal player_health_changed(current_health, max_health)

@export var max_lives: int = 3
@export var game_over_scene: PackedScene

var current_lives: int = 0
var score: int = 0
var is_game_over: bool = false

func _ready() -> void:
	# Called once when the game starts
	current_lives = max_lives
	print("GameManager loaded. Starting with ", current_lives, " lives.")

func add_score(amount: int) -> void:
	score += amount
	score_updated.emit(score)

func player_died() -> void:
	if is_game_over: return
	
	current_lives -= 1
	lives_updated.emit(current_lives)
	
	if current_lives <= 0:
		game_over()
	else:
		# Reload the scene to respawn the player/asteroids
		get_tree().reload_current_scene()

func game_over() -> void:
	if is_game_over: return
	
	is_game_over = true
	
	# Pause the game world entirely
	get_tree().paused = true
	
	# Load and add the Game Over screen as a child of the root viewport
	var game_over_screen = game_over_scene.instantiate()
	get_tree().get_root().add_child(game_over_screen)
	
func reset_game_state() -> void:
	# Reset all persistent values
	score = 0
	current_lives = max_lives
	is_game_over = false
	get_tree().paused = false # Unpause the game!
