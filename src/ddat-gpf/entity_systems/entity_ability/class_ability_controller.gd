extends ActivationController

class_name AbilityController

##############################################################################

# An AbilityController is an extended ActivationController with finer control
# over when and how an activation can occur. It is designed to provide
# activation conditions for player and enemy abilities, things that might
# have a warmup before activating, a cooldown after activating, or a set
# number of uses before they go on a longer cooldown.

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

# emits on first frame a new refresh delay starts (will not emit if a refresh
# delay starts whilst a refresh delay is already active)
signal refresh_delay_started()
# emits on the frame a refresh delay ends
signal refresh_delay_ended()
# for ui elements and animations
# only emits if 'refresh_delay_duration' > 0.0, and 'infinite_usages' == false
# cooldown_progress is the % of refresh delay completed
signal refresh_delay_active(delay_progress)

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
enum REFRESH_DELAY {
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
# handled in 'change_ability_usages' method as a minimum floor/clamp
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
# given value is inverted when provided to the 'change_ability_usages' method
# e.g. 1 becomes -1, 5 becomes -5
# set nil to prevent the ability consuming uses on activation
export(int, 0, 100) var usages_cost = 1
# if disabled prevents all refresh timer behaviour
export(bool) var enable_usage_refresh_over_time := true
# how many usages are refreshed when the use_refresh_time is exceed
# usages refreshed are capped at maximum usages
# set nil to prevent usage refresh
export(int, 0, 100) var usages_refresh_amount = 1
# the chosen refresh setting (see the REFRESH_DELAY enum for detail)
export(REFRESH_DELAY) var refresh_delay_mode := REFRESH_DELAY.NEVER
# how long (in frames) before an ability regains a set number of uses
# set nil to prevent usage refresh
# if current usages >= maximum uses, the refresh timer is not checked
export(float, 0.0, 100.0) var refresh_usages_time = 1.0
# how long (in frames) before the refresh timer begins
# set nil to disable
# the refresh timer provides signal updates for ui elements
# this property is useful if you want a delay for refresh time whenever
# the condition for REFRESH_DELAY is met
export(float, 0, 10.0) var refresh_delay_duration = 0.0

# ability state trackers
var is_in_cooldown := false
var is_in_warmup := false

# track how long ability state has lasted (for purpose of ending states)
var frames_since_cooldown_started := 0.0
var frames_since_warmup_started := 0.0

# set to max usages on ready
var current_usages := 0

# track how long since refresh timer started, for purpose of refreshing usages
var frames_since_refresh_started := 0.0
# track how long since refresh delay started
var frames_since_delay_started := 0.0

# tracks whether a refresh delay is active (for the purpose of tracking
# when the delay ends so a signal can be emitted)
var refresh_delay_is_active := false

# track whether the ability can use a cooldown
# this isn't set or unset by abilityController; this is an optional flag that
# devs can set false from elsewhere to control ability cooldowns
var ability_can_cooldown := true
# track whether the ability can use a warmup
# this isn't set or unset by abilityController; this is an optional flag that
# devs can set false from elsewhere to control ability warmups
var ability_can_warmup := true
# track whether refresh timer should be counting
# this isn't set or unset by abilityController; this is an optional flag that
# devs can set false from elsewhere to control the refresh timer
# abilityController tracks if refresh can process w/'is_refresh_valid' method
var ability_usages_can_refresh := true
# track if refresh delay is active
# this isn't set or unset by abilityController; this is an optional flag that
# devs can set false from elsewhere to control the refresh delay
# abilityController tracks if the refresh delay is processing with the
# 'is_refresh_delay_valid' method
var ability_usage_refresh_can_delay := true


##############################################################################

# virtual methods


func _ready():
	# set usages to max at first, if allowed
	if start_at_full_usages:
		# force usages update for ui elements
		change_ability_usages(max_usages, true)


func _process(arg_delta):
	# accumulate delta trackers
	_process_cooldown_time(arg_delta)
	_process_warmup_time(arg_delta)
	_process_refresh_time(arg_delta)
	_process_refresh_delay(arg_delta)


func _process_cooldown_time(arg_delta):
	# ability cooldown processing immediately skipped if invalid or inactive
	if is_cooldown_active():
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
	if is_warmup_active():
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
			change_ability_usages(usages_refresh_amount)
			# new refresh so start over
			frames_since_refresh_started = 0.0
		# else, track refresh progress
		else:
			# pass along %done for ui elements and animations
			var refresh_completed = clamp(\
					(frames_since_refresh_started/refresh_usages_time),
					0.0, 1.0)
			emit_signal("ability_refresh_active", refresh_completed)


# handle the delay before the refresh timer restarts (if interrupted, see
# the REFRESH_DELAY enum for more detail)
func _process_refresh_delay(arg_delta):
	# if delay is active, reset frame count
	if is_refresh_delay_valid():
		if frames_since_delay_started > 0.0:
			emit_signal("refresh_delay_started")
		frames_since_delay_started = 0.0
		refresh_delay_is_active = true
	# if delay is not active, can begin to count for the delay
	elif frames_since_delay_started < refresh_delay_duration\
	and refresh_delay_is_active:
		frames_since_delay_started += arg_delta
		# progress udpate for ui elements and animations
		var refresh_delay_completed = clamp(\
				(frames_since_delay_started/refresh_delay_duration),
				0.0, 1.0)
		emit_signal("refresh_delay_active", refresh_delay_completed)
	else:
		if refresh_delay_is_active:
			emit_signal("refresh_delay_ended")
			refresh_delay_is_active = false


##############################################################################

# public methods


# shadowed from activation controller to check conditions before activation
# ability controller will check warmup, cooldown, and usages, before it
# actually activates the ability
# activate within abilityController is a conditional check and triggers
# the warmup state before calling the actual activation
func activate():
	# check conditions before activating
	if not is_warmup_active()\
	and not is_cooldown_active()\
	and are_usages_remaining():
		# if warmup is used but not active, activate it
		if is_warmup_valid():
			change_warmup_state(true)
		# otherwise skip warmup and carry on
		else:
			activate_after_warmup()


# abilityController precursor to calling the _call_ability method
# can be manually called to forcibly skip warmup behaviour
func activate_after_warmup():
	# activate with cooldown and track usages spent
	change_cooldown_state(true)
	# usage cost value always inverted
	change_ability_usages(-usages_cost)
	_call_ability()


# method to determine whether ability has usages remaining
func are_usages_remaining() -> bool:
	if infinite_usages:
		return true
	if current_usages >= usages_cost:
		return true
	else:
		return false


# adjust the current number of ability usages
# provide with positive value to increase usages, or negative to decrease
# if force_update_signal is set true, the 'ability_usage_refreshed' signal
# will be sent (even if conditions for it to send weren't met)
# this is useful for ui setup (call change_ability_usages(max_usages, true))
func change_ability_usages(
		usage_change: int,
		force_update_signal: bool = false):
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
	if is_cooldown_valid() == false:
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


# start a new warmup period
# if 'activate_warmup' is true, starts warmup (if not already active)
# if 'activate_warmup' is false, ends the active warmup period (if any)
func change_warmup_state(activate_warmup: bool = true) -> void:
	# skip if called without valid warmup
	if is_warmup_valid() == false:
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
		activate_after_warmup()


# method to determine whether ability is currently in the cooldown state
func is_cooldown_active() -> bool:
	# if cooldown is used, check whether ability is in cooldown
	if is_cooldown_valid():
		return is_in_cooldown
	else:
		return false


# method to determine whether ability uses a cooldown
func is_cooldown_valid() -> bool:
	# skip if optional flag is set false
	if ability_can_cooldown == false:
		return false
	# if cooldown isn't used, cooldown is never active
	if enable_cooldown == false\
	or (ability_cooldown == 0.0):
		return false
	else:
		return true


# check if ability delay is active
# if delay is active the property 'frames_since_delay_started' will be set
# to nil and must count back up to the export value 'refresh_delay_duration'
# if delay is not active 'frames_since_delay_started' can begin to count up
# only when frames_since_delay_started exceeds 'refresh_delay_duration' will
# 'frames_since_refresh_started' begin to count up (on the next _process call)
func is_refresh_delay_valid() -> bool:
	# skip if not using usages
	if infinite_usages:
		return false
	# skip if optional argument is set
	if ability_usage_refresh_can_delay == false:
		return false
	# if refresh delay is disabled, skip
	if refresh_delay_mode == REFRESH_DELAY.NEVER\
	or refresh_delay_duration == 0.0:
		return false
	# check multiple conditions, if any are fulfilled, refresh delay is active
	# if in catch-all or cooldown-only delay mode, must not be in cooldown
	if refresh_delay_mode == REFRESH_DELAY.ON_COOLDOWN\
	or refresh_delay_mode == REFRESH_DELAY.IN_USE:
		if is_cooldown_active():
			return true
	# if in catch-all or warmup-only delay mode, must not be in warmup
	if refresh_delay_mode == REFRESH_DELAY.ON_WARMUP\
	or refresh_delay_mode == REFRESH_DELAY.IN_USE:
		if is_warmup_active():
			return true
	# catchall exit
	return false


# check if ability refresh timer can count
func is_refresh_valid() -> bool:
	# skip if not using usages
	if infinite_usages:
		return false
	# cannot be valid if delay is active
	elif is_refresh_delay_valid():
		return false
	# if delay isn't active, it must not have been active recently
	elif refresh_delay_is_active:
		return false
	# check other conditions:
	#	public usage flag must be set
	#	export flag must be set
	#	current usages must be less than maximum usages
	#	max usages cannot be nil
	if ability_usages_can_refresh\
	and enable_usage_refresh_over_time\
	and current_usages < max_usages\
	and max_usages > MINIMUM_USAGES:
		return true
	else:
		# disabled logging (even verbose) due to method call within _process
		# (makes excessive print calls)
#		GlobalDebug.log_error(SCRIPT_NAME, "is_refresh_valid",
#				"refresh status log = {1}/{2}/{3}/{4}".format({
#					"1": ability_usages_can_refresh,
#					"2": enable_usage_refresh_over_time,
#					"3": (current_usages < max_usages),
#					"4": (max_usages > MINIMUM_USAGES),
#				}))
		return false


# method to determine whether ability is currently in the warmup state
func is_warmup_active() -> bool:
	# if warmup is used, check whether ability is in warmup 
	if is_warmup_valid():
		return is_in_warmup
	else:
		return false
	

# method to determine whether ability uses a warmup
func is_warmup_valid() -> bool:
	# skip if optional flag is set false
	if ability_can_warmup == false:
		return false
	# if warmup isn't used, warmup  is never active
	if enable_warmup == false\
	or (ability_warmup == 0.0):
		return false
	else:
		return true


##############################################################################

# private methods


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
