# HUD.gd
extends CanvasLayer

@onready var score_label: Label = %ScoreLabel
@onready var lives_label: Label = %LivesLabel
@onready var health_bar: ProgressBar = $MarginContainer/CenterContainer/HealthBar

# Called when the HUD is created
func _ready() -> void:
	# Set initial values
	update_score(Global.score)
	update_lives(Global.current_lives)
	
	# Connect the signals from the persistent Global script to this HUD script
	Global.score_updated.connect(update_score)
	Global.lives_updated.connect(update_lives)
	Global.player_health_changed.connect(update_health_bar)

# Public functions for other scripts to call
func update_score(new_score: int) -> void:
	score_label.text = "SCORE: %06d" % new_score # %06d ensures zero-padding: 000001


func update_lives(new_lives: int) -> void:
	lives_label.text = "LIVES: %d" % new_lives


func update_health_bar(current: int, max_hp: int) -> void:
	# Set the max value (in case max_health changes due to upgrades later)
	health_bar.max_value = max_hp
	health_bar.value = current
	
	# Optional Juice: Change color based on health?
	# You can access the StyleBoxFlat we created in the editor
	var style_box = health_bar.get_theme_stylebox("fill")
	
	if style_box is StyleBoxFlat:
		if current < max_hp * 0.3:
			style_box.bg_color = Color.RED # Critical!
		elif current < max_hp * 0.6:
			style_box.bg_color = Color.YELLOW # Warning
		else:
			style_box.bg_color = Color.GREEN # Good
