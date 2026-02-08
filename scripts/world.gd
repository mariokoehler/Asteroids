extends Node2D

# The blueprint for the asteroid
@export var asteroid_scene: PackedScene
# How many large asteroids should be on screen at all times?
@export var initial_asteroid_count: int = 4

# --- INTERNAL STATE ---
# We need screen size and margin, just like in WrappableBody
var screen_size: Vector2
var wrap_margin: float = 100.0 # A larger margin for spawning is good

func _ready() -> void:
	# Get screen dimensions, accounting for camera zoom
	var rect_size = get_viewport_rect().size
	var camera = get_viewport().get_camera_2d()
	if camera:
		screen_size = rect_size / camera.zoom
	else:
		screen_size = rect_size
		
	# Spawn the first wave of asteroids
	for i in initial_asteroid_count:
		spawn_asteroid(Asteroid.Size.LARGE)

# This is the listener function that will be connected to the signal
func _on_asteroid_destroyed(size) -> void:
	# For now, we only care about replacing LARGE asteroids that are destroyed.
	# When a big one is destroyed, spawn another big one somewhere else.
	if size == Asteroid.Size.LARGE:
		spawn_asteroid(Asteroid.Size.LARGE)

func spawn_asteroid(size: Asteroid.Size) -> void:
	# 1. INSTANTIATE
	var asteroid_instance: Asteroid = asteroid_scene.instantiate()
	
	# 2. CALCULATE OFF-SCREEN POSITION
	var spawn_position = Vector2.ZERO
	var spawn_edge = randi() % 4 # 0=Top, 1=Bottom, 2=Left, 3=Right
	
	match spawn_edge:
		0: # Top
			spawn_position.x = randf_range(0, screen_size.x)
			spawn_position.y = -wrap_margin
		1: # Bottom
			spawn_position.x = randf_range(0, screen_size.x)
			spawn_position.y = screen_size.y + wrap_margin
		2: # Left
			spawn_position.x = -wrap_margin
			spawn_position.y = randf_range(0, screen_size.y)
		3: # Right
			spawn_position.x = screen_size.x + wrap_margin
			spawn_position.y = randf_range(0, screen_size.y)
			
	# 3. CALCULATE "AIM INWARDS" VELOCITY
	# Pick a random point inside the screen to aim at
	var target_position = Vector2(
		randf_range(screen_size.x * 0.25, screen_size.x * 0.75),
		randf_range(screen_size.y * 0.25, screen_size.y * 0.75)
	)
	var direction = (target_position - spawn_position).normalized()
	var speed = randf_range(50.0, 150.0)
	
	# 4. CONFIGURE THE ASTEROID
	asteroid_instance.size = size
	asteroid_instance.global_position = spawn_position
	asteroid_instance.linear_velocity = direction * speed
	asteroid_instance.angular_velocity = randf_range(-1.0, 1.0)
	
	# 5. CONNECT THE SIGNAL
	# This is the crucial step. We listen for this new asteroid's death signal.
	asteroid_instance.asteroid_destroyed.connect(_on_asteroid_destroyed)
	
	# 6. ADD TO SCENE
	add_child(asteroid_instance)
