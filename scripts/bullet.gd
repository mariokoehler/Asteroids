class_name Bullet extends WrappableBody

@export var speed: float = 900.0
@export var lifetime: float = 2.0
@export var damage: int = 1 # Standard bullet does 1 damage

func _ready() -> void:
	# 1. Initialize wrapping
	super._ready()
	
	# 2. Set velocity relative to its own rotation
	# (The rotation will be set by the player when spawning)
	#linear_velocity = Vector2.RIGHT.rotated(rotation) * speed
	
	# 3. Set a timer to destroy the object
	# This creates a lightweight timer that runs in the background
	await get_tree().create_timer(lifetime).timeout
	queue_free() # "free()" is effectively Java's explicit destructor


# This function is called automatically by the signal
func _on_body_entered(body: Node) -> void:
	# Check if the object we hit is in the "asteroids" group
	if body.is_in_group("asteroids"):
		# Call a function on the asteroid to handle damage
		if body.has_method("take_damage"):
			body.take_damage(damage)

		Global.add_score(1) 

		# Destroy the bullet
		queue_free()
