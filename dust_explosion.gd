extends GPUParticles2D

func _ready() -> void:
	# 1. Start the explosion immediately
	emitting = true
	
	# 2. Connect the "finished" signal to delete this node
	# This signal fires when the last particle has disappeared.
	finished.connect(_on_finished)

func _on_finished() -> void:
	queue_free()
