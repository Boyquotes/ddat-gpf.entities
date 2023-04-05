extends ActionCondition

#class_name ActionConditionOnInput

##############################################################################
#
# An ActionCondition where the condition is true on a frame it recieves
# a specific input action, input after recent input, sequence of inputs,
# or an input for a specific duration.

# legacy tod0
#// revisit the condition_state_now_valid conflict with allow_held/
#		is_action_pressed (it doesn't work without forcing it unset and
#		that in itself will repeatedly trigger the condition_state_now_invalid
#		signal every frame as well, which could produce undesirable behaviour)
#		arguments for which signal to use would make more sense

#//	add logic for sequence of action inputs, with support for holds
#		(could this be done with a chain of conditions?)

#//	add support for condition state remaining true for a period
#		(this ties into the above)

#		[re: timer code taken from actcon_on_interval.gd]
#//	potentially extend both input & interval action conditions from a
#		from a common timerActionCondition parent, since they both use two
#		timers and have the same setup condition (or add a static function
#		for setup to the actionCondition parent?)
#//NOTE	this is only relevant now (reviwed and refactored timer instantiation
#		behaviour for ActionConditionOnInput to only get a timer if need be)
#		if a manual (script-managed) timer is desirable in specific
#		circumstances only (rather than default actionConditionOnInterval
#		behaviour which is to instantiate both timers straight away)

#legacy TOD0
#// name repeat_delay_timeout_method
#// _process_input_pressed arguments for which signal to use would make more sense
	
#//
#	process disable condition state on next frame
#	single input behaviour
#	set up timer nodes
#	held input behaviour
#	repeat delay behaviour
#	sequence behaviour
	
##############################################################################

# the specific type of input that this actionCondition registers as
# fulfilling the condition state. If left at default 'INPUT_TYPE.AUTOMATIC'
# value, the chosen input type is automatically set based on export vars;
# to set MINIMUM_HOLD, held_input_duration must be greater than nil
# to set REPEATED, repeat_delay must be greater than nil
# if repeat_delay and held_input_duration are both greater than nil,
# the chosen_input_type will default to MINIMUM_HOLD
# if none of the above is true, PRESS is chosen.
# (to guarantee input type, set the relevant export on the node/in-editor)
enum INPUT_TYPE {AUTOMATIC, PRESS, MINIMUM_HOLD, REPEATED}

# for passing to error logging
const SCRIPT_NAME := "ActionConditionOnInput"
# for developer use, enable if making changes
const VERBOSE_LOGGING := true

export(INPUT_TYPE) var chosen_input_type = INPUT_TYPE.AUTOMATIC

# string that must correspond to input aciton string
# set inputAction string accepted actions to distinguish input methods
export(String) var input_action_accepted := ""

# duration that an input must be held, in seconds
# if this is set nil or negative, held inputs are not registered
# if this is set to greater than nil, repeat inputs are not registered
# setter instantiates the held_input_timer_node if it isn't already present
export(float) var held_input_duration := 0.0 setget _set_held_input_duration

#//RELEVANT FOR SEQUENCE BEHAVIOUR, REMOVED FROM REPEAT BEHAVIOUR
# if this flag is set true the condition is fulfilled when two inputs that are
# identical (and accepted inputs) are pressed.
# if false the next input must be the next input within the input actions
# accepted array (if the array is only length 1, this flag is forced true),
# wrapping to the start of the array if it reaches the end.
# I.e. if the index of first input is 4, the next input's index should be 5.
#//no longer currently planned
#export(bool) var repeat_identical := false

# the allowed gap between inputs, in seconds
# if this is set nil or negative, repeat inputs are not registered
# setter instantiates the repeat_timer_node if it isn't already present
export(float) var repeat_delay := 0.0 setget _set_repeat_delay
export(int) var repeats_required := 2

# for comparing to current input/getting input of last input
# cleared when repeat delay expires
var last_input := ""

# switch between 'is_action_just_pressed' and 'is_action_pressed' input reading
# this doesn't change the input type (PRESS, REPEAT, or MINIMUM_HOLD) but how
# the condition is valid (whether it expires after one frame or repeats as long
# as the input is held once valid)
export var allow_held := false

# timer for registering held input duration, instantiated on condition ready
# if isn't set when held_input_duration is changed, it will call setup method
var held_input_timer_node: Timer
# timer for registering repeat delay, instantiated on condition ready
# if isn't set when repeat_delay is changed, it will call setup method
var repeat_timer_node: Timer

##############################################################################

# setters and getters


# on setting the held input dur, set the held input timer node wait time
# if the timer node isn't found, create it
func _set_held_input_duration(arg_value):
	held_input_duration = arg_value
	#//TODO name method
	var held_input_timeout_method = ""
	if _validate_timer(
			held_input_timer_node, held_input_timeout_method) == false:
		var new_timer = _initialise_new_manual_timer(held_input_timeout_method)
		if new_timer is Timer:
			held_input_timer_node = new_timer
	else:
		held_input_timer_node.wait_time = held_input_duration


# on setting the repeat delay, set the repeat delay timer node wait time
# if the timer node isn't found, create it
func _set_repeat_delay(arg_value):
	repeat_delay = arg_value
	var repeat_delay_timeout_method = ""
	if _validate_timer(repeat_timer_node,
			repeat_delay_timeout_method) == false:
		var new_timer = _initialise_new_manual_timer(repeat_delay_timeout_method)
		if new_timer is Timer:
			repeat_timer_node = new_timer
	else:
		held_input_timer_node.wait_time = repeat_delay


##############################################################################

# virtual ready


#func _ready():
#	pass


##############################################################################

# virtual process

# placeholder, move to top
#var held_input_started := false

# get input type if automatic?
# or set input type w/automatic at ready then re-evaluate on change of
# any relevant property
# might need a 'was automatic on init' property since the var will change
# 
# need to pass delta to the action? or handle actCon getting out of sync?
#
# based on input type run input behaviour
# PRESS				> true once action is pressed
# REPEATED			> true the frame of completing required number of presses
# MINIMUM_HOLD		> true frame of holding for the minimum duration
func _process(delta):
	match chosen_input_type:
		# for inputs that are valid immediately
		INPUT_TYPE.PRESS:
			_process_input_pressed(delta)
		# for inputs that must be held for a minimum time to become true
		INPUT_TYPE.MINIMUM_HOLD:
			_process_input_minimum_hold(delta)
		# for combination inputs or multiple presses (double tap etc)
		INPUT_TYPE.REPEATED:
			_process_input_repeated(delta)


func _process_input_pressed(_dt):
	var action_valid_this_frame := false
	# check action is held if allowed, or just pressed if not
	if allow_held:
		if Input.is_action_pressed(input_action_accepted):
			# condition state must be set invalid to emit a valid signal for
			# manually connected actionCondition->actionEffect
			# otherwise would not emit as the condition state would remain the
			# same between frames
			# NOTE: this will trigger the condition_state_now_invalid signal
			# t0d0 arguments for which signal to use would make more sense
			self.condition_state = false
			action_valid_this_frame = true
	else:
		if Input.is_action_just_pressed(input_action_accepted):
			action_valid_this_frame = true
	# do stuff
	if action_valid_this_frame:
		self.condition_state = true
	else:
		self.condition_state = false


func _process_input_minimum_hold(_dt):
#	elif (chosen_input_type == INPUT_TYPE.MINIMUM_HOLD):
#		if Input.is_action_pressed(input_action_accepted):
			# if action is unpressed, timer stops
			# when timer expires, check action is still pressed
			# if it is, do action
	pass


func _process_input_repeated(_dt):
#	if (chosen_input_type == INPUT_TYPE.REPEATED):
	# todo add logic for update steps of repeat input (# of steps governed
	# by repeats_required)
	pass


##############################################################################


func _validate_timer(arg_timer_node, arg_receipt_method: String) -> bool:
	# check all required conditions
	# node is a timer, inside the tree, and a child of this actionCondition
	# the passed arg 'receipt_method' is a valid method of this actionCondition
	# the timeout signal of the timer is connected to that method
	if not arg_timer_node is Timer:
		GlobalDebug.log_error(SCRIPT_NAME, "_validate_timer", "err 1")
		return false
	if not arg_timer_node.is_inside_tree():
		GlobalDebug.log_error(SCRIPT_NAME, "_validate_timer", "err 2")
		return false
	if not arg_timer_node.get_parent() == self:
		GlobalDebug.log_error(SCRIPT_NAME, "_validate_timer", "err 3")
		return false
	if not self.has_method(arg_receipt_method):
		GlobalDebug.log_error(SCRIPT_NAME, "_validate_timer", "err 4")
		return false
	if not arg_timer_node.is_connected("timeout", self, arg_receipt_method):
		GlobalDebug.log_error(SCRIPT_NAME, "_validate_timer", "err 5")
		return false
	# if all checks passed
	return true


# only call this method if timer reference is null, or timer isn't present
# inside the tree, or timer isn't a child of this node
func _initialise_new_manual_timer(arg_receipt_method: String):
	var new_timer_node = Timer.new()
	# manually controlled timer (i.e only runs once and starts again by code)
	new_timer_node.autostart = false
	new_timer_node.one_shot = true
	self.call_deferred("add_child", new_timer_node)
	yield(new_timer_node, "ready")
	# check the passed argument is a valid method and can connect timer to
	if self.has_method(arg_receipt_method):
		if new_timer_node.connect("timeout", self, arg_receipt_method) == OK:
			# validate
			if _validate_timer(new_timer_node, arg_receipt_method):
				return new_timer_node
	# something failed
	# catch all exit condition
	GlobalDebug.log_error(SCRIPT_NAME, "_initialise_new_manual_timer",
			"new timer did not validate, freeing new timer")
	new_timer_node.call_deferred("queue_free")
	return null


# method to calculate chosen input type according to the rules set out above
# the INPUT_TYPE enum
# only applies if default chosen_input_type variable is 'INPUT_TYPE.AUTOMATIC')
func _get_input_type_if_automatic():
	pass


####################################################################

# discard/deprecated


func placeholder_debugger_discards():
	pass
	chosen_input_type = chosen_input_type
	input_action_accepted = input_action_accepted
	repeats_required = repeats_required
	last_input = last_input
	allow_held = allow_held

#func _ready():
#	if Input.is_action_just_pressed("dash_left_player1")
