extends Entity

class_name Projectile

##############################################################################

# Projectiles are derived from the entity class

# projectile behaviour priority
# move forward based on speed and rotation (global_transform.x)
# if forced_direction is set, projectile will instead move in that direction
# if current_target is set, will instead get vector to target and move in that
# direction, overriding both default behaviour and forced direction

##############################################################################

# public vars

# default projectile behaviour is to move forward based on speed
# speed is multiplied by delta to get the travel distance per frame
# if not set (or reset back to 0) the projectile will not move
var speed: int = 0
# force (multiplied by delta) of projectile rotation
# rotation_speed_actual ignored if a forced direction or current_target is set
# by setting this var will make the projectile turn as it moves
# determined in degrees
var rotation_speed_actual: int = 0
# applies a visual rotation to the projectile sprite every frame
var rotation_speed_visual: int = 0

# private vars

# behaviour controlling var, set with force_direction() method
# by setting a forced vector the projectile will instead move in that direction
var _forced_direction: Vector2 = Vector2.ZERO

# behaviour controlling vars, set with set_target() method
# if a current_target is set the projectile will move toward the target
var _current_target: Node2D = null
# configures frequency of updating target position if current_target is set
# sets wait_time on retarget timer (created if this value is set to non-nil)
var _retarget_frequency: float = 0.0
# speed at which the projectile adjusts its rotation toward target if tracking
var _turning_agility: int = 0

##############################################################################

# setters and getters

#//TODO
# func _set_current_target() #for validating and connecting/removing previous
# func _set_retarget_frequency() #for handling the timer node

##############################################################################

# virtual methods


# init/ready (if overriding init verify entity init still works)


##############################################################################

# virtual processing methods


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_process_node_rotation(delta)
	_process_sprite_rotation(delta)
	_process_movement(delta)
	#//TODO add tracking behaviour for current_target set


func _process_movement(dt: float) -> void:
	var my_dir: Vector2
	# if no forced direction is set, use facing for movement instead
	#//TODO sort out current target behaviour override
	if _forced_direction != Vector2.ZERO:
		my_dir = _forced_direction
	else:
		my_dir = global_transform.x
	# position adjusted by speed, direction, and time since last frame
	position += (speed*my_dir*dt)


# applies a rotation to the root projectile node
# if _forced_direction or _current_target is set, this will be ignored
func _process_node_rotation(dt: float) -> void:
	# rotation speed actual applies to the projectile, the parent node
	# only applies during default projectile behaviour (if forced direction
	# or current target are not set)
	if rotation_speed_actual != 0\
	and _forced_direction == Vector2.ZERO\
	and _current_target == null:
		rotation_degrees += (rotation_speed_actual*dt)


# applies a visual rotation to sprite child (if found)
func _process_sprite_rotation(dt: float) -> void:
	# rotation speed visual applies to the child sprite node
	# it will be affected by the rotation speed actual
	if rotation_speed_visual != 0 and my_sprite_node != null:
		if "rotation_degrees" in my_sprite_node:
			my_sprite_node.rotation_degrees += (rotation_speed_visual*dt)


##############################################################################

# public methods


# overrides default behaviour and sends the projectile in this direction
func force_direction(arg_direction: Vector2) -> void:
	self._forced_direction = arg_direction


#//TODO FINISH
# this method sets all variables necessary for projectile 'seek' a target
#[params as follows]
#1, "arg_target", is the node the projectile will seek. Projectile will follow
#	a variation of default behaviour, moving forward based on its rotation
#	but attempting to rotate toward the target.
#2, "arg_update_rate", is the wait time of the timer that determines how often
#	the projectile gets the position of the current target
#3, "turning agility", is how sharply the projectile will turn (adjust their
#	facing to point toward the target)
func set_target(
		arg_target: Node2D,
		arg_update_rate: float,
		arg_tracking: int) -> void:
	#
	self._current_target = arg_target
	self._retarget_frequency = arg_update_rate
	self._turning_agility = arg_tracking
	
	#//disable update if target is lost
	#// must check if update timer already exists and create if not
	#// make sure to confirm target existence (or never free targets whilst
	# in game?) -- connect exiting signals etc


##############################################################################

# private methods


#here

