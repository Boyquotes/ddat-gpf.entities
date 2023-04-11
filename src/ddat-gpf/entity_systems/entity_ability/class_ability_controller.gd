extends ActivationController

class_name AbilityController

##############################################################################

# An AbilityController is an extended ActivationController with finer control
# over when and how an activation can occur. It is designed to provide
# activation conditions for player and enemy abilities, things that might
# have a warmup before activating, a cooldown after activating, or a set
# number of uses before they go on a longer cooldown.

#//TODO
# property for activation controller that prevents activation if ability is
# waiting (i.e. if cooldown is waiting or warmup is going) - perhaps just
# as an abilityController shadowed method?

#//TODO
# need a property that prevents delta accumulation (see below) whilst the
# ability isn't ready (also prevent confirmed_press)
# - INPUT_CONFIRMED_PRESS activation mode allows the priming/initial input
#	even whilst the ability is on warmup/coodlwon
#	same applies for INPUT_CONFIRMED_HOLD, you can start priming a new input
#	same applies for INPUT_MINIMUM_HOLD
#	same applies for ON_INTERVAL
#	if the accumulation triggers activation whilst ability is on cooldown,
#	the activation is discarded - should it queue?

#//TODO/REVIEW
#	warmup and cooldown currently work with INPUT_CONFIRMED_HOLD,
#	INPUT_MINIMUM_HOLD, INPUT_WHILST_HELD < is this desired behaviour?

##############################################################################

# properties (signals, enums, constants, exports, variables, onreadys)

# for ability warmup animations
# only emitted if 'ability_warmup' is positive
# warmup_progress is the % of warmup completed
signal ability_warmup_active(warmup_progress)
# for ui elements and ability cooldown animations
# only emitted if 'ability_cooldown' is positive
# cooldown_progress is the % of warmup completed
signal ability_cooldown_active(cooldown_progress)
# indicates that the ability is preparing to fire
# only emitted if 'ability_warmup' is positive
# separate from corresponding 'active' signal for simply getting the first
# frame in which the warmup started without having to check a passed value
# (catches edge cases of frame lag also)
signal ability_warmup_started()
# indicates that the ability is entering cooldown
# only emitted if 'ability_cooldown' is positive
# separate from corresponding 'active' signal for simply getting the first
# frame in which the cooldown started without having to check a passed value
# (catches edge cases of frame lag also)
signal ability_cooldown_started()
# indicates that the ability is about to fire
# only emitted if 'ability_warmup' is positive
signal ability_warmup_finished()
# indicates that the ability can be used again
# only emitted if 'ability_cooldown' is positive
# warning-ignore:unused_signal
signal ability_cooldown_finished()

# emitted when ability no longer has enough usages remaining to spend
# only emitted after the ability spends usages and reaches this point
signal ability_usages_depleted()
# emitted when ability completely refills usages
# only emitted after the refresh timer refills usages and reaches this point
signal ability_usages_full()
# emitted alongside the 'activate_ability' signal
# useful for ui elements to track usage remaining
# only emitted if 'max_usages' property is positive
# will be emitted even if 'usages_refresh_amount' is nil
# warning-ignore:unused_signal
signal ability_usage_spent(uses_remaining, uses_spent)
# emitted when a usage is refreshed, for ui elements
# only emitted if 'refresh_usages_time' and 'usages_refresh_amount' are valid
# 'uses_refreshed' value will be equal to 'usages_refresh_amount' unless the
# number of usages to be refreshed would take the usages over the maximum
# warning-ignore:unused_signal
signal ability_usage_refreshed(uses_remaining, uses_refreshed)
# for ui elements and ability usage refreshing animations
# only emits if 'refresh_usages_time' > 0.0, and 'infinite_usages' == false
# cooldown_progress is the % of refresh completed
signal ability_refresh_active(refresh_progress)

# signal for indicating an activation would have happened, but a specific
# abilityController condition blocked it activating
# (useful for ui element animations/feedback)
# should pass a specific error code (see 'ACTIVATION_ERROR' enum) as to why
# warning-ignore:unused_signal
signal failed_activation(error_code)

# error codes that should be passed with the 'failed_activation' signal
# ERR_NO_USES_LEFT - ability had no usages remaining on activation call
# ERR_ON_COOLDOWN - ability was on cooldown on activation call
# ERR_ON_WARMUP - ability was already warming up on activation call
enum ACTIVATION_ERROR {
	ERR_NO_USES_LEFT,
	ERR_ON_COOLDOWN,
	ERR_ON_WARMUP,
}

# how the usage refresh properties work
# NEVER - refresh delay and timer counts constantly (default behaviour)
# IN_USE - refresh delay and timer will pause if the ability is in
#	either the warmup or cooldown state
# ON_COOLDOWN - refresh delay and timer pause if ability on cooldown
# ON_WARMUP - refresh delay and timer pause if ability is warming up
# IF_NOT_NIL - refresh timer only starts if all usages have been spent
#	(this setting is best used with a low 'refresh_usages_time' or high
#	'usages_refresh_amount' value)
enum REFRESH_PAUSE {
	NEVER,
	IN_USE,
	ON_COOLDOWN,
	ON_WARMUP,
	IF_NOT_NIL,
	}

# disable when finished
# for dev logging
const VERBOSE_LOGGING := false
const SCRIPT_NAME := "AbilityController"

# the minimum number of usages an ability can have
# handled in 'change_usages' method as a minimum floor/clamp
# defaults to 0, setting to negative may have unintended behaviour
const MINIMUM_USAGES := 0

# easy flag for disabling cooldown features
export(bool) var enable_cooldown := true
# how long (in frames) before the ability can fire again
# attempted activations are prevented whilst cooldown is active
# note: when considering multiple usage timings, cooldown applies on every use
# set nil to disable
export(float, 0.0, 600.0) var ability_cooldown = 0.5

# easy flag for disabling warmup features
export(bool) var enable_warmup := true
# how long (in frames) it takes for the ability to fire
# this applies after input is confirmed by default, and all other input or
# attempted activations are prevented whilst an activation is in the queue
# (applying a long warmup will slow ability resolution)
# note: when considering multiple usage timings, warmup applies on every use
# set nil to disable
export(float, 0.0, 20.0) var ability_warmup = 0.25

# abilities can have a finite number of uses; each activation consumes a set
# amount of uses and an ability can no longer activate once usages are consumed
# uses can be restored by signal (public method), or on a fixed duration
# (ability usage properties below)

# if set true, all usage and refresh behaviour is skipped
export(bool) var infinite_usages := true
# if set true, current usages equal max usages on _ready() call
export(bool) var start_at_full_usages := true
# max_usages is the total number of uses the ability has
# abilities start at their maximum number of uses by default
# set nil to disable the ability
export(int, 0, 100) var max_usages = 0
# how many uses of the ability are consumed on each activation
# given value is inverted when provided to the 'change_usages' method
# e.g. 1 becomes -1, 5 becomes -5
# set nil to prevent the ability consuming uses on activation
export(int, 0, 100) var usages_cost = 1
# if disabled prevents all refresh timer behaviour
export(bool) var usages_refreshed_over_time := true
# how many usages are refreshed when the use_refresh_time is exceed
# usages refreshed are capped at maximum usages
# set nil to prevent usage refresh
export(int, 0, 100) var usages_refresh_amount = 1
# the chosen refresh setting (see the REFRESH_PAUSE enum for detail)
export(REFRESH_PAUSE) var refresh_pause_mode := REFRESH_PAUSE.NEVER
# how long (in frames) before an ability regains a set number of uses
# set nil to prevent usage refresh
# if current usages >= maximum uses, the refresh timer is not checked
export(float, 0.0, 100.0) var refresh_usages_time = 1.0
# how long (in frames) before the refresh timer begins
# set nil to disable
# the refresh timer provides signal updates for ui elements
# this property is useful if you want a delay for refresh time whenever
# the condition for REFRESH_PAUSE is met
export(float, 0, 10.0) var refresh_delay_time = 0.0

# ability state trackers
var is_in_cooldown := false
var is_in_warmup := false

# track how long ability state has lasted (for purpose of ending states)
var frames_since_cooldown_started := 0.0
var frames_since_warmup_started := 0.0

# set to max usages on ready
var current_usages := 0

# track whether refresh timer should be counting
# this isn't set or unset by abilityController; option to set from elsewhere
var ability_usages_can_refresh := true
# track if refresh delay is active
var ability_usage_refresh_delayed := false

# track how long since refresh timer started, for purpose of refreshing usages
var frames_since_refresh_started := 0.0
# track how long since refresh delay started
var frames_since_delay_started := 0.0


##############################################################################

# virtual methods


func _ready():
	# set usages to max at first, if allowed
	if start_at_full_usages:
		# force usages update for ui elements
		change_usages(max_usages, true)


func _process(arg_delta):
	# accumulate delta trackers
	_process_cooldown_time(arg_delta)
	_process_warmup_time(arg_delta)
	_process_refresh_time(arg_delta)
	_process_refresh_delay(arg_delta)


func _process_cooldown_time(arg_delta):
	# ability cooldown processing immediately skipped if invalid or inactive
	if _is_cooldown_active():
		frames_since_cooldown_started += arg_delta
		# if exceed the cooldown length, end cooldown
		if frames_since_cooldown_started > ability_cooldown:
			change_cooldown_state(false)
		# else, track cooldown
		else:
			# pass along %done for ui elements and animations
			var cooldown_completed = clamp(\
					(frames_since_cooldown_started/ability_cooldown),
					0.0, 1.0)
			emit_signal("ability_cooldown_active", cooldown_completed)


func _process_warmup_time(arg_delta):
	# ability warmup processing immediately skipped if invalid or inactive
	if _is_warmup_active():
		frames_since_warmup_started += arg_delta
		# if exceed the warmup length, end warmup
		if frames_since_warmup_started > ability_warmup:
			change_warmup_state(false)
		# else, track warmup
		else:
			# pass along %done for ui elements and animations
			var warmup_completed = clamp(\
					(frames_since_warmup_started/ability_warmup),
					0.0, 1.0)
			emit_signal("ability_warmup_active", warmup_completed)


func _process_refresh_time(arg_delta):
	# ability refresh processing immediately skipped if invalid or inactive
	if is_refresh_valid():
		frames_since_refresh_started += arg_delta
		# if exceed the refresh period, restore usages
		if frames_since_refresh_started > refresh_usages_time:
			change_usages(usages_refresh_amount)
			# new refresh so start over
			frames_since_refresh_started = 0.0
		# else, track refresh progress
		else:
			# pass along %done for ui elements and animations
			var refresh_completed = clamp(\
					(frames_since_refresh_started/refresh_usages_time),
					0.0, 1.0)
			emit_signal("ability_refresh_active", refresh_completed)


# temporary/placeholder
func _process_refresh_delay(arg_delta):
	# refresh delay processing immediately skipped if invalid or inactive
	pass
	arg_delta = arg_delta
	# refresh delay does not have a % done signal like cd/wm/rfrsh


##############################################################################

# public methods


# check if ability refresh timer can count
func is_refresh_valid() -> bool:
	# skip if not using usages
	if infinite_usages:
		return false
	# public usage flag must be set
	# export flag must be set
	# current usages must be less than maximum usages
	# max usages cannot be nil
	if ability_usages_can_refresh\
	and usages_refreshed_over_time\
	and current_usages < max_usages\
	and max_usages > MINIMUM_USAGES:
		return true
	else:
		# disabled logging (even verbose) due to method call within _process
		# (makes excessive print calls)
#		GlobalDebug.log_error(SCRIPT_NAME, "is_refresh_valid",
#				"refresh status log = {1}/{2}/{3}/{4}".format({
#					"1": ability_usages_can_refresh,
#					"2": usages_refreshed_over_time,
#					"3": (current_usages < max_usages),
#					"4": (max_usages > MINIMUM_USAGES),
#				}))
		return false


# shadowed from activation controller to check conditions before activation
# ability controller will check warmup, cooldown, and usages, before it
# actually activates the ability
# activate within abilityController is a conditional check and triggers
# the warmup state before calling the actual activation
func activate():
	# check conditions before activating
	if not _is_warmup_active()\
	and not _is_cooldown_active()\
	and _are_usages_remaining():
		# call ability if no warmup, else 
		if ability_warmup > 0.0:
			change_warmup_state(true)
		else:
			activate_no_warmup()


# abilityController precursor to calling the _call_ability method
# can be manually called to forcibly skip warmup behaviour
func activate_no_warmup():
	# activate with cooldown and track usages spent
	change_cooldown_state(true)
	# usage cost value always inverted
	change_usages(-usages_cost)
	_call_ability()


# adjust the current number of ability usages
# provide with positive value to increase usages, or negative to decrease
# if force_update_signal is set true, the 'ability_usage_refreshed' signal
# will be sent (even if conditions for it to send weren't met)
# this is useful for initial ui setup (call change_usages(max_usages, true))
func change_usages(usage_change: int, force_update_signal: bool = false):
	# skip if not using usages
	if infinite_usages:
		return
	# track usages before change so can emit correct signal
	var initial_usages = current_usages
	# else adjust the current usages within bounds
	current_usages =\
			int(clamp(current_usages+usage_change,
			MINIMUM_USAGES,
			max_usages))
	if current_usages < initial_usages:
		emit_signal("ability_usage_spent", current_usages, usage_change)
		# if this was the last time the cost could be spent
		if initial_usages >= usages_cost\
		and current_usages < usages_cost:
			emit_signal("ability_usages_depleted")
	elif current_usages > initial_usages:
		emit_signal("ability_usage_refreshed", current_usages, usage_change)
		# if overflowed and was clamped to max
		if initial_usages < max_usages\
		and current_usages == max_usages:
			# refresh should be stopped and reset if max usages are reached
			frames_since_refresh_started = 0.0
			emit_signal("ability_usages_full")
	if force_update_signal:
		emit_signal("ability_usage_refreshed", current_usages, usage_change)


# start a new cooldown period or end an active cooldown period
# if 'activate_cooldown' is true, starts cooldown (if not already active)
# if 'activate_cooldown' is false, ends the active cooldown period (if any)
func change_cooldown_state(activate_cooldown: bool = true) -> void:
	# skip if called without valid cooldown
	if _is_cooldown_valid() == false:
		return
	# start cooldown and reset timer (if not already in cooldown)
	if activate_cooldown and not is_in_cooldown:
		is_in_cooldown = activate_cooldown
		frames_since_cooldown_started = 0.0
		emit_signal("ability_cooldown_active", 0.0)
		emit_signal("ability_cooldown_started")
	# end cooldown state
	elif not activate_cooldown and is_in_cooldown:
		is_in_cooldown = activate_cooldown
		emit_signal("ability_cooldown_finished")
#
#	# whenever cooldown or warmup state is changed,
#	# check the refresh pause state
#	recheck_refresh_pause_state()
#
#
#func recheck_refresh_pause_state():
#	var refresh_is_valid_state := true
#	# if cooldown is on then ON_COOLDOWN or IN_USE modes for REFRESH_PAUSE
#	# cause refresh pause; if using refresh delay this will restart the delay
#	if refresh_pause_mode == REFRESH_PAUSE.ON_COOLDOWN\
#	or refresh_pause_mode == REFRESH_PAUSE.IN_USE:
#		if is_in_cooldown:
#			refresh_is_valid_state = false
#	# if warmup is on then ON_WARMUP or IN_USE modes for REFRESH_PAUSE
#	# cause refresh pause; if using refresh delay this will restart the delay
#	if refresh_pause_mode == REFRESH_PAUSE.ON_WARMUP\
#	or refresh_pause_mode == REFRESH_PAUSE.IN_USE:
#		if is_in_warmup:
#			refresh_is_valid_state = false
#	# if a refresh blocked state (see above) is met,
#	# refresh is blocked and delay is called if it wasn't already active
#	ability_usages_can_refresh = refresh_is_valid_state
#	if infinite_usages:
#		return false
#
#	#temp
#	if refresh_pause_mode == REFRESH_PAUSE.ON_WARMUP\
#	or refresh_pause_mode == REFRESH_PAUSE.IN_USE:
#		ability_usages_can_refresh = false


# start a new warmup period
# if 'activate_warmup' is true, starts warmup (if not already active)
# if 'activate_warmup' is false, ends the active warmup period (if any)
func change_warmup_state(activate_warmup: bool = true) -> void:
	# skip if called without valid warmup
	if _is_warmup_valid() == false:
		return
	# start warmup and reset timer (if not already in warmup)
	if activate_warmup and not is_in_warmup:
		is_in_warmup = true
		frames_since_warmup_started = 0.0
		emit_signal("ability_warmup_active", 0.0)
		emit_signal("ability_warmup_started")
	# end warmup state, automatically start cooldown
	elif not activate_warmup and is_in_warmup:
		is_in_warmup = false
		emit_signal("ability_warmup_finished")
		# warmup always proceeds to activation
		activate_no_warmup()


##############################################################################

# private methods


# method to determine whether ability has usages remaining
func _are_usages_remaining() -> bool:
	if infinite_usages:
		return true
	if current_usages >= usages_cost:
		return true
	else:
		return false


# method to determine whether ability is currently in the cooldown state
func _is_cooldown_active() -> bool:
	# if cooldown is used, check whether ability is in cooldown
	if _is_cooldown_valid():
		return is_in_cooldown
	else:
		return false


# method to determine whether ability uses a cooldown
func _is_cooldown_valid() -> bool:
	# if cooldown isn't used, cooldown is never active
	if enable_cooldown == false\
	or (ability_cooldown == 0.0):
		return false
	else:
		return true


# method to determine whether ability is currently in the warmup state
func _is_warmup_active() -> bool:
	# if warmup is used, check whether ability is in warmup 
	if _is_warmup_valid():
		return is_in_warmup
	else:
		return false
	

# method to determine whether ability uses a warmup
func _is_warmup_valid() -> bool:
	# if warmup isn't used, warmup  is never active
	if enable_warmup == false\
	or (ability_warmup == 0.0):
		return false
	else:
		return true


## after conclusion of cooldown period
#func _on_cooldown_expired():
#	is_in_cooldown = false
#	emit_signal("ability_cooldown_finished")


## after conclusion of warmup period
#func _on_warmup_expired():
#	is_in_warmup = false
#	emit_signal("ability_warmup_finished")
#	# warmup always proceeds to activation
#	activate_with_cooldown()


##############################################################################

# 
