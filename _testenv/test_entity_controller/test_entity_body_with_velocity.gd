extends EntityBody

# testenv script

var velocity: Vector2 = Vector2.ZERO

func _ready():
	self.is_active = true
	self.is_valid = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	var _collision_info
	_collision_info = move_and_slide(velocity)
