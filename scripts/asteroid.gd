extends WrappableBody
class_name Asteroid

# This defines a new signal this node can emit.
# We'll pass its final position and size so the spawner knows what died.
signal asteroid_destroyed(size)

enum Size { LARGE, MEDIUM, SMALL }
@export var size: Size = Size.LARGE

@export_group("Variations")
@export var large_variations: Array[PackedScene]
@export var medium_variations: Array[PackedScene]
@export var small_variations: Array[PackedScene]

@export_group("Properties")
@export var min_speed: float = 50.0
@export var max_speed: float = 150.0
@export var min_rotation: float = -3.0
@export var max_rotation: float = 3.0

# Using int for discrete hits (3 hits to kill)
@export var max_health: int = 3 
@export var explosion_scene: PackedScene

@export_group("Sounds")
@export var break_sound_large: AudioStream
@export var break_sound_small: AudioStream

@onready var rock_hit_sound: AudioStreamPlayer = $RockHit

# A place to store the velocity before collisions mess it up
var velocity_before_collision: Vector2 = Vector2.ZERO

# Tracks current state
var current_health: int

# We need a place to store the reference to the spawned visual
var active_visual: Node2D

var last_hit_time: float = 0.0

# Point this to your main asteroid scene file path
const ASTEROID_SCENE_PATH: String = "res://scenes/asteroid.tscn" 

func _ready() -> void:
	# 1. Call super._ready() to initialize screen_size and margins
	super._ready()
	
	var variation_to_spawn: PackedScene
	
	match size:
		Size.LARGE:
			max_health = 3
			scale = Vector2(1.0, 1.0)
			if not large_variations.is_empty():
				variation_to_spawn = large_variations.pick_random()
		
		Size.MEDIUM:
			max_health = 2
			scale = Vector2(0.5, 0.5)
			if not medium_variations.is_empty():
				variation_to_spawn = medium_variations.pick_random()

		Size.SMALL:
			max_health = 1
			scale = Vector2(0.25, 0.25)
			if not small_variations.is_empty():
				variation_to_spawn = small_variations.pick_random()
				
	# Initialize health
	current_health = max_health
	
	# Now, spawn the chosen visual prefab
	if variation_to_spawn:
		active_visual = variation_to_spawn.instantiate()
		call_deferred("add_child", active_visual)
		
	# Only randomize velocity if we are "standing still" (i.e., newly spawned by the game start).
	# If we were spawned by a split, linear_velocity will already be non-zero.
	if linear_velocity == Vector2.ZERO:
		var random_angle: float = randf() * TAU
		var direction: Vector2 = Vector2.RIGHT.rotated(random_angle)
		var random_speed: float = randf_range(50.0, 150.0) # or your var names
		linear_velocity = direction * random_speed
		angular_velocity = randf_range(-3.0, 3.0)
		

func _physics_process(delta: float) -> void:
	# 1. Capture the velocity at the start of the frame
	# Since _physics_process runs before the internal physics collision resolution steps,
	# this captures the movement "flight" vector, not the "impact" vector.
	velocity_before_collision = linear_velocity


func take_damage(amount: int) -> void:
	current_health -= amount
	
	if current_health > 0:
		flash_damage()
		
		# Get current time in milliseconds
		var now = Time.get_ticks_msec()
		
		# Only play sound if 50ms have passed since the last one
		if now - last_hit_time > 50:
			rock_hit_sound.pitch_scale = randf_range(0.8, 1.2)
			rock_hit_sound.play()
			last_hit_time = now
			
	elif current_health <= 0:
		explode()


func flash_damage() -> void:
	if active_visual:
		var sprite = active_visual.get_node("Sprite2D")
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.RED, 0.05)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.05)


func explode() -> void:
	# 1. Notify the World (Game Manager)
	asteroid_destroyed.emit(size)
	
	# --- SPAWN DUST CLOUD ---
	if explosion_scene:
		var explosion = explosion_scene.instantiate()
		explosion.global_position = global_position
		
		var sound_to_play: AudioStream
		
		# Scale the explosion based on asteroid size?
		# A simple way:
		match size:
			Size.LARGE: 
				explosion.scale = Vector2(1.5, 1.5)
				sound_to_play = break_sound_large
			Size.MEDIUM: 
				explosion.scale = Vector2(1.0, 1.0)
				sound_to_play = break_sound_small
			Size.SMALL:
				explosion.scale = Vector2(0.6, 0.6)
				sound_to_play = break_sound_small

		# Pass the sound to the explosion wrapper
		if explosion.has_method("set_sound"):
			explosion.set_sound(sound_to_play)

		# Add to World (the parent), NOT self!
		get_parent().call_deferred("add_child", explosion)

	# 2. Split Logic
	# If we are NOT a small asteroid, we spawn children
	if size != Size.SMALL:
		spawn_children()

	# 3. Destroy self
	queue_free()

func spawn_children() -> void:
	# Load the scene template
	var scene_resource = load(ASTEROID_SCENE_PATH)
	
	# We spawn 3 smaller asteroids
	for i in 2:
		var child: Asteroid = scene_resource.instantiate()
		
		# A. Set the Size
		# Enums are just integers (0, 1, 2). 
		# So Size.LARGE (0) + 1 becomes Size.MEDIUM (1).
		child.size = size + 1 
		
		# B. Set Position (Start exactly where the parent was)
		child.global_position = global_position
		
		# C. Calculate Velocity
		# We want them to split away from each other.
		# Let's take the parent's current direction and rotate it.
		var current_speed = velocity_before_collision.length()
		
		# Ensure they have at least some speed if parent was stopped
		var base_speed = max(current_speed, 100.0) 
		
		var angle_offset = deg_to_rad(22.5) if i == 0 else deg_to_rad(-22.5)
		
		# We rotate the velocity vector
		var new_velocity = velocity_before_collision.rotated(angle_offset)
		
		# Normalize it and apply new speed (make smaller ones faster!)
		child.linear_velocity = new_velocity.normalized() * (base_speed * 1.5)
		
		# D. Add to World
		# We use call_deferred to safeguard the physics engine during a callback
		get_parent().call_deferred("add_child", child)

func get_collision_damage() -> int:
	match size:
		Size.LARGE: return 3
		Size.MEDIUM: return 2
		Size.SMALL: return 1
	return 0
