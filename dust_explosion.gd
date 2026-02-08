extends GPUParticles2D

@onready var sound_player: AudioStreamPlayer2D = $SoundPlayer

# Variable to store the sound temporarily
var pending_sound: AudioStream

func _ready() -> void:
	# 1. Start particles
	emitting = true
	finished.connect(_on_finished)
	
	# 2. Check if we have a sound waiting to play
	if pending_sound:
		sound_player.stream = pending_sound
		sound_player.play()

# Modified setter: Just stores the value, doesn't touch the node yet
func set_sound(stream: AudioStream) -> void:
	pending_sound = stream

func _on_finished() -> void:
	# Check if sound is still playing
	if sound_player.playing:
		await sound_player.finished
	queue_free()
