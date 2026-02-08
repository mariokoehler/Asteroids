extends WrappableBody

@export var thrust_power: float = 500.0
@export var rotation_speed: float = 2000.0
@export var bullet_scene: PackedScene
@export var rate_of_fire: float = 8.0
@onready var muzzle: Marker2D = $Muzzle
@export var max_health: int = 5

@onready var left_exhaust = $LeftEngine
@onready var right_exhaust = $RightEngine

var current_health: int

# This variable tracks how many seconds we have to wait.
# We initialize it to 0.0 so we can shoot immediately when the game starts.
var _cooldown_timer: float = 0.0

var is_invincible: bool = false

func _ready() -> void:
	super._ready() # Initialize screen wrap
	current_health = max_health
	Global.player_health_changed.emit(current_health, max_health)
	
func _physics_process(_delta: float) -> void:
	
	# 1. Update the timer every frame
	# We subtract the time passed since the last frame (delta)
	if _cooldown_timer > 0.0:
		_cooldown_timer -= _delta
		
	if Input.is_action_pressed("forward"):
		var force_vector: Vector2 = Vector2.RIGHT.rotated(rotation) * thrust_power
		apply_central_force(force_vector)
		left_exhaust.emitting = true
		right_exhaust.emitting = true
	else:
		left_exhaust.emitting = false
		right_exhaust.emitting = false
	
	if Input.is_action_pressed("left"):
		apply_torque(-rotation_speed)
	elif Input.is_action_pressed("right"):
		apply_torque(rotation_speed)
		
	if Input.is_action_pressed("fire") and _cooldown_timer <= 0.0:
		shoot()
		# Reset the timer
		# Math: 1 second / 2 shots = 0.5 seconds delay per shot
		_cooldown_timer = 1.0 / rate_of_fire

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var xform: Transform2D = state.transform
	var origin: Vector2 = xform.origin
	var did_wrap: bool = false
	
	# --- HORIZONTAL WRAPPING ---
	# Only wrap if we are PAST the screen edge PLUS the margin
	if origin.x > screen_size.x + wrap_margin:
		origin.x = -wrap_margin 
		did_wrap = true
	elif origin.x < -wrap_margin:
		origin.x = screen_size.x + wrap_margin
		did_wrap = true
	
	# --- VERTICAL WRAPPING ---
	if origin.y > screen_size.y + wrap_margin:
		origin.y = -wrap_margin
		did_wrap = true
	elif origin.y < -wrap_margin:
		origin.y = screen_size.y + wrap_margin
	did_wrap = true
	
	if did_wrap:
		state.transform.origin = origin

func shoot() -> void:
	# 1. Instantiate the scene (create the object in memory)
	# The return type is 'Node', so we cast it to our Bullet class
	var bullet_instance: Bullet = bullet_scene.instantiate()
	
	# 2. Set the starting position and rotation
	# We use global_position because the Muzzle is moving/rotating inside the player
	bullet_instance.global_position = muzzle.global_position
	bullet_instance.rotation = rotation
	bullet_instance.linear_velocity = linear_velocity + (Vector2.RIGHT.rotated(rotation) * bullet_instance.speed)
	
	# 3. Add to the Scene Tree
	# CRITICAL: Do NOT use add_child(bullet_instance) on the Player!
	# If you do, the bullet will move WITH the player.
	# We want to add it to the "World" (the player's parent).
	get_parent().add_child(bullet_instance)


func take_damage(amount: int) -> void:
	if is_invincible: return # Ignore damage if recently hit
	
	current_health -= amount
	Global.player_health_changed.emit(current_health, max_health)
	
	# Visual feedback
	flash_damage()
	
	if current_health <= 0:
		die()
		return
		
	start_invincibility()


func start_invincibility() -> void:
	# Safety check: if the node is being deleted or the tree is gone, stop.
	if not is_inside_tree(): 
		return
		
	is_invincible = true
	# Wait 1 second before being vulnerable again
	await get_tree().create_timer(1.0).timeout
	is_invincible = false
	

func flash_damage() -> void:
	var sprite = get_node_or_null("Ship")
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.RED, 0.1)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)


func die() -> void:
	print("Player Perished!")
	
	# Call the Global function to handle the death logic
	Global.player_died() 
	
	# CRITICAL: We need to destroy the player node itself,
	# but we must wait one frame so the Global script can handle the reload.
	# We use call_deferred to safely free the node after the frame has finished.
	call_deferred("queue_free") 


# Signal connected from the Inspector
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("asteroids"):
		# Get damage based on asteroid size
		var dmg = 1 # fallback
		if body.has_method("get_collision_damage"):
			dmg = body.get_collision_damage()
		
		take_damage(dmg)
		
		# Optional: If you want asteroids to explode when they hit the player:
		if body.has_method("explode"):
			body.explode()
