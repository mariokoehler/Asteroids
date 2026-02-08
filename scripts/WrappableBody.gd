# WrappableBody.gd
class_name WrappableBody extends RigidBody2D

# Protected variables (conceptually)
var screen_size: Vector2
var wrap_margin: float = 50.0

func _ready() -> void:
	# 1. Setup Screen Size (Logic reused from Player)
	var rect_size = get_viewport_rect().size
	var camera = get_viewport().get_camera_2d()
	if camera:
		screen_size = rect_size / camera.zoom
	else:
		screen_size = rect_size
		
	# 2. Auto-calculate margin based on sprite size (if available)
	# This looks for the FIRST Sprite2D child, regardless of name
	for child in get_children():
		if child is Sprite2D:
			# Calculate margin based on the largest dimension
			var size = child.texture.get_size() * child.scale
			wrap_margin = max(size.x, size.y) / 2.0
			break

# The wrapping logic lives here, shared by Player and Asteroids
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var xform: Transform2D = state.transform
	var origin: Vector2 = xform.origin
	var did_wrap: bool = false
	
	if origin.x > screen_size.x + wrap_margin:
		origin.x = -wrap_margin
		did_wrap = true
	elif origin.x < -wrap_margin:
		origin.x = screen_size.x + wrap_margin
		did_wrap = true
	
	if origin.y > screen_size.y + wrap_margin:
		origin.y = -wrap_margin
		did_wrap = true
	elif origin.y < -wrap_margin:
		origin.y = screen_size.y + wrap_margin
		did_wrap = true
		
	if did_wrap:
		state.transform.origin = origin
