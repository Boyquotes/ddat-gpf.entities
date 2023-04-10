extends Node2D

class_name ActivationController

##############################################################################

# docstring

# ActivationController is a manager for subnodes that do things ingame.
# On fulfilling the activation mode condition the controller emits a signal
# that can be tied to custom behaviour in child nodes.

##############################################################################

# properties (signals, enums, constants, exports, variables, onreadys)

# main signal for the activation controller, this is emitted when resolving
# all prerequisites and recieving the required activation input
# connect this to the node you are controlling with the ActivationController
signal activate_ability()
# applies every frame that input is held (applies on CONFIRMED_HOLD)
# parameter is whether the minimum hold duration is reached
signal input_held(hold_dur_left)
# emitted on the frame the activation input is released
signal held_input_just_released()
# emitted under INPUT_CONFIRMED_PRESS or INPUT_CONFIRMED_HOLD only
# INPUT_CONFIRMED_PRESS; emitted as true on first input press, false when
#	either the input is confirmed or is now invalid
# INPUT_CONFIRMED_HOLD; emitted as true the first frame input is pressed,
#	and false when the input is released or is now invalid
# this signal can be connected to ability targeters to show/hide reticules
signal input_confirming(is_waiting)

# how input affects the activation of the ability
# INPUT_ACTIVATED ~ input activates, effect triggers once
# INPUT_TOGGLED ~ input toggles on/off, in 'on' state the activation
#	signal is sent every frame
# INPUT_CONFIRMED_PRESS ~ input starts target selection, repeat press
#	to confirm, press ability_target_clear action to cancel
# INPUT_CONFIRMED_HOLD ~ target acquisiton whilst action held, press the
#	ability_target_clear action to stop or release action to confirm
# CONTINUOUS ~ will send activation signal every frame
# ON_INTERVAL ~ ability automatically activates on a fixed interval
# ON_SIGNAL ~ ability activates only on manual signal receipt to main method
enum ACTIVATION {
	INPUT_ACTIVATED,
	INPUT_TOGGLED,
	INPUT_WHILST_HELD,
	INPUT_CONFIRMED_PRESS,
	INPUT_CONFIRMED_HOLD,
	CONTINUOUS,
	ON_INTERVAL,
	ON_SIGNAL,
	DISABLE_ACTIVATION,
	}

# disable when finished
# for dev logging
const CLASS_VERBOSE_LOGGING := false
const CLASS_SCRIPT_NAME := "ActivationController"

# how many times the ability can be activated during each frame
# This is a technical limiter and should not be used as an ability cooldown
# system. If such functionality is desired, extend this class and add it.
export(int, 0, 121) var activation_cap_per_frame := 60

# the active input mode, see ACTIVATION
export(ACTIVATION) var activation_mode =\
		ACTIVATION.INPUT_ACTIVATED
# the InputMap action (see projectSettings) that the input mode responds to
export(String) var use_ability_action = "activate_ability_1"
# the InputMap action (see projectSettings) that clears target acquisiton
# during ACTIVATION.CONFIRMED_PRESS or ACTIVATION.CONFIRMED_HOLD
export(String) var target_clear_action = "cancel_ability"
# maximum frames between two inputs for the second input to be considered
# only applies if activation mode is set to ACTIVATION.CONFIRMED_PRESS
export(float, 0.1, 60.0) var max_input_separation := 1.0
# min duration (in frames) input must be held to activat, set nil to disable
# only applies if activation mode is set to ACTIVATION.CONFIRMED_HOLD
export(float, 0.0, 60.0) var min_hold_duration := 0.0
# if set activation will be triggered every x frames; set nil to disable
# only applies if activation mode is set to ACTIVATION.ON_INTERVAL
export(float, 0.0, 600.0) var forced_activation_interval := 0.0

# delta accumulation since last frame
var delta_since_last_frame := 0.0
# how many times the ability has been activated since last frame
var activations_since_last_frame := 0
# if in ACTIVATION.INPUT_TOGGLED mode, tracks the active state
var ability_toggle_state := false
# delta accumulation since last input in activation mode CONFIRMED_PRESS
var frames_since_last_valid_input := 0
# for INPUT_CONFIRMED_PRESS activation mode, is true whilst inputs are being
# checked against future inputs (for max_input_separation duration) and puts
# out signals for reticule handling in abilityTargeter nodes
var is_input_checking_active := false
# if in activation mode CONFIRMED_HOLD, tracks how long that an
# input has been held across multiple frames
var is_input_being_held := false
# delta accumulation since frame that input was first pressed (and held)
var frames_input_has_been_held := 0.0
# delta accumulation since last time forced activation occured
# only applies if activation mode is set to ACTIVATION.ON_INTERVAL
var frames_since_last_forced_activation := 0.0

##############################################################################

# setters and getters


##############################################################################

# virtual methods


func _ready():
	# call setters and getters
	self.activation_mode = activation_mode


# delta is time since last frame
func _process(arg_delta):
	# handle per-frame activations
	if activation_mode == ACTIVATION.CONTINUOUS\
			or ((activation_mode == ACTIVATION.INPUT_TOGGLED)
			and (ability_toggle_state == true)):
		activate()
	
	# if input is held down during 'whilst held' mode
	if activation_mode == ACTIVATION.INPUT_WHILST_HELD\
	and Input.is_action_pressed(use_ability_action):
		activate()
	
	# count time and activations over a frame
	delta_since_last_frame += arg_delta
	if delta_since_last_frame >= 1.0:
		delta_since_last_frame -= 1.0
		# assumes at least one _process loop per frame (1tps)
		activations_since_last_frame = 0
	
	# (checked for ACTIVATION.CONFIRMED_PRESS mode)
	# accumulate time since last input
	frames_since_last_valid_input += arg_delta
	if frames_since_last_valid_input >= max_input_separation:
		self.is_input_checking_active = false
	
	# (checked during ACTIVATION.CONFIRMED_HOLD mode)
	# count time input has been held
	if is_input_being_held:
		frames_input_has_been_held += arg_delta
		if (frames_input_has_been_held>=min_hold_duration):
			emit_signal("input_held", 1.0)
		else:
			emit_signal("input_held",\
					(frames_input_has_been_held/min_hold_duration))
	
	if activation_mode == ACTIVATION.ON_INTERVAL:
		# (checked during ACTIVATION.INTERVAL mode)
		frames_since_last_forced_activation += arg_delta
		if frames_since_last_forced_activation >= forced_activation_interval:
			frames_since_last_forced_activation -= forced_activation_interval
			activate()

# on an input arg_event
func _input(arg_event):
	# initial action press handling
	if arg_event.is_action_pressed(use_ability_action):
		match activation_mode:
			
			# single press activates
			ACTIVATION.INPUT_ACTIVATED:
				activate()
			
			# single press toggles state
			ACTIVATION.INPUT_TOGGLED:
				ability_toggle_state = !ability_toggle_state
			
			# input must be double pressed
			ACTIVATION.INPUT_CONFIRMED_PRESS:
				# input has been previously pressed
				if is_input_checking_active\
				and frames_since_last_valid_input < max_input_separation:
					emit_signal("input_confirming", false)
					self.is_input_checking_active = false
					activate()
				# input not previously pressed
				else:
					# if first press
					if is_input_checking_active == false:
						emit_signal("input_confirming", true)
					self.is_input_checking_active = true
			
			# input must be held
			ACTIVATION.INPUT_CONFIRMED_HOLD:
				# emit input-waiting-to-be-confirmed signal on first frame only
				if not is_input_being_held:
						emit_signal("input_confirming", true)
				self.is_input_checking_active = true
				is_input_being_held = true
	
	# clearing targeting during hold states
	if arg_event.is_action_pressed(target_clear_action):
		if is_input_being_held:
			is_input_being_held = false
		if is_input_checking_active:
			self.is_input_checking_active = false
		emit_signal("input_confirming", false)
	
	# handle confirmed held release
	if is_input_being_held\
	and arg_event.is_action_released(use_ability_action):
			self.is_input_checking_active = false
			is_input_being_held = false
			if frames_input_has_been_held >= min_hold_duration:
				activate()
			frames_input_has_been_held = 0.0
			emit_signal("held_input_just_released")
			emit_signal("input_confirming", false)


##############################################################################

# public methods


# shadow in extended classes to add more preconditions for an ability to fire
func activate():
	_call_ability()


##############################################################################

# private methods


# actually the main activation method, activate() method calls this if valid
# checks the activation cap before actually triggering the ability
func _call_ability():
	if activations_since_last_frame < activation_cap_per_frame:
		emit_signal("activate_ability")
		activations_since_last_frame += 1
		# signal RETICULE.SHOW_ON_ACTIVATION
	else:
		if CLASS_VERBOSE_LOGGING:
			GlobalDebug.log_error(CLASS_SCRIPT_NAME, "activate",\
					"activation ctrlr {x} called at max activations".format({
						"x": str(self)
					}))


##############################################################################

# 
