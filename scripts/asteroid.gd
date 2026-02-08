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

# Tracks current state
var current_health: int

# We need a place to store the reference to the spawned visual
var active_visual: Node2D

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
		
	# 2. Randomize Position (Optional, if you aren't placing them manually)
	rotation = randf() * TAU 
	
	# 3. random Direction
	# TAU is a constant in Godot (2 * PI), representing 360 degrees in radians
	var random_angle: float = randf() * TAU
	var direction: Vector2 = Vector2.RIGHT.rotated(random_angle)
	
	# 4. Random Speed
	var random_speed: float = randf_range(min_speed, max_speed)
	
	# 5. Apply Linear Velocity
	linear_velocity = direction * random_speed
	
	# 6. Apply Random Rotation (Angular Velocity)
	angular_velocity = randf_range(min_rotation, max_rotation)
	
	
func take_damage(amount: int) -> void:
	current_health -= amount
	
	# Visual Feedback
	flash_damage()
	
	if current_health <= 0:
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
		
		# Scale the explosion based on asteroid size?
		# A simple way:
		match size:
			Size.LARGE: explosion.scale = Vector2(1.5, 1.5)
			Size.MEDIUM: explosion.scale = Vector2(1.0, 1.0)
			Size.SMALL: explosion.scale = Vector2(0.6, 0.6)
			
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
		var current_speed = linear_velocity.length()
		# Ensure they have at least some speed if parent was stopped
		var base_speed = max(current_speed, 100.0) 
		
		# Child 1 goes 120 degrees, Child 2 goes 240 degrees ...
#		var angle_offset = deg_to_rad(120.0) * i
		var angle_offset = deg_to_rad(45.0) if i == 0 else deg_to_rad(-45.0)
		
		
		# We rotate the velocity vector
		var new_velocity = linear_velocity.rotated(angle_offset)
		
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
