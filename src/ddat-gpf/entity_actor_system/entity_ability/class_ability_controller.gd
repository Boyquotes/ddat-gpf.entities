extends Node2D

class_name EntityAbilityController

##############################################################################

# docstring

# EntityAbilityController is a manager for subnodes that do things ingame.
# On fulfilling the activation mode condition the controller emits a signal
# that can be tied to custom behaviour in child nodes.

#//TODO
#	event on every frame (_process Input.pressed) instead of on input
#	add activate at minimum hold option (rather than on release after)
#	dynamic reticule that has a conditional bool state (rather than default
#		reticule per entityAbility)
#	reticule support for target lines
#	setting for reticule positoning, fixed distance/on-target/rot-toward
#	property for fixed look-at reticule distance from abilityController

##############################################################################

# properties (signals, enums, constants, exports, variables, onreadys)

# main signal for the entityAbility, this is emitted when the ability resolves
# all prerequisites and recieves the required activation input
# connect this to the node you are controlling with the EntityAbiltiyController
signal activate_ability()
# applies every frame that input is held (applies on CONFIRMED_HOLD)
# parameter is whether the minimum hold duration is reached
signal input_held(minimum_hold_reached)
# if using a non-sprite reticule you can connect this signal to the node
# for when to show the reticule
signal change_reticule_visibility(is_visible)

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
	INPUT_CONFIRMED_PRESS,
	INPUT_CONFIRMED_HOLD,
	CONTINUOUS,
	ON_INTERVAL,
	ON_SIGNAL,
	}

# when to show the ability's relevant targeting reticule
enum RETICULE {
	SHOW_ALWAYS,
	SHOW_ON_ACTIVATION,
	SHOW_ON_TARGETING,
	NEVER_SHOW,
	}

# disable when finished
# for dev logging
const CLASS_VERBOSE_LOGGING := true
const CLASS_SCRIPT_NAME := "EntityAbility"

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

# the active targeting reticule mode, see RETICULE
export(RETICULE) var reticule_mode =\
		RETICULE.SHOW_ALWAYS

# path to a sprite that displays as the targeting reticule for this ability
# if no path is set the chosen_targeting_reticule property will default to
# RETICULE.NEVER_SHOW, and targeting reticules will be ignored
export(NodePath) var path_to_reticule_sprite

# duration to show the reticule on entityAbilityController activation
# only applies if reticule mode is set to RETICULE.SHOW_ON_ACTIVATION
export(float, 0.0, 60.0) var show_reticule_duration := 0.4

# delta accumulation since last frame
var delta_since_last_frame := 0.0
# how many times the ability has been activated since last frame
var activations_since_last_frame := 0
# if in ACTIVATION.INPUT_TOGGLED mode, tracks the active state
var ability_toggle_state := false
# if on and in RETICULE.SHOW_ON_TARGETING mode, shows targeting graphics
var is_targeting_active := false setget _set_is_targeting_active
# delta accumulation since last input in activation mode CONFIRMED_PRESS
var frames_since_last_valid_input := 0
# if in activation mode CONFIRMED_HOLD, tracks how long that an
# input has been held across multiple frames
var is_input_being_held := false
# delta accumulation since frame that input was first pressed (and held)
var frames_input_has_been_held := 0.0
# delta accumulation since last time forced activation occured
# only applies if activation mode is set to ACTIVATION.ON_INTERVAL
var frames_since_last_forced_activation := 0.0

# tracking whether the reticule has been temporarily shown after activation
# only applies if reticule mode is set to RETICULE.SHOW_ON_ACTIVATION
var showing_reticule_after_activation := false
# delta accumulation since targeting reticule was set visible
# used to track when to hide the reticule again
# only applies if reticule mode is set to RETICULE.SHOW_ON_ACTIVATION
var frames_since_reticule_shown := 0.0

# reference to targeting reticule sprite, if unset will disable any reticule
# based methods such as _change_targeting_reticule_visibility
var targeting_reticule_node: Sprite = null

##############################################################################

# setters and getters


func _set_is_targeting_active(arg_value):
	is_targeting_active = arg_value
	if reticule_mode == RETICULE.SHOW_ON_TARGETING:
		_change_targeting_reticule_visibility(arg_value)


##############################################################################

# virtual methods


func _ready():
	# call setters and getters
	self.activation_mode = activation_mode
	self.reticule_mode = reticule_mode
	# establish node refs
	_attempt_to_set_targeting_reticule()


# delta is time since last frame
func _process(arg_delta):
	# handle per-frame activations
	if activation_mode == ACTIVATION.CONTINUOUS\
			or ((activation_mode == ACTIVATION.INPUT_TOGGLED)
			and (ability_toggle_state == true)):
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
		self.is_targeting_active = false
	
	# (checked during ACTIVATION.CONFIRMED_HOLD mode)
	# count time input has been held
	if is_input_being_held:
		frames_input_has_been_held += arg_delta
	
	if activation_mode == ACTIVATION.ON_INTERVAL:
		# (checked during ACTIVATION.INTERVAL mode)
		frames_since_last_forced_activation += arg_delta
		if frames_since_last_forced_activation >= forced_activation_interval:
			frames_since_last_forced_activation -= forced_activation_interval
			activate()
	
	# (checked during RETICULE.SHOW_ON_ACTIVATION mode)
	if showing_reticule_after_activation:
		frames_since_reticule_shown += arg_delta
		if frames_since_reticule_shown >= show_reticule_duration:
			frames_since_reticule_shown = 0.0
			_change_targeting_reticule_visibility(false)


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
				if is_targeting_active\
				and frames_since_last_valid_input < max_input_separation:
					self.is_targeting_active = false
					activate()
				# input not previously pressed
				else:
					self.is_targeting_active = true
			
			# input must be held
			ACTIVATION.INPUT_CONFIRMED_HOLD:
				emit_signal("input_held",
						(min_hold_duration>=frames_input_has_been_held))
				self.is_targeting_active = true
				is_input_being_held = true
	
	# clearing targeting during hold states
	if arg_event.is_action_pressed(target_clear_action):
		if is_input_being_held:
			is_input_being_held = false
		if is_targeting_active:
			self.is_targeting_active = false
	
	# handle confirmed held release
	if is_input_being_held\
	and arg_event.is_action_released(use_ability_action):
			self.is_targeting_active = false
			is_input_being_held = false
			if frames_input_has_been_held >= min_hold_duration:
				activate()
			frames_input_has_been_held = 0.0


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
		if reticule_mode == RETICULE.SHOW_ON_ACTIVATION:
			_change_targeting_reticule_visibility(true)
			showing_reticule_after_activation = true
	else:
		if CLASS_VERBOSE_LOGGING:
			GlobalDebug.log_error(CLASS_SCRIPT_NAME, "activate",\
					"entityAbility {x} called at max activations".format({
						"x": str(self)
					}))


# some targeting styles need reticule preconfiguration
# maybe change to setter?
func _change_targeting_reticule_visibility(arg_show: bool = false):
	if targeting_reticule_node != null:
		targeting_reticule_node.visible = arg_show
		emit_signal("change_reticule_visibility", arg_show)


# attempt to establish the targeting reticule sprite
func _attempt_to_set_targeting_reticule():
	# ERR checking
	if path_to_reticule_sprite == null:
		return
	var get_potential_reticule = get_node_or_null(path_to_reticule_sprite)
	if get_potential_reticule == null:
		if CLASS_VERBOSE_LOGGING:
			GlobalDebug.log_error(CLASS_SCRIPT_NAME, "path_to_reticule_sprite",
					"reticule sprite path invalid")
		return
	if get_potential_reticule is Sprite:
		targeting_reticule_node = get_potential_reticule
		if reticule_mode == RETICULE.SHOW_ALWAYS:
			_change_targeting_reticule_visibility(true)
		elif reticule_mode == RETICULE.NEVER_SHOW:
			_change_targeting_reticule_visibility(false)


##############################################################################

# 
