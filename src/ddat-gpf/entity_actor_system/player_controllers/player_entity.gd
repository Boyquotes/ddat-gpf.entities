extends EntityBody

class_name PlayerMovementController

##############################################################################

# PlayerMovementController is an EntityBody(KinematicBody2D) extension which
# allows for a wide variety of top-down movement styles by adjusting the
# included properties and input style settings (for movement/rotation).
# As an example; you can get tank-style controls by setting movement_input to
# forward_only && rotation_input to left_right.

#//TODO
#	review lerp for rotation - when given stronger differences it eases faster
#	change rotation to be a fixed value rather than lerp
#	 (use lerp to get direction of rotation?)
#	reimplement stored velocity cap_velocity & velocity_dropoff methods
#	add acceleration steps/stages (faster acceleration at start or end)
#	implement accelerate_per_direction
#	add movement audio argument/add audio
#	add mouse control variation (press input to turn on/off mouse look)
#	review is_changing_direction usage for turning_coefficient in change_accel
#	forward_only doesn't have deacceleration

##############################################################################

# placeholder signal for audio manager implementation
# if current volume for sound effect is very different to given, ease to
# the new volume over a period determined by the difference in volume
signal play_audio(sound_effect_name, sound_effect_volume)

# change controller input by setting associated export to one of these values
# modify action strings and controller properties to produce alternate movement
# MOVEMENT_INPUT
# .CARDINAL = 4 direction movement (from cardinal input)
# .OMNIDIRECTIONAL = 8 direction movement (diag normalised from cardinal input)
# .FORWARD_ONLY = 1 direction movement (direction determined by rotation)
enum MOVEMENT_INPUT {
	CARDINAL,
	OMNIDIRECTIONAL,
	FORWARD_ONLY,
	}
# ROTATION_INPUT
# .CARDINAL = face direction of cardinal input
# .OMNIDIRECTIONAL = face normalised direction of cardinal inputs
# .LEFT_RIGHT = turn left or right with different inputs
# .MOUSE_LOOK = rotate to face mouse
enum ROTATION_INPUT {
		TOWARD_CARDINAL,
		TOWARD_OMNIDIRECTIONAL,
		LEFT_RIGHT,
		MOUSE_LOOK,
		}

# NOTES ON MOVEMENT_INPUT and ROTATION_INPUT:
# 1) If using movement_input.forward_only with rotation_input.cardinal or
#	rotation_input.omnidirectional, do not overlap action_string_move_forward
#	with action_string_rotate_toward_up.

# for passing to error logging
const SCRIPT_NAME := "PlayerMovementController"
# for developer use, enable if making changes
const VERBOSE_LOGGING := false

# strings for InputMap (adjust in Project Settings)
# MOVEMENT_INPUT.CARDINAL
# MOVEMENT_INPUT.OMNIDIRECTIONAL
const ACTION_STRING_MOVE_UP = "ui_up"
const ACTION_STRING_MOVE_RIGHT = "ui_right"
const ACTION_STRING_MOVE_LEFT = "ui_left"
const ACTION_STRING_MOVE_DOWN = "ui_down"
# MOVEMENT.INPUT_FORWARD_ONLY
const ACTION_STRING_MOVE_FORWARD = "ui_accept"
# ROTATION_INPUT.TOWARD_CARDINAL
const ACTION_STRING_ROTATE_TOWARD_UP = "ui_up"
const ACTION_STRING_ROTATE_TOWARD_RIGHT = "ui_right"
const ACTION_STRING_ROTATE_TOWARD_LEFT = "ui_left"
const ACTION_STRING_ROTATE_TOWARD_DOWN = "ui_down"
# ROTATION_INPUT.LEFT_RIGHT
const ACTION_STRING_ROTATE_CLOCKWISE = "ui_right"
const ACTION_STRING_ROTATE_COUNTER_CLOCKWISE = "ui_left"

# turning penalty can never be negative
const TURN_PENALTY_FLOOR := 0.0
# turning penalty can never exceed 100%
const MAX_TURN_PENALTY := 1.0

# the chosen input styles
# the values for these properties influence how the player controller is moved
export(MOVEMENT_INPUT) var movement_style = MOVEMENT_INPUT.CARDINAL
export(ROTATION_INPUT) var rotation_style = ROTATION_INPUT.MOUSE_LOOK

# maximum speed per frame (normalised across axis)
export(float) var max_speed_per_frame := 300.0

# speed change over 1 frame when player is providing input
export(float) var acceleration_per_frame := 150.0
# adjustment to acceleration when player is not providing input, e.g.
# 1.0 will result in deacceleration equalling acceleration
# 0.0 will result in no deacceleration, ever
# negative values would result in acceleration even when not accelerating
# 2.0 is twice as fast deacceleration vs acceleration
# 0.5 is half as fast deacceleration vs acceleration
export(float) var deacceleration_modifier := 1.25
# minmum modifier to acceleration and deacceleration applied when the player is
# changing direction/turning. The modifier can go higher, to MAX_TURN_PENALTY.
export(float) var acceleration_turn_penalty := 0.25


# coeff applied to rotation speed (flat) applied when applying movement input
export(float) var acceleration_rotation_effect := 0.25
# rate at which the player rotates toward the angle of their movement intent
# this parameter is not applied if 'rotational_movement' isn't set
export(float) var rotation_speed := 7.5
## how different the angle to the intended rotation target can be from the
## current player rotation (in degrees) before the turning mod (see below)
## is applied to all velocity changes
# higher values generate allow wider turns to be considered 'not turning'
export(float) var turning_agility := 0.01

# whether velocity is conserved between frames, and new velocity is just
# added to the previous values. In combination with acceleration this will
# result in substantial velocity gain in a movement direction over short
# periods. It is intended for space or friction-less movement simulation.
export(bool) var store_velocity := false
# if storing velocity it is useful (for gameplay purposes to prevent runaway
# players) to restrict the maximum velocity on either axis. This is independent
# of maximum speed, as speed can stil be accrued and tracked and apply when
# travel direction changes.
# if set nil or negative this property will not be applied.
export(float) var velocity_cap := 0.0
# if storing velocity it is useful (as above, for gameplay purposes to prevent
# runaway players) to allow increased velocity gain when changing direction.
# set to 1.0 to disable this property.
export(float) var velocity_dropoff := 1.0

# whether player is moving during this frame
var is_moving := false
# whether the player is enacting a sharp enough turn to reduce momentum
var is_turning := false
# the stored velocity of the player between frames
var velocity := Vector2.ZERO
# store the previous direction of travel in last frame
var previous_velocity := Vector2.ZERO
# store the normalised velocity (travel direction) during this frame
var travel_direction := Vector2.ZERO
# as 'travel_direction' but for the previous frame
var previous_direction := Vector2.ZERO
# as 'travel_direction' but normalised every frame to represent the recent avg.
var average_dir := Vector2.ZERO
# the speed the player travels at when they do nothing
var minimum_speed := 0.0
# calculated by acceleration and time since movement stopped or changed
var current_speed := 0.0

## whether the player is trying to travel (change the axis of velocity) in
## a new direction this frame when compared to previous frames
#var is_changing_direction := false

# 'thinking' speed at which player turns
var rotation_intent_multiplier := 2.0
# current intent of rotation
var current_rotation_intent_angle = 0

# if set false the player will not look at the mouse, even if the control
# scheme setting is changed to CONTROL_SCHEME.KEYBOARD_AND_MOUSE
var enable_mouselook := true

# node references
#onready var intent_icon_root = $IndicatorHolder
#onready var direction_indicator_node = $DirectionIndicator

##############################################################################

# virtual methods


# Called when the node enters the scene tree for the first time.
#func _ready():
#	pass

func _physics_process(arg_delta):
	var movement_intent = _get_movement_input()
	var rotational_intent = _get_rotation_input()
	_process_movement(movement_intent, arg_delta)
	_process_rotation(rotational_intent, arg_delta)
	_process_debug_info()


##############################################################################

# virtual method extensions


# arg 1, dt, is delta from the physics process (time since last frame)
func _process_movement(arg_movement_intent: Vector2, arg_dt: float):
	var new_velocity: Vector2
	new_velocity = (arg_movement_intent*current_speed)
	
	if arg_movement_intent != Vector2.ZERO:
		_change_acceleration(arg_dt, true)
		#//TODO add movement audio argument
		# placeholder
#		_play_movement_audio(1.0)
	else:
		_change_acceleration(arg_dt, false)
		is_moving = false
	
	_change_velocity(new_velocity)
	
	var _collision
	_collision = move_and_slide(velocity)
	
	# rotate direction indicator
	# update debug info


func _process_rotation(arg_rotation_intent: Vector2, arg_dt: float):
	if arg_rotation_intent != Vector2.ZERO:
		_rotate_toward_intent(arg_dt, arg_rotation_intent)


func _process_debug_info():
	GlobalDebug.update_debug_overlay("is_moving", is_moving)
	GlobalDebug.update_debug_overlay("is_turning", is_turning)
	GlobalDebug.update_debug_overlay("current speed", current_speed)
	GlobalDebug.update_debug_overlay("current dir: x", travel_direction.x)
	GlobalDebug.update_debug_overlay("current dir: y", travel_direction.y)
	GlobalDebug.update_debug_overlay("current rotation", int(rotation_degrees))
	GlobalDebug.update_debug_overlay("velocity: x", int(velocity.x))
	GlobalDebug.update_debug_overlay("velocity: y", int(velocity.y))


##############################################################################

# public


##############################################################################

# private


# check and process inputs for movement based on the movement_style
func _get_movement_input() -> Vector2:
	var new_movement_input = Vector2.ZERO
	# input style
	match movement_style:
		#1
		MOVEMENT_INPUT.CARDINAL:
			if Input.is_action_pressed(ACTION_STRING_MOVE_UP):
				new_movement_input = Vector2.UP
			elif Input.is_action_pressed(ACTION_STRING_MOVE_RIGHT):
				new_movement_input = Vector2.RIGHT
			elif Input.is_action_pressed(ACTION_STRING_MOVE_LEFT):
				new_movement_input = Vector2.LEFT
			elif Input.is_action_pressed(ACTION_STRING_MOVE_DOWN):
				new_movement_input = Vector2.DOWN
		#2
		MOVEMENT_INPUT.OMNIDIRECTIONAL:
			if Input.is_action_pressed(ACTION_STRING_MOVE_UP):
				new_movement_input += Vector2.UP
			if Input.is_action_pressed(ACTION_STRING_MOVE_RIGHT):
				new_movement_input += Vector2.RIGHT
			if Input.is_action_pressed(ACTION_STRING_MOVE_LEFT):
				new_movement_input += Vector2.LEFT
			if Input.is_action_pressed(ACTION_STRING_MOVE_DOWN):
				new_movement_input += Vector2.DOWN
			new_movement_input = new_movement_input.normalized()
		#3
		MOVEMENT_INPUT.FORWARD_ONLY:
			if Input.is_action_pressed(ACTION_STRING_MOVE_FORWARD):
				new_movement_input += global_transform.x
	# exit
	return new_movement_input


# check and process inputs for rotation based on the rotation_style
func _get_rotation_input() -> Vector2:
	var new_rotation_goal = Vector2.ZERO
	# rotation_style
	match rotation_style:
		#1
		ROTATION_INPUT.TOWARD_CARDINAL:
			if Input.is_action_pressed(ACTION_STRING_ROTATE_TOWARD_UP):
				new_rotation_goal = Vector2.UP
			elif Input.is_action_pressed(ACTION_STRING_ROTATE_TOWARD_RIGHT):
				new_rotation_goal = Vector2.RIGHT
			elif Input.is_action_pressed(ACTION_STRING_ROTATE_TOWARD_LEFT):
				new_rotation_goal = Vector2.LEFT
			elif Input.is_action_pressed(ACTION_STRING_ROTATE_TOWARD_DOWN):
				new_rotation_goal = Vector2.DOWN
		#2
		ROTATION_INPUT.TOWARD_OMNIDIRECTIONAL:
			if Input.is_action_pressed(ACTION_STRING_ROTATE_TOWARD_UP):
				new_rotation_goal += Vector2.UP
			if Input.is_action_pressed(ACTION_STRING_ROTATE_TOWARD_RIGHT):
				new_rotation_goal += Vector2.RIGHT
			if Input.is_action_pressed(ACTION_STRING_ROTATE_TOWARD_LEFT):
				new_rotation_goal += Vector2.LEFT
			if Input.is_action_pressed(ACTION_STRING_ROTATE_TOWARD_DOWN):
				new_rotation_goal += Vector2.DOWN
			new_rotation_goal = new_rotation_goal.normalized()
		#3
		ROTATION_INPUT.LEFT_RIGHT:
			if Input.is_action_pressed(ACTION_STRING_ROTATE_CLOCKWISE):
				new_rotation_goal = global_transform.x.rotated(deg2rad(90))
			if Input.is_action_pressed(ACTION_STRING_ROTATE_COUNTER_CLOCKWISE):
				new_rotation_goal = global_transform.x.rotated(deg2rad(-90))
		#4
		ROTATION_INPUT.MOUSE_LOOK:
			if enable_mouselook:
				new_rotation_goal =\
						(get_global_mouse_position()-global_position)
	
	return new_rotation_goal


# whenever the player stops moving, speed falls off quickly
func _change_acceleration(arg_dt: float, arg_is_increasing: bool = true):
#	var turning_coefficient =\
#			acceleration_turn_penalty if false else 1.0
	var turning_coefficient = (1.0-_get_turn_sharpness())
#	var turning_coefficient =\
#	acceleration_turn_penalty if is_changing_direction else 1.0
	var deacceleration_per_frame =\
			acceleration_per_frame*deacceleration_modifier
	if arg_is_increasing:
		current_speed += (acceleration_per_frame*arg_dt*turning_coefficient)
	else:
		current_speed -= (deacceleration_per_frame*arg_dt*turning_coefficient)
	# bound
	current_speed = clamp(current_speed, minimum_speed, max_speed_per_frame)

# handle the audio loop
func _play_movement_audio(arg_intensity: float):
	emit_signal("play_audio", "player_movement_loop", arg_intensity)


# add velocity (should be in movement direction based on current speed)
# dt is delta, or the time since last frame
func _change_velocity(arg_new_velocity: Vector2):
	# moving set true if this method is called
	is_moving = true
	
	# store the previous frame's velocity and travel direction
	previous_velocity = arg_new_velocity
	previous_direction = travel_direction
	# store the travel direction
	travel_direction = velocity.normalized()
	
	# gameplay considerations for stored velocity
	# if storing velocity, add the new velocity to current velocity
	if store_velocity:
		arg_new_velocity = _stored_velocity_dropoff(arg_new_velocity)
		_stored_velocity_clamp()
		velocity += arg_new_velocity
	# if not storing velocity, overwrite current velocity with new velocity
	else:
		velocity = arg_new_velocity


# returns a float value indicating how wide a turn the player is making is
# this determines when the turning modifier penalty is applied
# making very gradual turns will ignore turning modifier penalties
# wider turns apply additional penalties beyond the base turning modifier value
# penalties cannot exceed 1.0 (100%)
func _get_turn_sharpness() -> float:
	average_dir = (average_dir+travel_direction).normalized()
	var get_dir_change = (average_dir-travel_direction).length()
	is_turning = (get_dir_change >= turning_agility)
	var turn_penalty = clamp(\
			get_dir_change*10, TURN_PENALTY_FLOOR, MAX_TURN_PENALTY)
	if is_turning:
		turn_penalty = clamp(\
				turn_penalty, acceleration_turn_penalty, MAX_TURN_PENALTY)
	else:
		turn_penalty = 0.0
	return turn_penalty
	
#	GlobalDebug.update_debug_overlay("avgdir", average_dir)
#	GlobalDebug.update_debug_overlay("avgdir_chg", get_dir_change)
#	GlobalDebug.update_debug_overlay("thrust multi", get_dir_change*10)
#	GlobalDebug.update_debug_overlay("is_turning: ", is_turning)


# if 'rotational_movement' property is not set, this is never called
# player has a rotational intent (a goal) to rotate toward, but doesn't
# immediately rotate toward that goal, instead moving toward it slower (the
# rate difference is controlled by 'rotation_intent_multiplier').
# This prevents snappy leftover rotation after the player ends input.
func _rotate_toward_intent(arg_dt: float, arg_intent: Vector2):
	# store previous
#	var previous_intent_angle = current_rotation_intent_angle
#	var previous_actual_rotation = rotation
	# if moving, apply a flat penalty to (actual) rotation speed
	var rotation_momentum_modifier =\
			acceleration_rotation_effect if is_moving else 1.0
	# calculate next
	# remembers where the player wants to rotate toward
	var new_intent_angle = lerp_angle(
		current_rotation_intent_angle,
		arg_intent.angle(),
		(arg_dt * rotation_speed * rotation_intent_multiplier))
	#assign
	current_rotation_intent_angle = new_intent_angle
	
	# actually rotates the player toward their intent
	var new_actual_rotation = lerp_angle(
		rotation,
		current_rotation_intent_angle,
		arg_dt * rotation_speed * rotation_momentum_modifier)
	# assign next
	rotation = new_actual_rotation


# takes the current velocity and bounds each axis to be within a range of
# -velocity_cap to velocity_cap.
func _stored_velocity_clamp():
	var is_velocity_capped: bool = (velocity_cap > 0.0)
	if not is_velocity_capped:
		return 
	# restrict velocity
	var clampvel_x: float = clamp(velocity.x, -velocity_cap, velocity_cap)
	var clampvel_y: float = clamp(velocity.y, -velocity_cap, velocity_cap)
	var clamped_velocity: Vector2 = Vector2(clampvel_x, clampvel_y)
#	var velocity_difference = Vector2(
#			abs(clamped_velocity.x)-abs(target_velocity.x),
#			abs(clamped_velocity.y)-abs(target_velocity.y))
#	var veldiff_proportion = velocity_difference.x/velocity_difference.y
	velocity = clamped_velocity


func _stored_velocity_dropoff(arg_new_velocity: Vector2) -> Vector2:
	var is_dropoff_disabled: bool = (velocity_dropoff == 1.0)
	if is_dropoff_disabled:
		return arg_new_velocity
	var new_velocity := arg_new_velocity
	# if axis of new velocity is different to stored velocity axis,
	# then the new velocity value is modified by the change in velocity
	# coefficient (velocity_dropoff).
	# x axis
	if (new_velocity.x > 0 and velocity.x < 0)\
	or (new_velocity.x < 0 and velocity.x > 0):
		new_velocity.x *= velocity_dropoff
	# y axis
	if (new_velocity.y > 0 and velocity.y < 0)\
	or (new_velocity.y < 0 and velocity.y > 0):
		new_velocity.y *= velocity_dropoff
	# return the modified velocity
	return new_velocity

#	if (new_velocity.x > 0 and previous_velocity.x < 0 and not store_velocity)\
#	or (new_velocity.x < 0 and previous_velocity.x > 0 and not store_velocity)\
#	if (new_velocity.y > 0 and previous_velocity.y < 0 and not store_velocity)\
#	or (new_velocity.y < 0 and previous_velocity.y > 0 and not store_velocity)\
