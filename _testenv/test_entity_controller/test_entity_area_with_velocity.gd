extends EntityArea

# testenv script

var velocity: Vector2 = Vector2.ZERO

func _ready():
	self.is_active = true
	self.is_valid = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	global_position += velocity*delta
